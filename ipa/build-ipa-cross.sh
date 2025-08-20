#!/bin/bash

# Cross-compilation Ironic Python Agent (IPA) build script
# Builds both AMD64 and ARM64 images in a single run

set -e

OUTPUT_DIR=${OUTPUT_DIR:-/output}
BUILD_DIR="/tmp/ipa-build"
CACHE_DIR="/tmp/dib_cache"

echo "Starting cross-compilation IPA build for both AMD64 and ARM64..."

# Create directories
mkdir -p $BUILD_DIR $CACHE_DIR $OUTPUT_DIR

# Common environment variables
export DIB_CHECKSUM=1
export DIB_IMAGE_CACHE=$CACHE_DIR
export DIB_JOURNAL_SIZE=0
export DIB_RELEASE=bookworm
export DIB_CHECKSUM=1
export DIB_IMAGE_CACHE=$CACHE_DIR
export DIB_JOURNAL_SIZE=0
export ELEMENTS_PATH="/usr/share/diskimage-builder/elements"
export DIB_RELEASE=bookworm

# Function to build IPA for specific architecture
build_ipa() {
    local arch=$1
    local build_subdir="$BUILD_DIR/$arch"
    
    echo "Building IPA for $arch architecture..."
    
    # Create architecture-specific build directory
    mkdir -p $build_subdir
    cd $build_subdir
    
    # Set architecture environment variable for ironic-python-agent-builder
    if [ "$arch" = "arm64" ]; then
        export ARCH=aarch64
    else
        export ARCH=amd64
    fi
    
    echo "Building IPA using ironic-python-agent-builder for $arch..."
    
    # Build the IPA using ironic-python-agent-builder
    ironic-python-agent-builder -o ipa-$arch --release bookworm debian
    
    echo "Build completed for $arch!"
    
    # Copy files to output directory
    if [ -f "ipa-$arch.kernel" ] && [ -f "ipa-$arch.initramfs" ]; then
        cp "ipa-$arch.kernel" "$OUTPUT_DIR/"
        cp "ipa-$arch.initramfs" "$OUTPUT_DIR/"
        echo "Files copied: ipa-$arch.kernel, ipa-$arch.initramfs"
    else
        echo "ERROR: Expected files not found for $arch"
        ls -la
        return 1
    fi
}

# Setup cross-compilation environment
echo "Setting up cross-compilation environment..."

# Source the diskimage-builder configuration
if [ -f /tmp/dib-config-env ]; then
    source /tmp/dib-config-env
else
    echo "Warning: DIB configuration not found, setting default elements path..."
    # Try to find diskimage-builder elements
    DIB_PKG_PATH=$(python3 -c "import diskimage_builder; import os; print(os.path.dirname(diskimage_builder.__file__))" 2>/dev/null)
    if [ -n "$DIB_PKG_PATH" ] && [ -d "$DIB_PKG_PATH/elements" ]; then
        export ELEMENTS_PATH="$DIB_PKG_PATH/elements:/usr/local/share/diskimage-builder/elements"
    else
        export ELEMENTS_PATH="/usr/share/diskimage-builder/elements:/usr/local/share/diskimage-builder/elements"
    fi
fi

echo "Using ELEMENTS_PATH: $ELEMENTS_PATH"

# Ensure binfmt is properly configured
if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    echo "ARM64 emulation already enabled"
else
    echo "Enabling ARM64 emulation..."
    # Register qemu-aarch64-static manually if update-binfmts fails
    if ! update-binfmts --enable qemu-aarch64 2>/dev/null; then
        echo "update-binfmts failed, registering qemu-aarch64-static manually..."
        if [ -f /usr/bin/qemu-aarch64-static ]; then
            echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || echo "Warning: Failed to register ARM64 emulation"
        else
            echo "Warning: qemu-aarch64-static not found"
        fi
    fi
fi

# Build for AMD64 first (native)
build_ipa "amd64"

# Build for ARM64 (cross-compiled)
build_ipa "arm64"

# Set proper permissions
chmod 644 "$OUTPUT_DIR"/ipa-*.*

echo ""
echo "Cross-compilation build completed successfully!"
echo "Generated files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"/ipa-*.*

# Calculate and show file sizes
echo ""
echo "Summary:"
for file in "$OUTPUT_DIR"/ipa-*.*; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "$(basename "$file"): $size"
    fi
done