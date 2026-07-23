# Releasing

## Source release checklist

- [ ] `./Scripts/check.sh`
- [ ] `./Scripts/build-app.sh`
- [ ] `cd windows && npm ci && npm run check`
- [ ] Verify the app signature with `codesign --verify --deep --strict`
- [ ] Test hover, drop and undo with a disposable Finder file
- [ ] Review `git status` for generated files or private paths
- [ ] Confirm `THIRD_PARTY_NOTICES.md` matches the bundled shader
- [ ] Update `CHANGELOG.md`, `CFBundleShortVersionString`, `package.json`,
      `Cargo.toml` and `tauri.conf.json`
- [ ] Push `main`, wait for CI, then create an annotated version tag

Suggested first repository settings:

- Repository: `ljunnan24-hash/black-hole-bin`
- Description: `A macOS and Windows trash target rendered as a gravitationally lensed black hole.`
- Topics: `macos`, `windows`, `swift`, `rust`, `tauri`, `webgl2`, `trash`, `black-hole`
- License: MIT
- Enable Issues and private vulnerability reporting
- Protect `main` after CI has passed at least once

## macOS binary release checklist

Do not attach the current ad-hoc-signed bundle to a public release.

Before distributing a downloadable app:

1. Build a universal binary or publish architecture-specific artifacts clearly.
2. Sign nested code and the app with a Developer ID Application certificate.
3. Submit the archive for Apple notarization.
4. Staple the notarization ticket.
5. Test the downloaded archive on a clean macOS account.
6. Publish SHA-256 checksums.

## Windows release checklist

The Windows workflow builds x64 NSIS/MSI and ARM64 NSIS installers on every
commit. A `v*` tag publishes the successful artifacts to GitHub Releases.

1. Run the source checklist and push `main`.
2. Wait for both macOS CI and both Windows matrix jobs to pass.
3. Test the x64 installer on a clean Windows 10 or 11 account.
4. Test the ARM64 installer on Windows on ARM hardware or a trusted VM.
5. Create and push an annotated tag matching the versions in source.
6. Confirm the release contains x64 `.exe`, x64 `.msi` and ARM64 `.exe`.
7. Verify every asset against the generated `SHA256SUMS.txt`.
8. State clearly that preview installers are unsigned until a code-signing
   certificate and protected CI secret are configured.

## Upstream submission

Follow [docs/upstream-proposal.md](docs/upstream-proposal.md). Publish this
repository first, ask the upstream maintainer whether they want a community
link, and open only the small documentation pull request they approve.
