/**
 * whisper_wrapper.h - C wrapper for whisper.cpp
 * 
 * This wrapper provides a simplified C API for whisper.cpp that can be
 * called from Dart via FFI. It handles memory management and provides
 * a clean interface for transcription operations.
 * 
 * All functions are prefixed with 'kl_whisper_' to avoid conflicts with
 * the underlying whisper.cpp library.
 */

#ifndef KL_WHISPER_WRAPPER_H
#define KL_WHISPER_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #ifdef KL_WHISPER_WRAPPER_EXPORTS
    #define KL_WHISPER_API __declspec(dllexport)
  #else
    #define KL_WHISPER_API __declspec(dllimport)
  #endif
#else
  #define KL_WHISPER_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Opaque Handles
// ============================================================================

/// Opaque handle to whisper context
typedef struct kl_whisper_context* KLWhisperHandle;

// ============================================================================
// Data Structures
// ============================================================================

/// Word-level timestamp information
typedef struct {
    int64_t start_ms;       ///< Start timestamp in milliseconds
    int64_t end_ms;         ///< End timestamp in milliseconds
    const char* text;       ///< Word text (null-terminated, owned by result)
    float probability;      ///< Confidence score (0.0 to 1.0)
} KLWhisperWord;

/// Segment (sentence/phrase) with optional word timestamps
typedef struct {
    int64_t start_ms;       ///< Segment start timestamp in milliseconds
    int64_t end_ms;         ///< Segment end timestamp in milliseconds
    const char* text;       ///< Segment text (null-terminated, owned by result)
    float probability;      ///< Average confidence score
    int32_t num_words;      ///< Number of words (0 if word timestamps disabled)
    KLWhisperWord* words;   ///< Word-level timestamps (NULL if disabled)
} KLWhisperSegment;

/// Complete transcription result
typedef struct {
    int32_t num_segments;           ///< Number of segments
    KLWhisperSegment* segments;     ///< Array of segments
    const char* detected_language;  ///< ISO 639-1 language code
    float language_probability;     ///< Language detection confidence
    int64_t processing_time_ms;     ///< Time taken to transcribe
    bool success;                   ///< Whether transcription succeeded
    const char* error_message;      ///< Error message if failed
} KLWhisperResult;

/// Transcription configuration
typedef struct {
    int32_t n_threads;          ///< Number of CPU threads (0 = auto)
    bool use_gpu;               ///< Enable GPU acceleration
    int32_t gpu_device;         ///< GPU device index
    const char* language;       ///< Language code or NULL for auto-detect
    bool translate;             ///< Translate to English
    bool word_timestamps;       ///< Enable word-level timestamps
    float word_threshold;       ///< Minimum probability for words
    int32_t max_segment_length; ///< Max chars per segment (0 = no limit)
    bool split_on_word;         ///< Split segments on word boundaries
    float temperature;          ///< Sampling temperature (0 = greedy)
    int32_t beam_size;          ///< Beam search width
    float entropy_threshold;    ///< Fallback entropy threshold
    bool suppress_blank;        ///< Suppress blank outputs
    bool suppress_non_speech;   ///< Suppress non-speech tokens
    float no_speech_threshold;  ///< No-speech probability threshold
} KLWhisperConfig;

/// Model information
typedef struct {
    const char* model_type;     ///< Model type (tiny, base, small, etc.)
    bool is_multilingual;       ///< Whether model supports multiple languages
    bool using_gpu;             ///< Whether GPU acceleration is active
    int32_t n_vocab;            ///< Vocabulary size
    int32_t n_audio_ctx;        ///< Audio context size
    int32_t n_text_ctx;         ///< Text context size
} KLWhisperModelInfo;

/// Progress callback type
typedef void (*KLWhisperProgressCallback)(int progress, void* user_data);

// ============================================================================
// Initialization & Cleanup
// ============================================================================

/// Initialize whisper context from model file
KL_WHISPER_API KLWhisperHandle kl_whisper_init(const char* model_path);

/// Free whisper context and resources
KL_WHISPER_API void kl_whisper_free(KLWhisperHandle handle);

/// Get default transcription configuration
KL_WHISPER_API KLWhisperConfig kl_whisper_default_config(void);

/// Get model information
KL_WHISPER_API KLWhisperModelInfo kl_whisper_get_model_info(KLWhisperHandle handle);

// ============================================================================
// Transcription
// ============================================================================

/// Transcribe audio file (WAV format, will resample to 16kHz mono)
KL_WHISPER_API KLWhisperResult* kl_whisper_transcribe_file(
    KLWhisperHandle handle,
    const char* audio_path,
    const KLWhisperConfig* config
);

/// Transcribe PCM audio data (16kHz, mono, float32)
KL_WHISPER_API KLWhisperResult* kl_whisper_transcribe_pcm(
    KLWhisperHandle handle,
    const float* samples,
    int32_t num_samples,
    const KLWhisperConfig* config
);

/// Free transcription result
KL_WHISPER_API void kl_whisper_free_result(KLWhisperResult* result);

// ============================================================================
// Progress & Callbacks
// ============================================================================

/// Set progress callback for long transcriptions
KL_WHISPER_API void kl_whisper_set_progress_callback(
    KLWhisperHandle handle,
    KLWhisperProgressCallback callback,
    void* user_data
);

// ============================================================================
// Error Handling
// ============================================================================

/// Get last error message
KL_WHISPER_API const char* kl_whisper_get_error(void);

/// Clear last error
KL_WHISPER_API void kl_whisper_clear_error(void);

// ============================================================================
// GPU Support
// ============================================================================

/// Check if GPU acceleration is available
KL_WHISPER_API bool kl_whisper_gpu_available(void);

/// Get GPU backend name
KL_WHISPER_API const char* kl_whisper_gpu_name(void);

/// Get number of available GPUs
KL_WHISPER_API int32_t kl_whisper_gpu_count(void);

// ============================================================================
// Utility Functions
// ============================================================================

/// Get whisper wrapper version
KL_WHISPER_API const char* kl_whisper_version(void);

/// Get supported languages (comma-separated)
KL_WHISPER_API const char* kl_whisper_supported_languages(KLWhisperHandle handle);

#ifdef __cplusplus
}
#endif

#endif // KL_WHISPER_WRAPPER_H
