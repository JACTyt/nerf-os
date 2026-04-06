# Base Distribution Comparison for nerf-os

**Research Date:** April 2026
**Target:** 512MB–1GB RAM, HDD, 32-bit required, boot < 20s, Openbox + tint2, non-technical users

---

## Critical 32-Bit Status Overview (2026)

| Distro | 32-bit i686 Status |
|---|---|
| antiX | YES — active, antiX 26 released March 2026 |
| Void Linux | YES — i686 glibc maintained |
| Alpine Linux | YES — x86 (i686) fully maintained |
| Gentoo | YES — x86 stage3 tarballs, i486/i686 |
| Slackware | YES — 15.0 stable |
| Tiny Core Linux | YES — primarily 32-bit focused |
| Puppy Linux (Woof-CE) | YES — x86 builds available |
| Arch Linux 32 | YES — community fork, active |
| Debian 12 Bookworm | YES — but LAST version; Debian 13 dropped i386 entirely |
| Devuan 6 Excalibur | NO — dropped 32-bit alongside Debian 13 |
| MX Linux 25+ | NO — dropped 32-bit; 23.x supported until 2028 |
| NixOS | NO — officially phased out 2023–2024 |
| Artix Linux | NO — x86_64 only |
| Buildroot | YES — embedded focus, not desktop |

---

## Per-Distro Analysis

---

### 1. Debian 12 "Bookworm" Minimal

- **Init:** systemd (default). Switching possible but fights the grain.
- **Boot on HDD:** 25–45s. Journal writes to HDD are slow.
- **32-bit:** Available in Debian 12 only. **Debian 13 dropped i386 entirely.** Bookworm LTS until June 2028.
- **Packages:** 35,000+ stable / 94,000 across branches. Best ecosystem by far.
- **ISO Tooling:** `live-build` — gold standard. Mature, well-documented. **Excellent.**
- **RAM idle (Openbox+tint2):** ~120–180MB
- **Non-technical UX:** Low out-of-box, excellent once desktop layered on.
- **Release model:** Stable, every ~2 years.
- **Verdict:** Good tooling and ecosystem, but 32-bit is a dead-end path and systemd hurts boot on HDD.

---

### 2. Arch Linux / Arch Linux 32

- **Init:** systemd. Arch Linux 32 (community fork) also uses systemd.
- **Boot on HDD:** 15–30s (fewer default services than Debian).
- **32-bit:** Official Arch dropped i686 in 2017. **Arch Linux 32** community fork is active but small team, package updates lag mainline.
- **Packages:** pacman: ~15,000 official + AUR (effectively unlimited).
- **ISO Tooling:** `archiso` excellent for 64-bit. 32-bit via Arch Linux 32 is community-maintained and sparse.
- **RAM idle (Openbox+tint2):** ~110–160MB
- **Non-technical UX:** Low. Explicit Arch philosophy is against hand-holding.
- **Release model:** Pure rolling release.
- **Verdict:** Excellent 64-bit base. 32-bit is community-dependent and risky long-term. systemd still a boot-speed concern on HDD.

---

### 3. Void Linux

- **Init:** runit — fastest init system for HDD scenarios. Sub-10s boots on spinning rust reported.
- **Boot on HDD:** Sub-10–15s. Consistently fastest among all candidates.
- **32-bit:** i686 glibc officially maintained. Active rolling updates.
- **Packages:** XBPS: ~15,000. No AUR equivalent. Smaller than Debian/Arch but covers desktop needs.
- **ISO Tooling:** `void-mklive` — functional, less mature than live-build. **Adequate.**
- **RAM idle (Openbox+tint2):** ~100–150MB
- **Non-technical UX:** Low out-of-box. End-user software adequate for basic use.
- **Release model:** Rolling, conservative. One of the most stable rolling releases.
- **Verdict:** Top tier. runit gives best boot speed. Active 32-bit. Stable rolling. Main weakness: smaller package count and less mature ISO tooling.

---

### 4. Devuan GNU+Linux

- **Init:** sysvinit (default), OpenRC, runit — user's choice. Explicitly systemd-free.
- **Boot on HDD:** sysvinit ~25–40s (sequential). OpenRC ~10–18s. runit: fast.
- **32-bit:** **DROPPED in Devuan 6 (November 2025).** Only Devuan 5 (Debian 12 base) has 32-bit, LTS until 2028.
- **Packages:** APT/dpkg — full Debian ecosystem.
- **ISO Tooling:** Debian live-build infrastructure. **Good.**
- **RAM idle (Openbox+tint2):** ~60–150MB
- **Non-technical UX:** Same as Debian — requires layering.
- **Release model:** Stable, tracking Debian.
- **Verdict:** 32-bit is gone in current release — outright disqualifier unless frozen on Devuan 5. Excellent for 64-bit-only.

