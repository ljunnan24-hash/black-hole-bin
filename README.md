# Black Hole Bin

[![CI](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml/badge.svg)](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml)
[![Windows](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/windows.yml/badge.svg)](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/windows.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/ljunnan24-hash/black-hole-bin)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](Package.swift)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows11&logoColor=white)](windows/README.md)
[![MIT](https://img.shields.io/badge/License-MIT-2ea44f.svg)](LICENSE)

## 中文简介

黑洞垃圾箱是一款支持 macOS 和 Windows 的开源桌面工具。把文件或文件夹拖到黑洞
上，松手后会播放螺旋吸入动画，并将文件安全地移入系统废纸篓或回收站，不会直接
永久删除文件。

- **macOS：** macOS 13 或更高版本，原生 AppKit 客户端
- **Windows：** Windows 10 1803 或更高版本、Windows 11，提供 x64 和 ARM64 客户端
- **当前状态：** `0.2` 跨平台预览版；Windows 安装包由 GitHub Actions 自动构建，
  暂未购买代码签名证书
- **实机测试：** 正在征集 Windows x64、ARM64 实机结果，测试清单见
  [`docs/WINDOWS_TESTING.md`](docs/WINDOWS_TESTING.md)

[查看完整简体中文安装和使用说明 →](README.zh-CN.md)

Drag a file or folder onto a gravitationally lensed black hole. Release it to
spiral the item into the event horizon and safely move it to the macOS Trash or
Windows Recycle Bin.

<p align="center">
  <img src="docs/demo.gif" width="420" alt="Black Hole Bin idle, file-hover and real recycle animation">
</p>

The recording shows the real three-state flow: idle → file hover → release,
suction and confirmed move to Trash. It uses one disposable text file.

> **Current status: 0.2 cross-platform preview.** macOS 13+ and Windows
> 10 1803+/11 are supported. Windows x64 and ARM64 installers are built in a
> public GitHub Actions workflow. They are reproducible but currently unsigned,
> so Windows may show a SmartScreen reputation warning.

## Install

### Windows 10/11

Open the official
[Releases page](https://github.com/ljunnan24-hash/black-hole-bin/releases) and
download the installer for your device:

- Most Intel/AMD PCs: `Black.Hole.Bin_*_x64-setup.exe`
- Windows on ARM: `Black.Hole.Bin_*_arm64-setup.exe`
- An x64 `.msi` is also published for managed or alternative installation

Run the installer as the current user; administrator access is not required.
The app uses the WebView2 runtime already included with supported Windows
versions. Because this preview is not yet code-signed, do not download it from
mirrors. If your security policy blocks unsigned software, build from the
auditable source or wait for a signed release instead of weakening system-wide
security settings.

To uninstall, open **Settings → Apps → Installed apps → Black Hole Bin**. Files
already in the Recycle Bin are not affected. For a source build, see
[windows/README.md](windows/README.md).

### macOS one-command source install

You need macOS 13 or newer and Swift 6 from Xcode 16 or compatible Command Line
Tools. If `swift` is not available in Terminal, run `xcode-select --install`
first and follow the macOS prompt.

```sh
git clone https://github.com/ljunnan24-hash/black-hole-bin.git
cd black-hole-bin
./Scripts/install-local.sh
```

The script runs the release build, self-test and signature verification, then
installs and opens `~/Applications/黑洞垃圾箱.app`. It needs no third-party
packages or administrator access. To update, quit the running app and run:

```sh
git pull --ff-only
./Scripts/install-local.sh
```

The previous local install is moved to Trash instead of being permanently
deleted. For development or a temporary run:

```sh
./Scripts/check.sh
./Scripts/build-app.sh
open "dist/黑洞垃圾箱.app"
```

To uninstall, quit the app, run `open "$HOME/Applications"` and move
`黑洞垃圾箱.app` to Trash in Finder. This keeps removal visible and recoverable.

> Source builds are ad-hoc signed for the current Mac. Do not download binaries
> from third-party sites or disable Gatekeeper/remove quarantine attributes to
> make one run. The official signed build will appear on this repository's
> [Releases](https://github.com/ljunnan24-hash/black-hole-bin/releases) page.

## Use

1. Launching the app shows a floating black hole instead of a conventional
   application window.
2. Drag a file or folder from **Finder** or **File Explorer** onto the black
   hole. Gravity rings and a release hint appear over a valid drop area.
3. Release over the black hole. The icon is pulled in, then the original item
   moves to the system Trash or Recycle Bin.
4. On macOS, choose **Undo Last Drop** from the menu-bar item or right-click
   menu. On Windows, open the Recycle Bin and choose **Restore**.
5. Drag the black hole itself to reposition it; the app remembers the location.

Double-clicking the black hole plays the harmless preview shown above and moves
no files. Pointer hover is intentionally subtle; the complete suction effect
starts after a valid file drop or double-click preview.

## Safety model

- macOS drops call `NSWorkspace.recycle`; Windows drops use the system Recycle
  Bin through the MIT-licensed `trash` Rust crate. Neither client has a
  permanent-delete path.
- macOS retains the latest successful batch in memory for one-click undo.
  Windows uses the Recycle Bin's standard **Restore** action in this preview.
- Windows validates the entire batch first, rejects roots/relative/missing
  paths, removes nested duplicates and caps a drop at 128 paths.
- The app does not request Full Disk Access or install a privileged helper.
- There are no network requests, accounts, analytics or cloud rendering.
- The renderer loads only bundled local HTML and GLSL.

File tools still deserve care. Start with one disposable local file and verify
both recycle and undo before using the app with important data. Finder remains
responsible for final Trash deletion.

## Highlights

- Native AppKit macOS client and compact Tauri/WebView2 Windows client
- WebGL2 geodesic ray tracing, accretion disk and gravitational lensing
- Hover, gravity-ring, staggered multi-file suction and status animations
- File/folder recycle on both platforms; one-batch undo on macOS
- All-Spaces visibility, always-on-top, position memory and reduced motion
- Local-only renderer with no accounts, analytics or cloud dependency

## Windows

The Windows preview lives in [`windows/`](windows/README.md). It uses Tauri 2
for a small native shell, the system WebView2 runtime, the same HTML/GLSL
renderer as macOS, and a Rust backend for validated Recycle Bin operations.
GitHub Actions builds an NSIS installer for x64 and ARM64 plus an x64 MSI on
every `main` commit. Version tags publish those installers to GitHub Releases.

Current Windows gaps are documented rather than hidden: installers are not yet
code-signed, in-app undo is not implemented, and startup-at-login needs design
and user consent. Real-device testers can follow the auditable
[Windows smoke-test checklist](docs/WINDOWS_TESTING.md). See
[ROADMAP.md](ROADMAP.md) for the remaining work.

## Architecture

| Component | Responsibility |
| --- | --- |
| `Sources/BlackHoleBin` | Native AppKit shell, drag/drop and macOS undo |
| `windows/src` | Windows drag state, overlays, localization and icon animation |
| `windows/src-tauri` | Validated Windows Recycle Bin commands and native window |
| `blackhole.html` / `blackhole.glsl` | Shared WebGL2 renderer and interaction contract |
| Windows workflow | Reproducible x64/ARM64 checks, installers and tagged releases |

The app combines AppKit drag callbacks with a system drag-pasteboard fallback.
This supports Finder sources that expose different drag-operation masks while
preventing duplicate recycle operations.

## Upstream and license

The renderer is adapted from the MIT-licensed
[`s0xDk/ghostty-blackhole`](https://github.com/s0xDk/ghostty-blackhole) shader,
reviewed at commit
[`b49fa0a`](https://github.com/s0xDk/ghostty-blackhole/commit/b49fa0ab2eaf0644a690f4cb386d70c21eb9f969).
This project adds transparent desktop output, interaction uniforms, drag/drop
and success/error feedback. It is an independent derivative project, not an
official part of Ghostty Blackhole.

Black Hole Bin is released under the [MIT License](LICENSE). See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [Licenses](Licenses/) for
complete upstream attribution.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [SUPPORT.md](SUPPORT.md) and
[ROADMAP.md](ROADMAP.md) first.
Drag/drop reports should include the OS version, device/architecture, source
application and whether both hover and release phases appeared. Report security
issues privately as described in [SECURITY.md](SECURITY.md).
