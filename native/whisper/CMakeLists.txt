# CMakeLists.txt for whisper_wrapper native library
#
# This builds the whisper_wrapper shared library which wraps whisper.cpp
# for use from Dart FFI.
#
# Prerequisites:
# 1. whisper.cpp source code (or pre-built library)
# 2. CMake 3.16+
# 3. C++17 compatible compiler
#
# Build instructions:
# Windows: cmake -B build -G "Visual Studio 17 2022" && cmake --build build --config Release
# Linux/macOS: cmake -B build && cmake --build build

cmake_minimum_required(VERSION 3.16)
project(whisper_wrapper VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Options
option(WHISPER_WRAPPER_BUILD_SHARED "Build shared library" ON)
option(WHISPER_USE_CUDA "Enable CUDA support" OFF)
option(WHISPER_USE_METAL "Enable Metal support (macOS)" OFF)
option(WHISPER_USE_VULKAN "Enable Vulkan support" OFF)
option(WHISPER_USE_BUNDLED "Use bundled whisper.cpp" ON)

# Find or build whisper.cpp
if(WHISPER_USE_BUNDLED)
    # Use FetchContent to download whisper.cpp
    include(FetchContent)
    
    FetchContent_Declare(
        whisper
        GIT_REPOSITORY https://github.com/ggml-org/whisper.cpp.git
        GIT_TAG        v1.7.3
        GIT_SHALLOW    TRUE
    )
    
    # Configure whisper.cpp build options
    set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE) # Build whisper as static
    
    # Disable whisper's install targets - we handle installation ourselves
    set(WHISPER_NO_INSTALL ON CACHE BOOL "" FORCE)
    set(GGML_NO_INSTALL ON CACHE BOOL "" FORCE)
    
    if(WHISPER_USE_CUDA)
        set(GGML_CUDA ON CACHE BOOL "" FORCE)
    endif()
    if(WHISPER_USE_METAL)
        set(GGML_METAL ON CACHE BOOL "" FORCE)
    endif()
    if(WHISPER_USE_VULKAN)
        set(GGML_VULKAN ON CACHE BOOL "" FORCE)
    endif()

    # Enable SIMD optimizations for CPU inference (Intel Haswell 2013+ / AMD Zen 2017+)
    set(GGML_AVX2  ON CACHE BOOL "" FORCE)
    set(GGML_FMA   ON CACHE BOOL "" FORCE)
    set(GGML_F16C  ON CACHE BOOL "" FORCE)
    
    FetchContent_MakeAvailable(whisper)
    
    set(WHISPER_INCLUDE_DIR "${whisper_SOURCE_DIR}/include")
    set(WHISPER_LIBRARY whisper)
else()
    # Find pre-installed whisper
    find_path(WHISPER_INCLUDE_DIR whisper.h
        HINTS
            ${WHISPER_ROOT}/include
            $ENV{WHISPER_ROOT}/include
            /usr/local/include
            /usr/include
    )
    
    find_library(WHISPER_LIBRARY
        NAMES whisper whisper.cpp
        HINTS
            ${WHISPER_ROOT}/lib
            $ENV{WHISPER_ROOT}/lib
            /usr/local/lib
            /usr/lib
    )
    
    if(NOT WHISPER_INCLUDE_DIR OR NOT WHISPER_LIBRARY)
        message(FATAL_ERROR "whisper.cpp not found. Set WHISPER_ROOT or enable WHISPER_USE_BUNDLED.")
    endif()
endif()

# Source files
set(WRAPPER_SOURCES
    whisper_wrapper.cpp
)

set(WRAPPER_HEADERS
    whisper_wrapper.h
)

# Build library
if(WHISPER_WRAPPER_BUILD_SHARED)
    add_library(whisper_wrapper SHARED ${WRAPPER_SOURCES} ${WRAPPER_HEADERS})
    target_compile_definitions(whisper_wrapper PRIVATE WHISPER_WRAPPER_EXPORTS)
else()
    add_library(whisper_wrapper STATIC ${WRAPPER_SOURCES} ${WRAPPER_HEADERS})
endif()

# Include directories
target_include_directories(whisper_wrapper
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${WHISPER_INCLUDE_DIR}
)

# Link whisper
target_link_libraries(whisper_wrapper PRIVATE ${WHISPER_LIBRARY})

# Platform-specific settings
if(WIN32)
    target_compile_definitions(whisper_wrapper PRIVATE
        _CRT_SECURE_NO_WARNINGS
        NOMINMAX
    )
    # Enable exceptions on MSVC
    if(MSVC)
        target_compile_options(whisper_wrapper PRIVATE /EHsc)
    endif()
endif()

if(APPLE)
    # Link frameworks needed by Metal
    if(WHISPER_USE_METAL)
        target_link_libraries(whisper_wrapper PRIVATE
            "-framework Foundation"
            "-framework Metal"
            "-framework MetalKit"
        )
    endif()
endif()

if(UNIX AND NOT APPLE)
    target_link_libraries(whisper_wrapper PRIVATE pthread)
endif()

# GPU-specific definitions
if(WHISPER_USE_CUDA)
    target_compile_definitions(whisper_wrapper PRIVATE GGML_USE_CUDA)
endif()
if(WHISPER_USE_METAL)
    target_compile_definitions(whisper_wrapper PRIVATE GGML_USE_METAL)
endif()
if(WHISPER_USE_VULKAN)
    target_compile_definitions(whisper_wrapper PRIVATE GGML_USE_VULKAN)
endif()

# Installation (when built standalone)
# When included as subdirectory, the parent project handles installation
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    include(GNUInstallDirs)
    
    install(TARGETS whisper_wrapper
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    
    install(FILES ${WRAPPER_HEADERS}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
endif()

# Output location info
message(STATUS "whisper_wrapper build configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Shared library: ${WHISPER_WRAPPER_BUILD_SHARED}")
message(STATUS "  CUDA support: ${WHISPER_USE_CUDA}")
message(STATUS "  Metal support: ${WHISPER_USE_METAL}")
message(STATUS "  Vulkan support: ${WHISPER_USE_VULKAN}")
