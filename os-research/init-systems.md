# Init System Comparison for nerf-os

**Key question:** Which init system gives the fastest HDD boot time for old hardware?

---

## Comparison Table

| Init System | HDD Boot Speed | Parallelization | Footprint | Used By |
|---|---|---|---|---|
| **runit** | Fastest (~5–12s) | Yes (service supervision) | Very small | Void, antiX, Artix |
| **dinit** | Fast (~8–15s) | Yes | Small | antiX, Artix |
| **OpenRC** | Fast (~8–18s) | Yes (parallel) | Small | Gentoo, Alpine, Devuan (opt) |
| **s6/s6-rc** | Fast | Yes | Small, complex | antiX, Artix |
| **systemd** | Medium (~15–35s) | Yes | Large | Debian, Arch, NixOS |
| **sysvinit** | Slow (~25–45s) | No (sequential) | Minimal | Slackware, Devuan (default) |

---

## Recommendation for nerf-os: runit

runit is the clear choice for nerf-os:

- **Fastest on HDD** — service supervisor model avoids systemd's journal write overhead
- **Smallest footprint** — aligns with minimal RAM usage goal
- **Actively maintained** in both top candidates (antiX default, Void default)
- Users report runit making boot "as fast as if I had an SSD" on spinning rust

### Why not systemd?
systemd's journal (journald) performs frequent writes on HDD, significantly slowing boot. On spinning rust, seek time amplifies this effect. 15–35s vs 5–12s for runit.

### Why not sysvinit?
Sequential service startup cannot achieve <20s on HDD. Services start one after another — no parallelism. Hard dealbreaker for the boot time goal.

### Why not OpenRC?
OpenRC is a valid second choice (used by Alpine). Parallel startup achieves 8–18s on HDD. However, runit is consistently faster and simpler. If antiX or Void is the base, runit is already the default.

---

## runit Service Structure

runit uses a simple directory-based service supervision model:

```
/etc/runit/
  runsvdir/
    default/       <- symlinks to active services
      NetworkManager -> /etc/sv/NetworkManager
      dbus -> /etc/sv/dbus
      ...

/etc/sv/
  NetworkManager/
    run            <- shell script to start the service
    finish         <- optional cleanup on stop
    log/
      run          <- log service (optional)
```

Each service is a directory with a `run` script. No XML, no unit files, no complex dependencies — just shell scripts.

### Minimal service set for nerf-os (512MB target)

Keep only what is essential:

| Service | Purpose | Keep? |
|---|---|---|
| dbus | IPC for desktop apps | Yes |
| NetworkManager | WiFi/Ethernet | Yes |
| lightdm | Display manager | Optional (or startx) |
| syslog | System logging | Yes (lightweight: busybox syslog) |
| cron | Scheduled tasks | Optional |
| bluetooth | Bluetooth | No (waste on old HW) |
| cups | Printing | No (unless needed) |
| avahi | mDNS/Bonjour | No |
| ModemManager | Mobile broadband | No |

Disabling unnecessary services is the single highest-impact optimization after init system choice.

---

## Sources

- [OpenRC vs runit comparison 2025 - Slant](https://www.slant.co/versus/12958/12960/~openrc_vs_runit)
- [Comparison of init systems - Gentoo Wiki](https://wiki.gentoo.org/wiki/Comparison_of_init_systems)
- [antiX 26: Five Init Systems, Zero Systemd - LinuxIAC](https://linuxiac.com/antix-26-released-as-systemd-free-debian-13-distro-with-five-init-systems/)
