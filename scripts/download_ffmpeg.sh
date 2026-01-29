#!/bin/bash
#
# FFmpeg Binary Downloader for KidsLens Video Editor
#
# Downloads FFmpeg static builds for macOS/Linux from:
# - macOS: evermeet.cx
# - Linux: johnvansickle.com
#
# Usage:
#   ./download_ffmpeg.sh [options]
#
# Options:
#   --platform=<platform>  Target platform (macos-universal, linux-x64, linux-arm64)
#   --force                Force re-download even if binaries exist
#   --output=<dir>         Custom output directory
#   --help                 Show help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
PLATFORM=""
FORCE=false
OUTPUT_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform=*)
            PLATFORM="${1#*=}"
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --output=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --help)
            echo "FFmpeg Binary Downloader for KidsLens Video Editor"
            echo ""
            echo "Usage:"
            echo "  ./download_ffmpeg.sh [options]"
            echo ""
            echo "Options:"
            echo "  --platform=<platform>  Target platform:"
            echo "                         - macos-universal (default on macOS)"
            echo "                         - linux-x64 (default on Linux x64)"
            echo "                         - linux-arm64"
            echo "  --force                Force re-download even if binaries exist"
            echo "  --output=<dir>         Custom output directory"
            echo "  --help                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./download_ffmpeg.sh"
            echo "  ./download_ffmpeg.sh --platform=linux-arm64"
            echo "  ./download_ffmpeg.sh --force"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Detect platform if not specified
detect_platform() {
    if [[ -z "$PLATFORM" ]]; then
        case "$(uname -s)" in
            Darwin)
                PLATFORM="macos-universal"
                ;;
            Linux)
                case "$(uname -m)" in
                    x86_64)
                        PLATFORM="linux-x64"
                        ;;
                    aarch64|arm64)
                        PLATFORM="linux-arm64"
                        ;;
                    *)
                        echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"
                        exit 1
                        ;;
                esac
                ;;
            *)
                echo -e "${RED}Unsupported OS: $(uname -s)${NC}"
                exit 1
                ;;
        esac
    fi
}

# Set output directory
set_output_dir() {
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$PROJECT_DIR/native/ffmpeg/binaries"
    fi
    PLATFORM_DIR="$OUTPUT_DIR/$PLATFORM"
}

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       FFmpeg Downloader for KidsLens Video Editor          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Platform: $PLATFORM${NC}"
    echo -e "${WHITE}Output: $PLATFORM_DIR${NC}"
    echo ""
}

# Download file with progress
download_file() {
    local url=$1
    local dest=$2
    
    echo -e "${WHITE}Downloading from: $url${NC}"
    
    # Create parent directory
    mkdir -p "$(dirname "$dest")"
    
    # Use curl with progress
    if command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$dest" -H "User-Agent: KidsLens-Video-Editor" "$url"
    elif command -v wget &> /dev/null; then
        wget --progress=bar:force -O "$dest" --header="User-Agent: KidsLens-Video-Editor" "$url"
    else
        echo -e "${RED}Error: curl or wget is required${NC}"
        exit 1
    fi
    
    local size=$(du -h "$dest" | cut -f1)
    echo -e "${GREEN}Downloaded: $size${NC}"
}

