# NerfOS v1 Design Spec

**Date:** 2026-04-02
**Status:** Approved

---

## Overview

NerfOS is a lightweight Linux distribution targeting 2008–2015 hardware. The focus of v1 is **performance, effectiveness, and stability** — reviving old PCs into usable machines for non-technical users.

**Not** a security-hardened OS in v1. Not a feature-rich OS. The philosophy: *what you remove matters more than what you add.*

---

## Target Hardware

| Spec | Target |
|---|---|
| RAM | 512MB – 2GB |
| CPU | Old Intel/AMD (no AVX required) |
| Storage | HDD (not SSD) |
| Architecture | i686 (32-bit) and x86_64 (64-bit) |
| Era | 2008–2015 laptops and desktops |

**Boot goal:** Under 20 seconds on HDD.
**RAM goal:** ~120–160MB idle in GUI mode, ~60–80MB in Terminal mode.

---

## Base System

- **Distro:** Debian 13 Trixie (minimal) via `debootstrap`
- **Init system:** runit (packages pulled from antiX 26 repositories)
- **No systemd** — runit gives the fastest HDD boot of any init system (5–12s vs 15–35s for systemd)
- **Kernel:** Debian 13 LTS kernel (6.6 series for 64-bit, 5.10 series for 32-bit)
- **Package manager:** APT (full Debian 13 ecosystem, 38,000+ packages)

---

## ISOs

Two ISOs per release, built from a single `live-build` config tree:

| ISO | Architecture |
|---|---|
| `nerf-os-1.0-x86_64.iso` | 64-bit |
| `nerf-os-1.0-i686.iso` | 32-bit |

The config tree is identical for both; `i686/` overrides only the kernel package and architecture target.

---

## Boot Menu

```
┌─────────────────────────────┐
│  NerfOS                     │
│                             │
│  > Start NerfOS (GUI)       │
│    Start NerfOS (Terminal)  │
│    Install NerfOS           │
│    Boot from HDD            │
└─────────────────────────────┘
```

Boot mode is passed as a kernel parameter (`nerf.mode=gui` or `nerf.mode=terminal`). A detection script at `/etc/runit/core-services` reads this parameter and symlinks the appropriate service set into `/etc/runit/runsvdir/default/` before runit starts.

---

## Boot Modes

### GUI Mode (default)
- runit service set: dbus, NetworkManager, syslog, lightdm, ufw, alsa
- lightdm autologin → Openbox session
- tint2 panel: app launcher, system tray, clock, battery indicator
- **RAM target:** ~120–160MB idle
- **Intended for:** normal daily use

### Terminal Mode
- runit service set: dbus, NetworkManager, syslog, ufw
- Drops to bash login shell
- Tools: nano, mc, links2, nmtui, htop, curl, wget
- **RAM target:** ~60–80MB idle
- **Intended for:** very low RAM machines (<512MB), recovery, power users

---

## App Stack

### GUI Mode

| Category | App |
|---|---|
| Browser (default) | Firefox-ESR (tuned) |
| Browser (lite) | Midori |
| File manager | PCManFM |
| Text editor | mousepad |
| Terminal | lxterminal |
| Image viewer | gpicview |
| Archive manager | file-roller |
| Network | nm-applet |

### Terminal Mode

| Tool | Purpose |
|---|---|
| nano | Text editing |
| mc | File manager (Midnight Commander) |
| links2 | Text-mode browser |
| nmtui | Network configuration TUI |
| htop | Process monitor |
| curl / wget | Downloads |

### Firefox-ESR Tuning
Applied via locked `policies.json`:
- Disable telemetry, crash reporter, Pocket
- Disable hardware acceleration (broken on old GPU drivers)
- Memory cache limit: 128MB
- Disable WebGL (stability on old GPUs)

### Explicitly Excluded in v1
- No office suite (installable post-setup via APT)
- No media player
- No email client
- No snap / flatpak

---

## Performance Optimizations

