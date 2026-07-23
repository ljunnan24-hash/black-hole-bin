# 黑洞垃圾箱

[![CI](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml/badge.svg)](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml)
[![Windows](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/windows.yml/badge.svg)](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/windows.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/ljunnan24-hash/black-hole-bin)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](Package.swift)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D4?logo=windows11&logoColor=white)](windows/README.md)
[![MIT](https://img.shields.io/badge/License-MIT-2ea44f.svg)](LICENSE)

[English](README.md)

把 Finder 或文件资源管理器中的文件、文件夹拖到黑洞上，松手后，它会沿螺旋轨迹
被吸入事件视界，随后安全地进入 macOS 废纸篓或 Windows 回收站。

<p align="center">
  <img src="docs/demo.gif" width="420" alt="黑洞垃圾箱待机、文件悬停和真实回收动画">
</p>

动图展示真实的三个状态：待机 → 文件悬停 → 松手吸入并确认移入废纸篓。录制使用
一份专门创建的一次性文本文件。

> **当前状态：0.2 跨平台预览版。** 支持 macOS 13 或更高版本，以及 Windows 10
> 1803 或更高版本、Windows 11。Windows 提供 x64 与 ARM64 安装包，构建过程完全
> 公开；目前还没有商业代码签名证书，Windows 可能显示 SmartScreen 信誉提示。

## 安装

### Windows 10/11

进入本仓库的
[Releases 页面](https://github.com/ljunnan24-hash/black-hole-bin/releases)，
按设备下载：

- 常见 Intel/AMD 电脑：`Black Hole Bin_*_x64-setup.exe`
- Windows on ARM 设备：`Black Hole Bin_*_arm64-setup.exe`
- x64 还提供 `.msi`，供企业管理或备用安装

安装器按当前用户安装，不需要管理员权限。受支持的 Windows 已自带 WebView2
运行时。由于当前预览版尚未代码签名，请只从本仓库下载，不要使用第三方镜像。如果
单位安全策略禁止未签名软件，请选择[从源码构建](windows/README.md)，或等待签名
版本，不要为了运行本项目关闭系统级安全保护。

卸载时进入“设置 → 应用 → 已安装的应用 → Black Hole Bin”。卸载不会清空回收站，
也不会影响其中已有文件。

### macOS 从源码一键安装

需要 macOS 13 或更高版本，以及 Swift 6（Xcode 16 或兼容的 Command Line
Tools）。如果终端里没有 `swift`，先运行 `xcode-select --install`，按系统提示
完成安装。

```sh
git clone https://github.com/ljunnan24-hash/black-hole-bin.git
cd black-hole-bin
./Scripts/install-local.sh
```

脚本会依次执行发布构建、自测和签名验证，然后把应用安装到
`~/Applications/黑洞垃圾箱.app` 并启动。项目没有第三方软件包依赖，也不会请求
管理员权限。更新时先退出正在运行的应用，再执行：

```sh
git pull --ff-only
./Scripts/install-local.sh
```

旧版本会被移动到废纸篓，而不是直接删除。如果只想开发或临时运行：

```sh
./Scripts/check.sh
./Scripts/build-app.sh
open "dist/黑洞垃圾箱.app"
```

卸载时，先退出应用，运行 `open "$HOME/Applications"`，然后在 Finder 中把
`黑洞垃圾箱.app` 移到废纸篓。整个过程可见、可恢复。

> 从源码生成的是本机 ad-hoc 签名版本。请不要从第三方站点下载所谓的安装包，也
> 不要用关闭 Gatekeeper、删除隔离属性等方式绕过 macOS 安全检查。正式签名下载包
> 会在本仓库的 [Releases](https://github.com/ljunnan24-hash/black-hole-bin/releases)
> 页面发布。

## 怎么用

1. 启动后不会出现普通窗口，而是显示一个悬浮黑洞。
2. 从 **Finder** 或 **文件资源管理器** 拖动文件、文件夹到黑洞上。进入有效投放
   区域后，引力环和提示会出现。
3. 在黑洞上松手。文件图标会被吸入，原文件随后进入系统废纸篓。
4. macOS 可从菜单栏或黑洞右键菜单选择“撤销上次投放”；Windows 请打开回收站，
   选择“还原”。
5. 单击拖动黑洞本体可以改变位置；应用会记住它。

双击黑洞只播放无害的吸入预览，不会移动任何文件。普通鼠标悬停只显示较轻的引力
响应；完整吸入动画需要拖入文件后松手，或双击预览。

## 安全边界

- macOS 调用 `NSWorkspace.recycle`；Windows 通过 MIT 许可的 Rust `trash` 库
  调用系统回收站。两个客户端都没有永久删除代码路径。
- macOS 在内存中保留最近一次成功投放，用于单批撤销；Windows 预览版使用系统
  回收站的“还原”功能，尚无应用内一键撤销。
- Windows 会在开始回收前校验整批路径，拒绝根目录、相对路径和不存在的项目，
  去除重复/嵌套路径，并将单次投放限制为 128 个路径。
- 不请求“完全磁盘访问权限”，不安装特权辅助进程。
- 没有网络请求、账户、统计分析或云端渲染。
- 渲染器只加载应用内置的 HTML 和 GLSL。

文件管理工具仍需谨慎。首次使用时，请先用一个无用的本地测试文件验证投放与撤销。
最终清空废纸篓仍由 Finder 管理。

## 功能

- 原生 AppKit macOS 客户端与轻量 Tauri/WebView2 Windows 客户端
- WebGL2 测地线追踪、吸积盘与引力透镜黑洞
- 悬停、引力环、多文件错峰螺旋吸入和成功/失败反馈
- 两个平台均支持文件、文件夹投放；macOS 支持上一次投放撤销
- 跨桌面显示、始终置顶、位置记忆和“减少动态效果”
- 本地渲染，无账户、统计分析或云端依赖

## Windows 版本

Windows 客户端位于 [`windows/`](windows/README.md)。它使用 Tauri 2 作为轻量
原生外壳，复用系统 WebView2 和 macOS 同一份 HTML/GLSL 黑洞渲染器，并由 Rust
后端执行经过校验的回收站操作。每次推送到 `main`，GitHub Actions 都会构建 x64、
ARM64 NSIS 安装器和 x64 MSI；打版本标签后会自动发布到 GitHub Releases。

当前差距也会明确公开：安装包尚未代码签名、Windows 端暂时没有应用内一键撤销、
开机启动仍需要完整设计和明确的用户授权。后续工作见 [ROADMAP.md](ROADMAP.md)。

## 项目结构

| 组件 | 职责 |
| --- | --- |
| `Sources/BlackHoleBin` | 原生 AppKit 外壳、macOS 拖放与撤销 |
| `windows/src` | Windows 拖放状态、中文界面和文件吸入动画 |
| `windows/src-tauri` | Windows 路径校验、回收站命令和原生窗口 |
| `blackhole.html` / `blackhole.glsl` | 两个平台共享的 WebGL2 渲染器 |
| Windows 工作流 | x64/ARM64 自动检查、安装包与标签发布 |

## 视觉来源与许可

黑洞渲染器修改自 MIT 许可的
[`s0xDk/ghostty-blackhole`](https://github.com/s0xDk/ghostty-blackhole)，
对照提交为
[`b49fa0a`](https://github.com/s0xDk/ghostty-blackhole/commit/b49fa0ab2eaf0644a690f4cb386d70c21eb9f969)。
本项目增加了透明桌面模式、交互 uniform、拖放和成功/失败反馈；它是独立衍生项目，
不是 Ghostty Blackhole 官方组成部分。

项目采用 [MIT License](LICENSE)。完整第三方归属见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 和 [Licenses](Licenses/)。

## 参与贡献

请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [ROADMAP.md](ROADMAP.md)。
报告拖放问题时，请附上系统版本、设备与 CPU 架构、文件来源应用，以及悬停和松手
两个阶段分别是否出现。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。