# Download FFmpeg for macOS
download_macos() {
    local temp_dir=$(mktemp -d)
    
    echo -e "${YELLOW}Downloading FFmpeg for macOS...${NC}"
    
    # Download ffmpeg
    download_file "https://evermeet.cx/ffmpeg/getrelease/zip" "$temp_dir/ffmpeg.zip"
    
    echo -e "${YELLOW}Extracting ffmpeg...${NC}"
    unzip -q -o "$temp_dir/ffmpeg.zip" -d "$temp_dir"
    
    mkdir -p "$PLATFORM_DIR"
    
    # Find and copy ffmpeg binary
    if [[ -f "$temp_dir/ffmpeg" ]]; then
        cp "$temp_dir/ffmpeg" "$PLATFORM_DIR/"
        chmod +x "$PLATFORM_DIR/ffmpeg"
        echo -e "${WHITE}  Copied: ffmpeg${NC}"
    else
        echo -e "${RED}  Error: ffmpeg not found in archive${NC}"
    fi
    
    # Download ffprobe separately
    echo -e "${YELLOW}Downloading ffprobe for macOS...${NC}"
    download_file "https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip" "$temp_dir/ffprobe.zip"
    
    echo -e "${YELLOW}Extracting ffprobe...${NC}"
    unzip -q -o "$temp_dir/ffprobe.zip" -d "$temp_dir"
    
    if [[ -f "$temp_dir/ffprobe" ]]; then
        cp "$temp_dir/ffprobe" "$PLATFORM_DIR/"
        chmod +x "$PLATFORM_DIR/ffprobe"
        echo -e "${WHITE}  Copied: ffprobe${NC}"
    else
        echo -e "${RED}  Error: ffprobe not found in archive${NC}"
    fi
    
    # Remove quarantine attribute (macOS security)
    if command -v xattr &> /dev/null; then
        xattr -d com.apple.quarantine "$PLATFORM_DIR/ffmpeg" 2>/dev/null || true
        xattr -d com.apple.quarantine "$PLATFORM_DIR/ffprobe" 2>/dev/null || true
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Download FFmpeg for Linux
download_linux() {
    local arch=$1
    local temp_dir=$(mktemp -d)
    
    echo -e "${YELLOW}Downloading FFmpeg for Linux ($arch)...${NC}"
    
    local url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-${arch}-static.tar.xz"
    local archive="$temp_dir/ffmpeg.tar.xz"
    
    download_file "$url" "$archive"
    
    echo -e "${YELLOW}Extracting archive...${NC}"
    
    mkdir -p "$temp_dir/extracted"
    tar -xJf "$archive" -C "$temp_dir/extracted" --strip-components=1
    
    mkdir -p "$PLATFORM_DIR"
    
    # Copy binaries
    for binary in ffmpeg ffprobe; do
        if [[ -f "$temp_dir/extracted/$binary" ]]; then
            cp "$temp_dir/extracted/$binary" "$PLATFORM_DIR/"
            chmod +x "$PLATFORM_DIR/$binary"
            echo -e "${WHITE}  Copied: $binary${NC}"
        else
            echo -e "${YELLOW}  Warning: $binary not found${NC}"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Verify installation
verify_installation() {
    local ffmpeg_path="$PLATFORM_DIR/ffmpeg"
    
    if [[ -f "$ffmpeg_path" ]]; then
        local version=$("$ffmpeg_path" -version 2>&1 | head -1 | grep -oE 'ffmpeg version [^ ]+' | cut -d' ' -f3)
        if [[ -n "$version" ]]; then
            echo -e "${GREEN}  Verified: FFmpeg $version${NC}"
        fi
    fi
}

# Main function
main() {
    detect_platform
    set_output_dir
    print_header
    
    # Check if binaries already exist
    if [[ -f "$PLATFORM_DIR/ffmpeg" ]] && [[ "$FORCE" != true ]]; then
        echo -e "${YELLOW}FFmpeg binaries already exist at: $PLATFORM_DIR${NC}"
        echo -e "${YELLOW}Use --force to re-download${NC}"
        verify_installation
        exit 0
    fi
    
    # Download based on platform
    case "$PLATFORM" in
        macos-universal)
            download_macos
            ;;
        linux-x64)
            download_linux "amd64"
            ;;
        linux-arm64)
            download_linux "arm64"
            ;;
        *)
            echo -e "${RED}Unknown platform: $PLATFORM${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ FFmpeg binaries installed to: $PLATFORM_DIR${NC}"
    
    verify_installation
}

# Run main function
main
