#!/bin/bash

# Simple IPA build script for both architectures

set -e

IMAGE_NAME="ipa-builder"
TAG="latest"
OUTPUT_DIR="./ipa-images"

echo "Building IPA builder for both architectures..."

# Create output directory
mkdir -p $OUTPUT_DIR

# Build the image
docker build -t $IMAGE_NAME:$TAG .

echo "Building IPA for both ARM64 and AMD64..."

TEMP_DIR="$(mktemp -d)"

# Run the container to build both architectures
docker run --rm \
    --privileged \
    --tmpfs /tmp:size=4g \
    --shm-size=2g \
    -v $TEMP_DIR:/tmp \
    -v $PWD/$OUTPUT_DIR:/build \
    $IMAGE_NAME:$TAG

echo "Build complete!"
echo "Images available in: $OUTPUT_DIR"
ls -la $OUTPUT_DIR/

echo ""
echo "Generated files:"
echo "- ironic-python-agent-arm64.kernel: Kernel for ARM64 systems"
echo "- ironic-python-agent-arm64.initramfs: Ramdisk for ARM64 systems"
echo "- ironic-python-agent-amd64.kernel: Kernel for AMD64 systems"
echo "- ironic-python-agent-amd64.initramfs: Ramdisk for AMD64 systems"

# Show file sizes
echo ""
echo "File sizes:"
du -h $OUTPUT_DIR/ironic-python-agent-*.{kernel,initramfs} 2>/dev/null || echo "No files generated"