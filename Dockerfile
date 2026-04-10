FROM debian:trixie

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Block systemd (consistent with the ISO build philosophy)
RUN printf 'Package: systemd systemd-sysv\nPin: release *\nPin-Priority: -1\n' \
    > /etc/apt/preferences.d/block-systemd

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Init and session management
    runit \
    elogind \
    libpam-elogind \
    # Network
    network-manager \
    wpasupplicant \
    # Firewall
    ufw \
    # System tools
    bash \
    busybox-syslogd \
    util-linux \
    procps \
    psmisc \
    less \
    file \
    # Compression
    zip \
    unzip \
    xz-utils \
    # Terminal tools
    nano \
    mc \
    htop \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# NerfOS version branding
COPY build/config/common/includes.chroot/etc/nerf-os/version /etc/nerf-os/version

LABEL org.opencontainers.image.title="NerfOS" \
      org.opencontainers.image.description="NerfOS base image — Debian Trixie with runit, no systemd" \
      org.opencontainers.image.source="https://github.com/maistruk-dmytro/nerf-os"

CMD ["/bin/bash"]
