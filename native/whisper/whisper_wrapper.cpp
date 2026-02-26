/**
 * whisper_wrapper.cpp - Implementation of C wrapper for whisper.cpp
 * 
 * This implementation wraps the whisper.cpp library and provides a clean C API
 * for use from Dart FFI. All functions are prefixed with 'kl_whisper_' to avoid
 * conflicts with the underlying whisper.cpp library.
 */

#define KL_WHISPER_WRAPPER_EXPORTS
#include "whisper_wrapper.h"

// Include whisper.cpp header
#include "whisper.h"

#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <mutex>
#include <chrono>
#include <fstream>
#include <algorithm>

// ============================================================================
// WAV File Loader
// ============================================================================

static bool load_wav_file(const char* path, std::vector<float>& pcm_out) {
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        return false;
    }

    // Read WAV header
    char riff[4];
    file.read(riff, 4);
    if (std::memcmp(riff, "RIFF", 4) != 0) {
        return false;
    }

    uint32_t chunk_size;
    file.read(reinterpret_cast<char*>(&chunk_size), 4);

    char wave[4];
    file.read(wave, 4);
    if (std::memcmp(wave, "WAVE", 4) != 0) {
        return false;
    }

    // Find fmt chunk
    uint16_t audio_format = 0;
    uint16_t num_channels = 0;
    uint32_t sample_rate = 0;
    uint16_t bits_per_sample = 0;

    while (file.good()) {
        char chunk_id[4];
        file.read(chunk_id, 4);
        if (!file.good()) break;

        uint32_t sub_chunk_size;
        file.read(reinterpret_cast<char*>(&sub_chunk_size), 4);
        if (!file.good()) break;

        if (std::memcmp(chunk_id, "fmt ", 4) == 0) {
            file.read(reinterpret_cast<char*>(&audio_format), 2);
            file.read(reinterpret_cast<char*>(&num_channels), 2);
            file.read(reinterpret_cast<char*>(&sample_rate), 4);
            uint32_t byte_rate;
            file.read(reinterpret_cast<char*>(&byte_rate), 4);
            uint16_t block_align;
            file.read(reinterpret_cast<char*>(&block_align), 2);
            file.read(reinterpret_cast<char*>(&bits_per_sample), 2);

            // Skip any extra format bytes
            if (sub_chunk_size > 16) {
                file.seekg(sub_chunk_size - 16, std::ios::cur);
            }
        } else if (std::memcmp(chunk_id, "data", 4) == 0) {
            // Read audio data
            size_t num_samples = sub_chunk_size / (bits_per_sample / 8);
            pcm_out.resize(num_samples / num_channels);

            if (bits_per_sample == 16 && audio_format == 1) {
                // PCM 16-bit
                std::vector<int16_t> raw_data(num_samples);
                file.read(reinterpret_cast<char*>(raw_data.data()), sub_chunk_size);

                // Convert to mono float32
                size_t out_idx = 0;
                for (size_t i = 0; i < num_samples; i += num_channels) {
                    float sample = 0.0f;
                    for (int ch = 0; ch < num_channels; ch++) {
                        sample += raw_data[i + ch] / 32768.0f;
                    }
                    pcm_out[out_idx++] = sample / num_channels;
                }
                pcm_out.resize(out_idx);

                // Reject non-16kHz audio — the Dart pipeline (FFmpeg) must
                // always pre-convert to 16 kHz before calling whisper.
                // Linear-interpolation resampling was removed because it
                // introduces aliasing artifacts that degrade transcription.
                if (sample_rate != 16000) {
                    fprintf(stderr, "[whisper_wrapper] Input audio must be 16 kHz. Got: %d Hz. Pre-process with FFmpeg: -ar 16000\n", sample_rate);
                    return false;
                }

                return true;
            } else if (bits_per_sample == 32 && audio_format == 3) {
                // Float32
                file.read(reinterpret_cast<char*>(pcm_out.data()), sub_chunk_size);
                return true;
            } else {
                return false; // Unsupported format
            }
        } else {
            // Skip unknown chunk
            file.seekg(sub_chunk_size, std::ios::cur);
        }
    }

    return false;
}

// ============================================================================
// Internal State
// ============================================================================

static thread_local std::string g_last_error;
static std::mutex g_error_mutex;