### zram (mandatory)
- Algorithm: lz4 (fastest compression, good ratio)
- Size: 50% of detected physical RAM (auto)
- Priority: 100 (preferred over disk swap)
- Effect: 512MB machine gets ~750MB effective working memory

### Service set (only essentials active)

| Service | Terminal | GUI |
|---|---|---|
| dbus | Yes | Yes |
| NetworkManager | Yes | Yes |
| syslog (busybox) | Yes | Yes |
| lightdm | No | Yes |
| ufw | Yes | Yes |
| alsa | No | Yes |

Not installed: bluetooth, cups, avahi, ModemManager.

### Auto-optimization script (`nerf-optim`)
Runs at first boot, detects hardware, writes `/etc/nerf-os/hardware-profile`:

| Detects | Action |
|---|---|
| RAM amount | Sets zram size, browser cache limit |
| CPU cores | Sets parallelism config |
| HDD vs SSD | Sets I/O scheduler (mq-deadline / none) |
| GPU vendor | Enables/disables Firefox hardware acceleration |

Re-runnable anytime: `sudo nerf-optim`

### Kernel tweaks (`/etc/sysctl.d/99-nerfo.conf`)
```
vm.swappiness = 10
vm.vfs_cache_pressure = 50
kernel.nmi_watchdog = 0
```

### I/O Scheduler
- HDD: `mq-deadline`
- SSD: `none`

---

## Installer (`nerf-install`)

CLI-based, rsync-driven. No GUI framework dependency.

**Flow:**
1. Welcome screen
2. Disk selection (lsblk listing + user pick + confirmation warning)
3. Auto-partitioning:
   - `<4GB RAM`: swap partition (2GB) + root (remaining)
   - `>=4GB RAM`: root only (zram handles swap)
   - Boot mode auto-detected: BIOS → MBR, UEFI → GPT
4. Filesystem: ext4 (compatibility + stability on old HDD)
5. User setup: username, password, hostname (default: `nerfo`)
6. Default boot mode preference: GUI or Terminal
7. Install: rsync live → disk, GRUB install, fstab generation, `nerf-optim` run
8. Done: prompt to remove USB and reboot

**Key decisions:**
- rsync-based (copies live system as-is) — simple, no package re-download
- ext4 only — btrfs/xfs add complexity without benefit on old HDD hardware
- BIOS + UEFI support — covers full 2008–2015 hardware range

---

## Build Pipeline

```
nerf-os/
├── build/
│   ├── build.sh                         # ./build.sh [x86_64|i686]
│   ├── config/
│   │   ├── common/
│   │   │   ├── package-lists/
│   │   │   │   ├── base.list.chroot
│   │   │   │   ├── gui.list.chroot
│   │   │   │   └── terminal.list.chroot
│   │   │   ├── hooks/
│   │   │   │   ├── 01-runit-setup.hook.chroot
│   │   │   │   ├── 02-zram-setup.hook.chroot
│   │   │   │   ├── 03-services-trim.hook.chroot
│   │   │   │   └── 04-branding.hook.chroot
│   │   │   └── includes.chroot/
│   │   │       ├── etc/
│   │   │       └── usr/
│   │   ├── x86_64/
│   │   └── i686/
├── os-research/
└── docs/
```

**Build flow:**
1. `build.sh x86_64` invokes `live-build` with config tree
2. `debootstrap` pulls Debian 13 Trixie minimal
3. antiX runit packages installed via APT (antiX repo added temporarily, removed after)
4. Hooks run in order: runit setup → zram → service trimming → branding
5. Output: `nerf-os-1.0-x86_64.iso`

---

## Security (v1 scope — basic only)

- ufw firewall enabled with default deny-incoming policy
- Unnecessary services not installed (minimal attack surface by omission)
- No root login by default
- Full security hardening deferred to v2

---

## Out of Scope for v1

- Office suite
- Media player / codec pack
- Email client
- Encrypted install
- AppArmor profiles
- Automatic security updates
- Custom branding/theme (beyond basic naming)
- Update mechanism / package manager GUI
