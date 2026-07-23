# Upstream proposal

## Recommendation

Publish Black Hole Bin as an independent repository first. The upstream
`s0xDk/ghostty-blackhole` repository is centered on a Ghostty shader, its
Claude Code signal bridge and a shader tuner. A complete desktop file utility
would add a separate product, lifecycle and support surface.

After the independent repository is public, open a small upstream issue asking
whether the maintainer would like a community-project link. Do not send the
entire application as an unsolicited pull request.

## Draft upstream issue

**Title**

```text
Showcase: macOS Black Hole Bin built from the shader
```

**Body**

```markdown
Hi! I adapted the MIT-licensed Ghostty Blackhole renderer into a small native
macOS utility:

https://github.com/ljunnan24-hash/black-hole-bin

Users drag Finder files or folders onto a transparent black-hole target. The
app adds hover/suction uniforms, transparent output and native recycle/undo
behavior while preserving the upstream geodesic integrator and disk design.

The repository retains your copyright and MIT license, links back to this
project, and records the reviewed upstream commit (`b49fa0a`) in its
third-party notices.

Would you be open to a small README "Community projects" or "Showcase" link?
I am happy to submit only that documentation change and keep the application
in its independent repository.
```

## Minimal follow-up pull request

Only open this after the maintainer agrees. Add a short section near the end of
the upstream README:

```markdown
## Community projects

- [Black Hole Bin](https://github.com/ljunnan24-hash/black-hole-bin) — a
  native macOS drag-to-Trash utility using an adapted version of this renderer.
```

## If upstream requests an example directory

Keep the upstream contribution small:

- Add a git submodule only if the maintainer explicitly prefers one.
- Otherwise link to the independent repository.
- Do not duplicate generated app bundles or screenshots unnecessarily.
- Keep Black Hole Bin releases, issues and file-safety support in its own repo.
