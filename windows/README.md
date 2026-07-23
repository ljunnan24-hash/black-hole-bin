# Black Hole Bin for Windows

This directory contains the Tauri 2 Windows client. It reuses the same bundled
WebGL renderer as the native macOS app and moves dropped files and folders to
the Windows Recycle Bin through the audited `trash` Rust crate.

## Requirements

- Windows 10 version 1803 or newer, or Windows 11
- Microsoft Edge WebView2 Runtime (included with supported Windows releases)
- Node.js 24 and Rust stable for source builds
- Visual Studio 2022 Build Tools with **Desktop development with C++**

## Run from source

```powershell
git clone https://github.com/ljunnan24-hash/black-hole-bin.git
cd black-hole-bin\windows
npm install
npm run tauri dev
```

Build an installer:

```powershell
npm ci
npm run check
npm run tauri build
```

The generated NSIS `.exe` and WiX `.msi` files are under
`src-tauri\target\release\bundle`. GitHub Actions also builds x64 and ARM64
artifacts for every commit on `main`.

## Safety

- There is no permanent-delete command.
- Every path is validated before the first Recycle Bin operation starts.
- Empty, relative, missing and filesystem-root paths are rejected.
- A single drop is capped at 128 paths and nested duplicates are removed.
- The app makes no network requests and loads the renderer from local files.

The current Windows preview does not yet provide one-click undo inside the app.
Use the standard **Restore** command in the Windows Recycle Bin. Test the first
drop with a disposable file.