/// Internal context wrapper
struct kl_whisper_context {
    struct whisper_context* ctx;
    KLWhisperProgressCallback progress_callback;
    void* progress_user_data;
    std::string model_path;
    KLWhisperModelInfo model_info;
    std::string model_type_str;
    std::string languages_cache;
    bool using_gpu;
    std::atomic<bool> abort_flag{false};
};

// ============================================================================
// Error Handling
// ============================================================================

static void set_error(const char* msg) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error = msg ? msg : "Unknown error";
}

KL_WHISPER_API const char* kl_whisper_get_error(void) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    return g_last_error.empty() ? nullptr : g_last_error.c_str();
}

KL_WHISPER_API void kl_whisper_clear_error(void) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error.clear();
}

// ============================================================================
// Configuration
// ============================================================================

KL_WHISPER_API KLWhisperConfig kl_whisper_default_config(void) {
    KLWhisperConfig config = {};
    config.n_threads = 0; // Auto-detect
    config.use_gpu = true;
    config.gpu_device = 0;
    config.language = nullptr; // Auto-detect
    config.translate = false;
    config.word_timestamps = true;
    config.word_threshold = 0.01f;
    config.max_segment_length = 0; // No limit
    config.split_on_word = true;
    config.temperature = 0.0f; // Greedy
    config.beam_size = 5;
    config.entropy_threshold = 2.4f;
    config.suppress_blank = true;
    config.suppress_non_speech = true;
    config.no_speech_threshold = 0.6f;
    return config;
}

// ============================================================================
// Initialization & Cleanup
// ============================================================================

KL_WHISPER_API KLWhisperHandle kl_whisper_init_with_config(
    const char* model_path,
    const KLWhisperConfig* config
) {
    if (!model_path) {
        set_error("Model path is null");
        return nullptr;
    }

    const KLWhisperConfig effective_config = config ? *config : kl_whisper_default_config();

    // Initialize whisper context - try requested backend first, fallback to CPU
    struct whisper_context_params cparams = whisper_context_default_params();
    struct whisper_context* ctx = nullptr;
    bool using_gpu = false;

    cparams.use_gpu = effective_config.use_gpu;
    cparams.gpu_device = effective_config.gpu_device < 0 ? 0 : effective_config.gpu_device;

    ctx = whisper_init_from_file_with_params(model_path, cparams);

    if (ctx) {
        using_gpu = cparams.use_gpu;
    } else {
        // Requested mode failed, try CPU fallback
        cparams.use_gpu = false;
        cparams.gpu_device = 0;
        ctx = whisper_init_from_file_with_params(model_path, cparams);

        if (!ctx) {
            set_error("Failed to load whisper model (tried requested mode and CPU fallback)");
            return nullptr;
        }
    }

    // Create wrapper context
    auto* wrapper = new kl_whisper_context();
    wrapper->ctx = ctx;
    wrapper->progress_callback = nullptr;
    wrapper->progress_user_data = nullptr;
    wrapper->model_path = model_path;
    wrapper->using_gpu = using_gpu;

    // Extract model info
    wrapper->model_info.is_multilingual = whisper_is_multilingual(ctx);
    wrapper->model_info.using_gpu = using_gpu;
    wrapper->model_info.n_vocab = whisper_n_vocab(ctx);
    wrapper->model_info.n_audio_ctx = whisper_n_audio_ctx(ctx);
    wrapper->model_info.n_text_ctx = whisper_n_text_ctx(ctx);

    // Infer model type from filename
    std::string path(model_path);
    if (path.find("tiny") != std::string::npos) {
        wrapper->model_type_str = "tiny";
    } else if (path.find("base") != std::string::npos) {
        wrapper->model_type_str = "base";
    } else if (path.find("small") != std::string::npos) {
        wrapper->model_type_str = "small";
    } else if (path.find("medium") != std::string::npos) {
        wrapper->model_type_str = "medium";
    } else if (path.find("large") != std::string::npos) {
        wrapper->model_type_str = "large";
    } else {
        wrapper->model_type_str = "unknown";
    }
    wrapper->model_info.model_type = wrapper->model_type_str.c_str();

    kl_whisper_clear_error();
    return wrapper;
}

KL_WHISPER_API KLWhisperHandle kl_whisper_init(const char* model_path) {
    const KLWhisperConfig config = kl_whisper_default_config();
    return kl_whisper_init_with_config(model_path, &config);
}

KL_WHISPER_API void kl_whisper_free(KLWhisperHandle handle) {
    if (!handle) return;
    
    if (handle->ctx) {
        whisper_free(handle->ctx);
    }
    delete handle;
}

