# Contributing

Thanks for helping improve Black Hole Bin.

## Before opening an issue

- Confirm the problem still occurs on the latest `main`.
- Test with a disposable local file.
- Check whether **Reduce Motion** is enabled.
- Note whether the hover response appears and whether release starts suction.

A useful drag/drop report includes:

- Operating system version, device model and x64/ARM64 architecture
- Finder, File Explorer or other source application
- File, folder, package, network volume or cloud-provider item
- Whether the source and Trash are on the same volume
- Relevant Console messages containing `BlackHoleBin`

## Development setup

```sh
git clone https://github.com/ljunnan24-hash/black-hole-bin.git
cd black-hole-bin
./Scripts/check.sh
./Scripts/build-app.sh
open "dist/黑洞垃圾箱.app"
```

For Windows development, use Windows 10/11 with Node.js 24, Rust stable and
Visual Studio 2022 Build Tools:

```powershell
cd windows
npm install
npm run check
npm run tauri dev
```

The macOS client has no external packages. Windows dependencies are locked in
`package-lock.json` and `Cargo.lock` and updated by Dependabot.

## Pull requests

Keep pull requests focused. Describe:

1. The user-visible problem.
2. Why the change is safe for file operations.
3. How it was tested, including recycle and undo.
4. Any GPU or reduced-motion impact.

Never replace `NSWorkspace.recycle` or the Windows `trash::delete_all` call
with permanent deletion. Changes to either drag path must preserve the
duplicate-operation guard. Windows changes must keep the all-paths-first
validation and root-path rejection.

## Shader changes

`Sources/BlackHoleBin/Resources/blackhole.glsl` is a modified upstream work.
Keep the upstream copyright notice and document meaningful divergence in
`THIRD_PARTY_NOTICES.md`. Prefer small input/output adapters over rewriting the
geodesic integrator so future upstream comparisons remain practical.

## Style

- Use Swift concurrency and AppKit APIs available on macOS 13.
- Keep the Windows shell compatible with Windows 10 version 1803 and WebView2.
- Run `npm run check` in `windows/` for Windows frontend or Rust changes.
- Keep UI work on the main actor.
- Avoid dependencies unless they remove substantially more code than they add.
- Use native reduced-motion behavior for new animations.
- Keep all runtime resources local; network access is outside project scope.
