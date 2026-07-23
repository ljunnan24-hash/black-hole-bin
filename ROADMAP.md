# Roadmap

This document describes direction, not a release promise. Priorities may change
after testing and community feedback.

## Now: macOS preview

- Stabilize Finder drag-and-drop across local, cloud and network-backed items.
- Improve multi-display placement, accessibility and reduced-motion behavior.
- Add automated coverage around recycle, undo and duplicate-drop prevention.
- Publish clear source-build instructions and real interaction media.

## Next: trusted macOS distribution

- Build a universal Apple silicon and Intel app.
- Sign with Developer ID, notarize with Apple and staple the ticket.
- Publish a versioned `.dmg` or `.zip` with SHA-256 checksums.
- Add an in-app update strategy only after the release channel is trusted.

Until those items are complete, the project does not publish an unsigned binary
and asks users to build locally from auditable source.

## Later: Windows

Windows support is planned for exploration, with no release date yet. The likely
shape is:

1. Extract the interaction states and animation contract from the AppKit shell.
2. Reuse the WebGL black-hole renderer through WebView2.
3. Build a native Windows desktop drop target.
4. Move files with the Windows Recycle Bin API, preserving undo and never adding
   a permanent-delete path.
5. Match reduced motion, multi-display placement, startup behavior, signing and
   installer expectations on Windows 11.

The current macOS app depends on AppKit, `WKWebView` and
`NSWorkspace.recycle`, so Windows will be a platform-specific shell around a
shared visual and interaction core—not a direct Swift build.

## Non-goals

- Permanent deletion
- Cloud storage, accounts, analytics or remote rendering
- A privileged helper or Full Disk Access requirement

Ideas and implementation proposals are welcome in
[GitHub Discussions or Issues](https://github.com/ljunnan24-hash/black-hole-bin/issues).