---

### 5. Alpine Linux

- **Init:** OpenRC. Parallel service startup.
- **Boot on HDD:** 8–15s with desktop (sub-5s in containers).
- **32-bit:** x86 (i686) fully maintained in Alpine 3.23 (January 2026).
- **Packages:** apk: ~28,000 stable / ~35,000 Edge.
- **ISO Tooling:** aports/abuild designed for packages, not custom desktop ISOs. **Poor for desktop ISO building.**
- **RAM idle (Openbox+tint2):** ~80–130MB. Most RAM-efficient option.
- **Non-technical UX:** Very low. musl/BusyBox stack creates real binary compatibility issues.
- **Release model:** Stable every 6 months + Edge (rolling).
- **Verdict:** musl libc compatibility wall is a serious practical problem for desktop apps non-technical users want. Better as server/embedded base.

---

### 6. Gentoo Linux

- **Init:** OpenRC (default) or systemd.
- **Boot on HDD:** 10–20s achievable with OpenRC.
- **32-bit:** Full i486/i686 support. Official Stage 3 tarballs active.
- **Packages:** Portage: ~31,000 ebuilds, source-compiled.
- **ISO Tooling:** No official derivative ISO framework. Catalyst is for official releases only. **Poor for this use case.**
- **RAM idle (Openbox+tint2):** ~60–130MB
- **Non-technical UX:** Essentially zero. Most expert-requiring distro that exists.
- **Verdict:** ELIMINATED. Compile time on a 2010-era HDD machine is catastrophic (8–16h for Firefox). Not viable for a distributable binary OS.

---

### 7. Slackware Linux

- **Init:** SysVinit only. Sequential, no parallelization.
- **Boot on HDD:** 30–60s. Worst init system for boot-time goal.
- **32-bit:** Yes — 15.0 supports i586/i686. Actively maintained.
- **Packages:** pkgtool: ~2,000. **No dependency resolution** by design.
- **ISO Tooling:** None official. No derivative tooling.
- **RAM idle (Openbox+tint2):** ~100–160MB
- **Non-technical UX:** Very low.
- **Verdict:** ELIMINATED. Sequential boot makes <20s goal nearly impossible. No dependency resolution. 2,000 packages is far too small.

---

### 8. antiX Linux ⭐ TOP RECOMMENDATION

- **Init:** 5 init options (runit default, sysvinit, dinit, s6-rc, s6-66). **Zero systemd.** runit is default in antiX 26.
- **Boot on HDD:** Users report <10–15s. Architected for fast booting on legacy hardware.
- **32-bit:** **Fully maintained.** antiX 26 (released March 21, 2026) ships both 64-bit and 32-bit editions. 32-bit uses kernel 5.10.240 LTS.
- **Packages:** APT (Debian 13/Trixie base). Full Debian ecosystem: 35,000+ packages.
- **ISO Tooling:** `build-iso-mx` + MX-Snapshot. GUI remastering tool. **Good.**
- **RAM idle (32-bit sysvinit):** ~87MB. Exceptional.
- **Non-technical UX:** Medium — ships IceWM/JWM/Fluxbox. Large community of non-technical users on old hardware. This IS the target audience.
- **Release model:** Stable snapshots based on Debian stable.
- **Verdict:** **Strongest base for nerf-os.** Literally doing what nerf-os wants — Debian ecosystem, no systemd, 32-bit, fast boot, old PC focus. Replace IceWM with Openbox + tint2 and you're there.

---

### 9. Buildroot

- **Init:** Configurable (BusyBox init, sysvinit, OpenRC, systemd).
- **Boot on HDD:** 2–5s. Fastest possible.
- **32-bit:** Full i386/i486/i686 support.
- **Packages:** ~2,500. No runtime package manager — everything baked at build time.
- **ISO Tooling:** Buildroot IS the build tooling (menuconfig-based).
- **RAM idle:** 16–32MB possible. Designed for embedded.
- **Non-technical UX:** Runtime can be simple. Build system is extremely complex.
- **Verdict:** ELIMINATED. No runtime package manager means users can't install software. Designed for embedded/IoT, not general-purpose desktops.

