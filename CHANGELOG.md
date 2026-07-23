# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-07-23

### Added

- Real in-app suction demo for the project README.
- One-command local source installer for `~/Applications`.
- Tauri 2 Windows client with the shared WebGL renderer, bilingual interface,
  drag/drop suction and validated system Recycle Bin operations.
- Reproducible Windows x64 NSIS/MSI and ARM64 NSIS builds in GitHub Actions.
- Automatic tagged Windows releases and weekly npm, Cargo and Actions updates.
- Public roadmap covering trusted macOS and Windows distribution.

### Changed

- Reworked English and Simplified Chinese onboarding around installation,
  first launch, platform differences, safe usage and current preview limitations.
- Added a dark backing to the drag-release hint so it remains legible on light
  desktop backgrounds.

## [0.1.0] - 2026-07-23

### Added

- Native transparent macOS black-hole trash target.
- WebGL2 geodesic renderer adapted from `s0xDk/ghostty-blackhole`.
- Hover attraction, suction preview and multi-file spiral animations.
- Finder file/folder recycle with one-batch undo.
- Menu-bar controls, position persistence, always-on-top and reduced motion.
- Native drag-operation negotiation plus system drag-pasteboard fallback.
- Local release build script and recycle/undo self-test.

[Unreleased]: https://github.com/ljunnan24-hash/black-hole-bin/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ljunnan24-hash/black-hole-bin/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ljunnan24-hash/black-hole-bin/releases/tag/v0.1.0