KL_WHISPER_API KLWhisperModelInfo kl_whisper_get_model_info(KLWhisperHandle handle) {
    if (!handle) {
        KLWhisperModelInfo empty = {};
        return empty;
    }
    return handle->model_info;
}

// ============================================================================
// Progress Callback
// ============================================================================

KL_WHISPER_API void kl_whisper_set_progress_callback(
    KLWhisperHandle handle,
    KLWhisperProgressCallback callback,
    void* user_data
) {
    if (!handle) return;
    handle->progress_callback = callback;
    handle->progress_user_data = user_data;
}

KL_WHISPER_API void kl_whisper_cancel(KLWhisperHandle handle) {
    if (!handle) return;
    handle->abort_flag.store(true, std::memory_order_release);
}

// Internal progress callback adapter
static void internal_progress_callback(
    struct whisper_context* /*ctx*/,
    struct whisper_state* /*state*/,
    int progress,
    void* user_data
) {
    auto* wrapper = static_cast<kl_whisper_context*>(user_data);
    if (wrapper && wrapper->progress_callback) {
        wrapper->progress_callback(progress, wrapper->progress_user_data);
    }
}

// ============================================================================
// Transcription Implementation
// ============================================================================

static KLWhisperResult* create_result_from_context(
    struct whisper_context* ctx,
    int64_t processing_time_ms,
    const char* language
) {
    int n_segments = whisper_full_n_segments(ctx);
    
    auto* result = new KLWhisperResult();
    result->num_segments = n_segments;
    result->segments = n_segments > 0 ? new KLWhisperSegment[n_segments] : nullptr;
    result->processing_time_ms = processing_time_ms;
    result->success = true;
    result->error_message = nullptr;
    result->language_probability = 1.0f;
    
    // Copy detected language
    static thread_local std::string lang_buf;
    lang_buf = language ? language : "en";
    result->detected_language = lang_buf.c_str();

    // Extract segments
    for (int i = 0; i < n_segments; i++) {
        KLWhisperSegment& seg = result->segments[i];
        
        seg.start_ms = whisper_full_get_segment_t0(ctx, i) * 10; // Convert to ms
        seg.end_ms = whisper_full_get_segment_t1(ctx, i) * 10;
        
        // Copy segment text
        const char* text = whisper_full_get_segment_text(ctx, i);
        char* text_copy = new char[strlen(text) + 1];
        strcpy(text_copy, text);
        seg.text = text_copy;
        
        seg.probability = 1.0f;
        
        // Extract word timestamps if available
        int n_tokens = whisper_full_n_tokens(ctx, i);
        std::vector<KLWhisperWord> words;
        
        for (int j = 0; j < n_tokens; j++) {
            whisper_token_data token = whisper_full_get_token_data(ctx, i, j);
            const char* token_text = whisper_full_get_token_text(ctx, i, j);
            
            // Skip special tokens
            if (token.id >= whisper_token_eot(ctx)) continue;
            if (!token_text || strlen(token_text) == 0) continue;
            
            KLWhisperWord word;
            word.start_ms = token.t0 * 10;
            word.end_ms = token.t1 * 10;
            word.probability = token.p;
            
            char* word_copy = new char[strlen(token_text) + 1];
            strcpy(word_copy, token_text);
            word.text = word_copy;
            
            words.push_back(word);
        }
        
        seg.num_words = static_cast<int32_t>(words.size());
        if (!words.empty()) {
            seg.words = new KLWhisperWord[words.size()];
            memcpy(seg.words, words.data(), words.size() * sizeof(KLWhisperWord));
        } else {
            seg.words = nullptr;
        }
    }

    return result;
}

