# Third-party notices

## ghostty-blackhole

The black-hole renderer directly adapts the following mature implementation:

- Project: `s0xDk/ghostty-blackhole`
- Source: https://github.com/s0xDk/ghostty-blackhole
- Source commit reviewed: `b49fa0ab2eaf0644a690f4cb386d70c21eb9f969`
- Upstream copyright: Copyright (c) 2026 s13k <s13k@pm.me>
- License: MIT

The complete upstream license text is bundled at:
`Licenses/ghostty-blackhole-MIT.txt`.

The bundled `blackhole.glsl` preserves the upstream geodesic integrator, thin
disk crossings, blackbody color, Doppler beaming, photon-ring hierarchy,
relativistic time dilation and turbulent disk design. The modifications are
limited to a desktop-bin input mode, upstream preset transitions, a transparent
output channel and success/error feedback rings.

The source copy retains the upstream token, Pomodoro and demo branches for
traceability, but the packaged application selects `MODE_BIN` and does not
wire the upstream Ghostty or Claude Code integrations.

## Generated application icon

The application icon was created specifically for this project with OpenAI's
image-generation tooling. It is distributed under this project's MIT license.

## Additional implementation references

The desktop overlay behavior was informed by the MIT-licensed
`GreenScreen410/singularity` project:

- Source: https://github.com/GreenScreen410/singularity
- Source commit reviewed: `02898ba135318ee49e3021b2cb376be950561a33`

No source files from that project are distributed in this application.
