# Security policy

## Supported versions

Security fixes are currently made on the latest `main` branch only.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature when the repository
is published. Do not open a public issue for a vulnerability that could cause
unexpected file movement, data loss or code execution.

Include the affected commit, macOS version, reproduction steps and the smallest
safe test case you can provide. Do not attach private user files.

## File-safety invariants

- Drops use `NSWorkspace.recycle`; the app has no permanent-delete path.
- A drop is accepted at most once, even when both native and fallback drag
  handlers observe the same release.
- Undo restores only the most recent batch returned by the system recycle API.
- The renderer loads bundled local HTML and GLSL; no remote page is requested.
- The app does not request Full Disk Access or install a privileged helper.