---

### 10. Linux From Scratch (LFS)

- **Verdict:** ELIMINATED. Educational project, not a distribution. No package manager, no tooling, no updates mechanism. Use to learn, not to ship.

---

### 11. Tiny Core Linux

- **Init:** Custom busybox-based init.
- **Boot on HDD:** 5–8s.
- **32-bit:** Primarily 32-bit focused. i686 supported.
- **Packages:** tce: ~15,000 extensions. All loaded into RAM at boot.
- **RAM idle:** ~52MB with desktop — most RAM-efficient.
- **Non-technical UX:** Low. RAM-loading model is counterintuitive. Persistent installs require configuration.
- **Verdict:** Too exotic. RAM-loading architecture is wrong for a general-purpose OS targeting non-technical users.

---

### 12. Puppy Linux / Woof-CE

- **Init:** SysVinit + custom scripts.
- **Boot on HDD:** Initial load 15–30s, then OS runs from RAM.
- **32-bit:** Woof-CE supports x86 i486/i686.
- **Packages:** Depends on compat distro (Slackware/Debian/Ubuntu packages).
- **RAM usage:** ~300MB (loads entire OS into RAM) — higher than traditional distros!
- **Non-technical UX:** Designed for non-technical users. "Save file" model.
- **Verdict:** RAM model is wrong for 512MB targets. Loads entire OS into RAM, leaving little headroom for apps.

---

### 13. NixOS

- **Verdict:** ELIMINATED. 32-bit officially dropped 2023–2024. systemd-only. High complexity.

---

### 14. MX Linux (honorable mention)

- **Dropped 32-bit in MX 25.** MX 23.x has LTS until 2028.
- Best-in-class ISO remastering tooling (MX-Snapshot).
- Strong Xfce default. Not Openbox.
- **Use MX-Snapshot tooling as reference, not as base going forward.**

---

### 15. BunsenLabs Linux (honorable mention)

- Debian stable base + **Openbox specifically** — exactly the WM target.
- 64-bit only. Small but dedicated community.
- Strong choice for a **64-bit-only nerf-os variant**.

---

### 16. Artix Linux (honorable mention)

- Arch without systemd. Multiple init choices (runit, OpenRC, s6, dinit).
- 64-bit only.
- **Best choice if 32-bit requirement is dropped in a future version.**

---

## RAM at Idle Comparison (Openbox + tint2 + X11)

| Distro/Config | RAM at Idle |
|---|---|
| Tiny Core + FLWM | ~52MB |
| antiX 32-bit (sysvinit) | ~87MB |
| Alpine + Openbox | ~90–130MB |
| Void Linux + runit + Openbox | ~100–150MB |
| Debian minimal + Openbox | ~120–180MB |
| Puppy (RAM-loaded) | ~300–600MB |

---

## Package Ecosystem Size (Repology, April 2026)

| Distro | Packages |
|---|---|
| Debian unstable | ~42,000 |
| Debian 13 stable | ~38,000 |
| Gentoo | ~31,000 |
| Alpine Edge | ~35,000 |
| Alpine 3.23 | ~28,000 |
| Void Linux x86_64 | ~15,000 |
| Tiny Core Extensions | ~15,000 |
| Slackware 15.0 | ~2,000 |

---

## Sources

- [Debian 13 "Trixie" Drops i386 Support - The Register](https://www.theregister.com/2025/08/12/debian_13_trixie_released/)
- [antiX 26 "Bonsai" Release - The Register](https://www.theregister.com/2026/03/24/antix_26_bonsai_trixie/)
- [antiX 26 Released - antiX Linux Official](https://antixlinux.com/antix-26-released/)
- [antiX 26: Five Init Systems, Zero Systemd - LinuxIAC](https://linuxiac.com/antix-26-released-as-systemd-free-debian-13-distro-with-five-init-systems/)
- [Void Linux Official](https://voidlinux.org/)
- [Devuan 6 drops 32-bit - heise online](https://www.heise.de/en/news/Devuan-GNU-Linux-Excalibur-Debian-13-Trixie-without-systemd-11050767.html)
- [Top 15 Linux Distros with 32-bit support - It's FOSS](https://itsfoss.com/32-bit-linux-distributions/)
- [Repology Repository Package Counts](https://repology.org/repositories/packages)
