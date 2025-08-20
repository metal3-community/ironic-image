#!/bin/bash

# Build IPA for both ARM64 and AMD64 architectures

set -e

echo "Building Ironic Python Agent for both architectures..."

# Clean up any existing files
rm -rf /tmp/dib_* /opt/build/* || true

# Create build directory with more space
mkdir -p /opt/build && cd /opt/build

# Set environment variables for disk image builder
export DIB_MANIFEST_SAVE_DIR=""
export DIB_IMAGE_SIZE=8
export TMP_MOUNT_PATH=/tmp
export DIB_CHECKSUM=0
export DIB_NO_TMPFS=1

# Ensure we have enough space
df -h /tmp

# Build for ARM64
echo "Building for ARM64..."
export IPA_REMOVE_FIRMWARE="amdgpu,netronome,ti-communication,ti-keystone,ueagle-atm,rsi,mrvl,mediatek,ath10k,rtlwifi"
export ARCH=arm64

# Clear any previous builds
rm -f ironic-python-agent-arm64* || true

ironic-python-agent-builder -o ironic-python-agent-arm64 --release bookworm debian || {
    echo "ARM64 build had some warnings but may have succeeded"
    if [ -f "ironic-python-agent-arm64.kernel" ] && [ -f "ironic-python-agent-arm64.initramfs" ]; then
        echo "ARM64 files found despite warnings"
    else
        echo "ARM64 build actually failed"
        exit 1
    fi
}

# Clean up temp files to save space
rm -rf /tmp/dib_* || true

# Copy files to output directory
cp -f ironic-python-agent-arm64.* /build/ 2>/dev/null || true

# Build for AMD64
echo "Building for AMD64..."
export ARCH=amd64

# Clear any previous builds
rm -f ironic-python-agent-amd64* || true

ironic-python-agent-builder -o ironic-python-agent-amd64 --release bookworm debian || {
    echo "AMD64 build had some warnings but may have succeeded"
    if [ -f "ironic-python-agent-amd64.kernel" ] && [ -f "ironic-python-agent-amd64.initramfs" ]; then
        echo "AMD64 files found despite warnings"
    else
        echo "AMD64 build actually failed"
        exit 1
    fi
}

echo "Build completed!"
echo "Generated files:"
ls -la ironic-python-agent-*.{kernel,initramfs} 2>/dev/null || echo "Files not found"

# Copy final files to output directory
cp -f ironic-python-agent-*.* /build/ 2>/dev/null || true

# Show file sizes
echo ""
echo "File sizes:"
for file in ironic-python-agent-*.{kernel,initramfs}; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "$file: $size"
    fi
done