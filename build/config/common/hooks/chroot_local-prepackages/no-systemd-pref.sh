#!/bin/bash
# Place apt preferences file before package installation to block systemd

mkdir -p /etc/apt/preferences.d
cat > /etc/apt/preferences.d/no-systemd << 'PREF'
# NerfOS uses runit as PID 1 — block systemd from being installed
Package: systemd
Pin: release *
Pin-Priority: -1

Package: systemd-sysv
Pin: release *
Pin-Priority: -1

Package: live-config-systemd
Pin: release *
Pin-Priority: -1
PREF
