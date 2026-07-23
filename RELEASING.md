# Releasing

## Source release checklist

- [ ] `./Scripts/check.sh`
- [ ] `./Scripts/build-app.sh`
- [ ] Verify the app signature with `codesign --verify --deep --strict`
- [ ] Test hover, drop and undo with a disposable Finder file
- [ ] Review `git status` for generated files or private paths
- [ ] Confirm `THIRD_PARTY_NOTICES.md` matches the bundled shader
- [ ] Update `CHANGELOG.md` and `CFBundleShortVersionString`
- [ ] Push `main`, wait for CI, then create an annotated version tag

Suggested first repository settings:

- Repository: `ljunnan24-hash/black-hole-bin`
- Description: `A native macOS trash target rendered as a gravitationally lensed black hole.`
- Topics: `macos`, `swift`, `appkit`, `webgl2`, `shader`, `trash`, `black-hole`
- License: MIT
- Enable Issues and private vulnerability reporting
- Protect `main` after CI has passed at least once

## Binary release checklist

Do not attach the current ad-hoc-signed bundle to a public release.

Before distributing a downloadable app:

1. Build a universal binary or publish architecture-specific artifacts clearly.
2. Sign nested code and the app with a Developer ID Application certificate.
3. Submit the archive for Apple notarization.
4. Staple the notarization ticket.
5. Test the downloaded archive on a clean macOS account.
6. Publish SHA-256 checksums.

## Upstream submission

Follow [docs/upstream-proposal.md](docs/upstream-proposal.md). Publish this
repository first, ask the upstream maintainer whether they want a community
link, and open only the small documentation pull request they approve.
