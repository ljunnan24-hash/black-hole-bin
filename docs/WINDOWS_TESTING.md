# Windows hardware smoke test / Windows 实机冒烟测试

This checklist turns real-device results into auditable project evidence. The
automated workflow already compiles and packages x64 and ARM64 installers, but
CI does not prove that File Explorer drag/drop, WebView2 rendering and Recycle
Bin recovery behave correctly on a physical Windows device.

这份清单用于把真实 Windows 设备结果变成可追踪的项目证据。自动工作流已经能构建
x64 和 ARM64 安装包，但 CI 不能代替实体电脑上的文件资源管理器拖放、WebView2
渲染、系统回收站和卸载测试。

## Safety first / 安全前提

1. Download only from the official
   [GitHub Releases page](https://github.com/ljunnan24-hash/black-hole-bin/releases).
2. Use a newly created disposable file and folder. Never begin with important
   or irreplaceable data.
3. Do not disable Windows security globally. The preview is unsigned; if local
   policy blocks it, stop and report that result.
4. If an item disappears without appearing in the Recycle Bin, stop testing
   immediately and use
   [private vulnerability reporting](https://github.com/ljunnan24-hash/black-hole-bin/security/advisories/new).

只使用专门新建的无用文件和文件夹。若文件消失后没有进入回收站，请立即停止测试，
不要继续尝试更多文件。

## Verify the download / 校验下载

Download `SHA256SUMS.txt` beside the installer, then run PowerShell:

```powershell
Get-FileHash ".\Black.Hole.Bin_0.2.0_x64-setup.exe" -Algorithm SHA256
Get-Content ".\SHA256SUMS.txt"
```

For Windows on ARM, replace `x64` with `arm64`. The displayed hash must match
the corresponding line in `SHA256SUMS.txt`.

## Test matrix / 测试矩阵

Please report the exact Windows edition/build, CPU architecture, device or VM,
installer format and WebView2 version when available.

| Target | Automated build | Real-device evidence needed |
| --- | --- | --- |
| Windows 11 x64 | Passing | Installer, drag/drop, restore, settings, uninstall |
| Windows 11 ARM64 | Passing | Native installer, drag/drop, restore, settings |
| Windows 10 x64 | Passing | Compatibility and WebView2 behavior |

## Required smoke test / 必测项目

Mark each item pass, fail or not tested:

- [ ] The NSIS installer opens and installs for the current user.
- [ ] The app launches and shows a transparent floating black hole.
- [ ] Pointer hover changes the black hole and attraction rings appear.
- [ ] Double-click plays a preview without moving any file.
- [ ] Dragging a disposable local file over the target shows the release hint.
- [ ] Releasing the file plays suction and moves it to the Recycle Bin exactly
      once.
- [ ] **Restore** in the Recycle Bin returns the file to its original location.
- [ ] A disposable folder can be recycled and restored.
- [ ] Multiple disposable files animate and move as one batch.
- [ ] A filename containing spaces and Simplified Chinese can be recycled and
      restored.
- [ ] **Open Recycle Bin**, **Always on top** and **Reduce motion** work.
- [ ] Moving/resizing the window is remembered after restart.
- [ ] Uninstalling from Windows Settings removes the app without changing
      existing Recycle Bin contents.

Optional follow-up tests:

- Desktop, OneDrive and a removable drive as drag sources
- More than one display and different display scaling values
- High-contrast mode, keyboard focus and reduced-motion preference
- MSI installation on x64

## Report the result / 提交结果

Use the
[Windows hardware test form](https://github.com/ljunnan24-hash/black-hole-bin/issues/new?template=windows_hardware_test.yml).
Attach only screenshots that contain no private filenames or paths. A failure
report is useful even when installation was blocked by policy or SmartScreen.

报告中请写明每一项的通过、失败或未测试状态。即使安装被单位策略拦截，也属于有价值
的兼容性结果。