KL_WHISPER_API KLWhisperResult* kl_whisper_transcribe_pcm(
    KLWhisperHandle handle,
    const float* samples,
    int32_t num_samples,
    const KLWhisperConfig* config
) {
    if (!handle || !handle->ctx) {
        set_error("Invalid handle");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    if (!samples || num_samples <= 0) {
        set_error("Invalid audio samples");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    KLWhisperConfig cfg = config ? *config : kl_whisper_default_config();

    // Set up whisper parameters
    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH);
    
    params.n_threads = cfg.n_threads > 0 ? cfg.n_threads : static_cast<int>(std::thread::hardware_concurrency());
    params.language = cfg.language;
    params.translate = cfg.translate;
    params.token_timestamps = cfg.word_timestamps;
    params.thold_pt = cfg.word_threshold;
    params.max_len = cfg.max_segment_length;
    params.split_on_word = cfg.split_on_word;
    params.temperature = cfg.temperature;
    params.beam_search.beam_size = cfg.beam_size;
    params.entropy_thold = cfg.entropy_threshold;
    params.suppress_blank = cfg.suppress_blank;
    params.suppress_non_speech_tokens = cfg.suppress_non_speech;
    params.no_speech_thold = cfg.no_speech_threshold;

    // Set progress callback if registered
    if (handle->progress_callback) {
        params.progress_callback = internal_progress_callback;
        params.progress_callback_user_data = handle;
    }

    // Set abort callback — allows kl_whisper_cancel() to interrupt whisper_full
    handle->abort_flag.store(false, std::memory_order_release);
    params.abort_callback = [](void* data) -> bool {
        auto* ctx = static_cast<kl_whisper_context*>(data);
        return ctx->abort_flag.load(std::memory_order_acquire);
    };
    params.abort_callback_user_data = handle;

    // Run transcription
    auto start_time = std::chrono::high_resolution_clock::now();
    
    int result_code = whisper_full(handle->ctx, params, samples, num_samples);
    
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);

    if (result_code != 0) {
        set_error("Transcription failed");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    return create_result_from_context(handle->ctx, duration.count(), cfg.language);
}

KL_WHISPER_API KLWhisperResult* kl_whisper_transcribe_file(
    KLWhisperHandle handle,
    const char* audio_path,
    const KLWhisperConfig* config
) {
    if (!handle || !handle->ctx) {
        set_error("Invalid handle");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    if (!audio_path) {
        set_error("Audio path is null");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    // Load audio file
    std::vector<float> pcm_data;
    
    if (!load_wav_file(audio_path, pcm_data)) {
        set_error("Failed to load audio file. Ensure it is a valid WAV file.");
        auto* result = new KLWhisperResult();
        result->success = false;
        result->error_message = kl_whisper_get_error();
        return result;
    }

    return kl_whisper_transcribe_pcm(
        handle,
        pcm_data.data(),
        static_cast<int32_t>(pcm_data.size()),
        config
    );
}

KL_WHISPER_API void kl_whisper_free_result(KLWhisperResult* result) {
    if (!result) return;

    // Free segments
    for (int i = 0; i < result->num_segments; i++) {
        KLWhisperSegment& seg = result->segments[i];
        
        // Free segment text
        delete[] seg.text;
        
        // Free words
        for (int j = 0; j < seg.num_words; j++) {
            delete[] seg.words[j].text;
        }
        delete[] seg.words;
    }
    delete[] result->segments;
    
    delete result;
}

// ============================================================================
// GPU Support
// ============================================================================

KL_WHISPER_API bool kl_whisper_gpu_available(void) {
#ifdef GGML_USE_CUDA
    return true;
#elif defined(GGML_USE_METAL)
    return true;
#elif defined(GGML_USE_VULKAN)
    return true;
#else
    return false;
#endif
}

KL_WHISPER_API const char* kl_whisper_gpu_name(void) {
#ifdef GGML_USE_CUDA
    return "CUDA";
#elif defined(GGML_USE_METAL)
    return "Metal";
#elif defined(GGML_USE_VULKAN)
    return "Vulkan";
#else
    return nullptr;
#endif
}

KL_WHISPER_API int32_t kl_whisper_gpu_count(void) {
#ifdef GGML_USE_CUDA
    return 1;
#elif defined(GGML_USE_METAL)
    return 1;
#else
    return 0;
#endif
}

// ============================================================================
// Utility Functions
// ============================================================================

KL_WHISPER_API const char* kl_whisper_version(void) {
    return "1.0.0";
}

KL_WHISPER_API const char* kl_whisper_supported_languages(KLWhisperHandle handle) {
    if (!handle || !handle->ctx) return nullptr;
    
    // Build comma-separated list of languages
    if (handle->languages_cache.empty()) {
        int max_lang_id = whisper_lang_max_id();
        for (int i = 0; i <= max_lang_id; i++) {
            const char* lang = whisper_lang_str(i);
            if (lang) {
                if (!handle->languages_cache.empty()) {
                    handle->languages_cache += ",";
                }
                handle->languages_cache += lang;
            }
        }
    }
    
    return handle->languages_cache.c_str();
}
