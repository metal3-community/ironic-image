# Simple Ironic Python Agent (IPA) Builder
FROM debian:bookworm

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    qemu-utils \
    qemu-user-static \
    debootstrap \
    squashfs-tools \
    sudo \
    procps \
    cpio \
    kpartx \
    parted \
    e2fsprogs \
    gdisk \
    dosfstools \
    && rm -rf /var/lib/apt/lists/*

# Install ironic-python-agent-builder
# Install diskimage-builder and ironic-python-agent-builder
RUN pip3 install --break-system-packages diskimage-builder ironic-python-agent-builder

# Copy build script to /usr/local/bin
COPY build-both.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build-both.sh

# Create build directory
WORKDIR /build

# Default command to build IPA for both architectures
CMD ["/usr/local/bin/build-both.sh"]