#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
cd "$project_dir"

swift build -c release
.build/release/BlackHoleBin --self-test
plutil -lint Resources/Info.plist
