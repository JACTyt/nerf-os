# nerf-os Base Distro Recommendations

**Research Date:** April 2026

---

## Final Recommendations

### Primary: antiX Linux (base/inspiration) + Openbox layer

**Why antiX:**
- Released antiX 26 (March 21, 2026) — actively maintained, most recent
- Debian 13/Trixie base → 38,000+ packages via APT
- runit default (fastest boot on HDD, <15s)
- **32-bit fully maintained** with kernel 5.10 LTS
- ~87MB RAM idle on 32-bit — exceptional
- MX-Snapshot + build-iso-mx for custom ISOs (best tooling among lightweight distros)
- Community is literally the same audience as nerf-os users (non-technical people on old PCs)
- Zero systemd

**Build path:**
1. Start with antiX 26 core edition (~660MB)
2. Replace IceWM/JWM with Openbox + tint2
3. Configure runit service set for minimal attack surface
4. Use `build-iso-mx` or MX-Snapshot to produce nerf-os ISOs
5. Add curated app set (Firefox-ESR or Midori, PCManFM, mousepad, etc.)
6. Configure zram for 512MB RAM targets
7. Add performance mode switch script

---

### Secondary: Void Linux i686 glibc

**Why Void as alternative:**
- Maximum independence — not a Debian downstream
- runit is the native default init
- i686 glibc officially maintained, rolling updates
- XBPS is reliable and fast
- ~100–150MB RAM idle (Openbox + tint2)

**When to choose Void over antiX:**
- You want full control over every package choice
- You don't want to inherit antiX's desktop decisions
- You prefer pure scripting over GUI remastering tools
- Smaller package count (~15k vs 38k) is acceptable

**Tradeoffs vs antiX:**
- More work to produce a desktop ISO (void-mklive vs build-iso-mx)
- No GUI remastering tool — pure scripting
- Smaller package ecosystem

---

### Future 64-bit variant: Artix Linux (runit)

Once 32-bit support is no longer required in a future nerf-os version:
- Artix with runit = Arch package richness + fastest init
- pacman + AUR = massive software availability
- Excellent archiso tooling
- No systemd

---

## Key Architecture Decisions

### 1. Use runit, not sysvinit

The boot speed difference on HDD is 3–5x:
- sysvinit: ~25–45s (sequential)
- runit: ~5–12s (supervised, parallel-capable)

sysvinit **cannot** achieve the <20s HDD boot goal. This is non-negotiable.

### 2. 32-bit window is closing — plan ahead

Distros that still maintain 32-bit (April 2026):
- antiX, Void Linux, Alpine, Gentoo, Slackware, Arch Linux 32

Distros that dropped it recently:
- Debian 13 (August 2025), Devuan 6 (November 2025), MX 25, NixOS (2023)

**Plan:** Support 32-bit through nerf-os v1.x (antiX base). Migrate to 64-bit-only in v2.x (Artix base) when 32-bit hardware becomes truly obsolete.

### 3. zram is mandatory for 512MB targets

Without RAM compression, 512MB with a browser is nearly unusable:
- Browser alone: 300–500MB active
- zram provides effective ~750MB working memory from 512MB physical RAM
- Must be configured at boot, before any user session starts

```bash
# Example zram config for 512MB machine
modprobe zram
echo lz4 > /sys/block/zram0/comp_algorithm
echo 512M > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 100 /dev/zram0
```

### 4. Avoid Alpine's musl for a desktop distro

musl libc creates binary compatibility issues:
- Tor Browser won't run
- Some Electron apps fail
- Proprietary tools (Zoom, Slack, etc.) are glibc-only
- Creates support nightmares for non-technical users

Alpine is excellent for servers/containers. Not for this desktop use case.

### 5. Don't use Gentoo — compilation time is catastrophic

A Firefox compile on 2010-era CPU + HDD takes **8–16+ hours**.
Gentoo requires cross-compilation infrastructure for a distributable binary OS.
Eliminated definitively.

### 6. Openbox + tint2 idle RAM of 87–150MB is confirmed feasible

Across all top candidates, the WM choice achieves the target.
The stack is:
- X11 (Xorg minimal): ~20–30MB
- Openbox: ~10–15MB
- tint2: ~5–10MB
- PCManFM (file manager, not running): 0MB idle
- Total with display manager: ~87–150MB depending on base

---

## What to Remove (Equally Important)

nerf-os philosophy: "what you remove, not what you add"

**Remove at base level:**
- bluetooth stack (not needed on most old HW, wasteful)
- cups (printing — optional, add if needed)
- avahi-daemon (mDNS — not needed for basic use)
- ModemManager (mobile broadband — rare on target HW)
- snapd / flatpak (heavy, adds overhead)
- Any sound server beyond ALSA/PipeWire-minimal

**Remove at UI level:**
- All desktop animations / compositing (picom/compton should be minimal or disabled)
- Desktop icons if not needed (PCManFM can manage desktop)
- Multiple virtual desktops (confusing for non-technical users)
- Complex menu systems

**Replace heavy with light:**

| Heavy | Light replacement |
|---|---|
| Firefox (full) | Firefox-ESR (tuned) or Midori |
| GNOME Terminal | lxterminal or xterm |
| Nautilus | PCManFM |
| gedit | mousepad or nano |
| NetworkManager applet | nm-applet (already minimal) |
| PulseAudio | ALSA or PipeWire-minimal |
