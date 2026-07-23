# Roadmap

This document describes direction, not a release promise. Priorities may change
after testing and community feedback.

## Now: cross-platform preview

- Stabilize Finder and File Explorer drag-and-drop across local, cloud and
  network-backed items.
- Improve multi-display placement, accessibility and reduced-motion behavior
  on both native shells.
- Add automated coverage around recycle, undo and duplicate-drop prevention.
- Publish reproducible Windows x64/ARM64 installers from tagged commits.

## Next: trusted distribution and parity

- Build a universal Apple silicon and Intel app.
- Sign with Developer ID, notarize with Apple and staple the ticket.
- Publish a versioned `.dmg` or `.zip` with SHA-256 checksums.
- Sign Windows installers to remove the unknown-publisher/SmartScreen warning.
- Add one-click Windows undo without adding a permanent-delete path.
- Test x64 and ARM64 installers on clean Windows 10 and Windows 11 machines.
- Add an in-app update strategy only after the release channel is trusted.

The Windows shell is implemented with Tauri 2 and WebView2, while macOS remains
native AppKit. Both consume the same checked-in HTML/GLSL visual core. Unsigned
Windows preview artifacts are published transparently; users under a policy
that blocks unsigned software should build from source or wait for signing,
not disable system-wide protection.

## Later

- Optional startup-at-login with explicit opt-in and an obvious off switch.
- Keyboard-accessible file picking as an alternative to drag/drop.
- Localization beyond English and Simplified Chinese.
- Better multi-file progress and recoverable partial-failure reporting.

## Non-goals

- Permanent deletion
- Cloud storage, accounts, analytics or remote rendering
- A privileged helper or Full Disk Access requirement

Ideas and implementation proposals are welcome in
[GitHub Discussions or Issues](https://github.com/ljunnan24-hash/black-hole-bin/issues).
