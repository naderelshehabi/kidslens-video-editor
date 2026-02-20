# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(kidslens_video_editor LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "kidslens_video_editor")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# ============================================================================
# Native Libraries Build Options
# ============================================================================
option(BUILD_WHISPER_WRAPPER "Build whisper_wrapper native library" ON)
option(WHISPER_USE_CUDA "Enable CUDA GPU acceleration for Whisper (preferred)" ON)
option(WHISPER_USE_VULKAN "Enable Vulkan GPU acceleration for Whisper (fallback)" ON)

# ============================================================================
# GPU Backend Auto-Detection: CUDA > Vulkan > CPU
# CUDA is preferred for NVIDIA GPUs (2-4x faster than Vulkan for whisper.cpp)
# Vulkan is the fallback for AMD/Intel GPUs
# CPU is the final fallback when no GPU SDK is available
# ============================================================================

# Step 1: Try CUDA (preferred — fastest for NVIDIA hardware)
if(WHISPER_USE_CUDA)
  include(CheckLanguage)
  check_language(CUDA)
  if(CMAKE_CUDA_COMPILER)
    enable_language(CUDA)
    message(STATUS "CUDA compiler found — enabling CUDA backend (preferred)")
    set(WHISPER_USE_CUDA ON CACHE BOOL "" FORCE)
    # When CUDA is available, disable Vulkan to avoid conflicts
    set(WHISPER_USE_VULKAN OFF CACHE BOOL "" FORCE)
  else()
    message(STATUS "CUDA compiler not found — falling back to Vulkan/CPU")
    set(WHISPER_USE_CUDA OFF CACHE BOOL "" FORCE)
  endif()
endif()

# Step 2: Try Vulkan (fallback for non-NVIDIA or when CUDA unavailable)
if(NOT WHISPER_USE_CUDA AND WHISPER_USE_VULKAN)
  find_package(Vulkan QUIET)
  if(NOT Vulkan_FOUND)
    message(STATUS "Vulkan SDK not found — building Whisper with CPU-only support")
    message(STATUS "For GPU acceleration, install:")
    message(STATUS "  NVIDIA: CUDA Toolkit — https://developer.nvidia.com/cuda-toolkit")
    message(STATUS "  AMD/Intel: Vulkan SDK — https://vulkan.lunarg.com/sdk/home")
    set(WHISPER_USE_VULKAN OFF CACHE BOOL "" FORCE)
  else()
    message(STATUS "Vulkan SDK found — GPU acceleration via Vulkan")
  endif()
endif()

# Summary
if(WHISPER_USE_CUDA)
  message(STATUS "Whisper GPU backend: CUDA")
elseif(WHISPER_USE_VULKAN)
  message(STATUS "Whisper GPU backend: Vulkan")
else()
  message(STATUS "Whisper GPU backend: CPU-only")
endif()

# ============================================================================
# Build whisper_wrapper native library
# ============================================================================
if(BUILD_WHISPER_WRAPPER)
  message(STATUS "Building whisper_wrapper native library...")
  
  # Add whisper subdirectory
  set(WHISPER_WRAPPER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../native/whisper")
  
  if(EXISTS "${WHISPER_WRAPPER_DIR}/CMakeLists.txt")
    # Configure whisper options before adding subdirectory
    set(WHISPER_WRAPPER_BUILD_SHARED ON CACHE BOOL "" FORCE)
    set(WHISPER_USE_BUNDLED ON CACHE BOOL "" FORCE)
    
    # Pass GPU options
    if(WHISPER_USE_CUDA)
      set(WHISPER_USE_CUDA ON CACHE BOOL "" FORCE)
    endif()
    if(WHISPER_USE_VULKAN)
      set(WHISPER_USE_VULKAN ON CACHE BOOL "" FORCE)
    endif()
    
    # EXCLUDE_FROM_ALL prevents whisper.cpp's install targets from running
    # We handle installation of whisper_wrapper ourselves below
    add_subdirectory("${WHISPER_WRAPPER_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/whisper_wrapper" EXCLUDE_FROM_ALL)
    
    # Make whisper_wrapper build as part of the default ALL target
    set_target_properties(whisper_wrapper PROPERTIES EXCLUDE_FROM_ALL FALSE)
    
    # Add to bundled libraries for installation
    set(WHISPER_WRAPPER_LIBRARY "$<TARGET_FILE:whisper_wrapper>")
    list(APPEND NATIVE_BUNDLED_LIBRARIES "${WHISPER_WRAPPER_LIBRARY}")
  else()
    message(WARNING "whisper_wrapper not found at ${WHISPER_WRAPPER_DIR}")
  endif()
endif()

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# ============================================================================
# Install whisper_wrapper native library
# ============================================================================
if(BUILD_WHISPER_WRAPPER AND TARGET whisper_wrapper)
  install(TARGETS whisper_wrapper
    RUNTIME DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    LIBRARY DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  message(STATUS "whisper_wrapper will be installed to ${INSTALL_BUNDLE_LIB_DIR}")
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
