# 黑洞垃圾箱

[![CI](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml/badge.svg)](https://github.com/ljunnan24-hash/black-hole-bin/actions/workflows/ci.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/ljunnan24-hash/black-hole-bin)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](Package.swift)
[![MIT](https://img.shields.io/badge/License-MIT-2ea44f.svg)](LICENSE)

[English](README.md)

把 Finder 中的文件或文件夹拖到黑洞上，松手后，它会沿螺旋轨迹被吸入事件视界，
随后安全地进入 macOS 废纸篓。

<p align="center">
  <img src="docs/demo.gif" width="420" alt="黑洞垃圾箱真实吸入动画">
</p>

> **当前状态：0.1 预览版，仅支持 macOS。** 现在可以从源码安装。面向普通用户的
> 签名、公证下载包尚未发布；在 Apple Developer ID 签名和公证完成前，本项目不会
> 提供来路不明的预编译程序。

## 安装

### 从源码一键安装

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

1. 启动后不会出现普通窗口；黑洞默认悬浮在主屏幕右下角，菜单栏也会出现控制图标。
2. 从 **Finder** 拖动文件或文件夹到黑洞上。进入有效投放区域后，引力环和提示会
   出现。
3. 在黑洞上松手。文件图标会被吸入，原文件随后进入系统废纸篓。
4. 如果需要恢复，立即从菜单栏或黑洞右键菜单选择“撤销上次投放”。
5. 单击拖动黑洞本体可以改变位置；应用会记住它。

双击黑洞只播放无害的吸入预览，不会移动任何文件。普通鼠标悬停只显示较轻的引力
响应；完整吸入动画需要拖入文件后松手，或双击预览。

## 安全边界

- 只调用 `NSWorkspace.recycle` 移入系统废纸篓，没有永久删除代码路径。
- 仅在内存中保留最近一次成功投放，用于单批撤销；退出应用后撤销记录会消失。
- 不请求“完全磁盘访问权限”，不安装特权辅助进程。
- 没有网络请求、账户、统计分析或云端渲染。
- 渲染器只加载应用内置的 HTML 和 GLSL。

文件管理工具仍需谨慎。首次使用时，请先用一个无用的本地测试文件验证投放与撤销。
最终清空废纸篓仍由 Finder 管理。

## 功能

- 原生 AppKit 菜单栏应用和透明无边框悬浮面板
- WebGL2 测地线追踪、吸积盘与引力透镜黑洞
- 悬停、引力环、多文件错峰螺旋吸入和成功/失败反馈
- 文件、文件夹投放及上一次投放撤销
- 跨桌面显示、始终置顶、位置记忆和“减少动态效果”
- 无第三方运行时依赖

## Windows 版本

Windows 版本在后续规划中，目前没有发布日期。现有应用依赖 AppKit、`WKWebView`
和 `NSWorkspace.recycle`，不能直接在 Windows 上编译。计划是保留 WebGL 黑洞和
交互状态，使用 Windows 原生桌面外壳、WebView2 与回收站 API，并继续遵守“不永久
删除”和“可撤销”的安全原则。详细阶段见 [ROADMAP.md](ROADMAP.md)。

欢迎熟悉 WinUI、WebView2、Windows Shell 或跨平台桌面架构的贡献者先参与设计讨论。

## 项目结构

| 组件 | 职责 |
| --- | --- |
| `BlackHolePanel` | 透明悬浮面板与位置记忆 |
| `BlackHoleView` | 鼠标、拖放状态，原生提示与图标动画 |
| `BlackHoleWebRenderer` | 本地 `WKWebView` 桥接和 WebGL2 生命周期 |
| `blackhole.glsl` | 测地线追踪、吸积盘与交互 uniform |
| `TrashController` | 移入废纸篓和单批撤销 |

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
报告拖放问题时，请附上 macOS 版本、Mac 型号、文件来源应用，以及悬停和松手两个
阶段分别是否出现。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。
