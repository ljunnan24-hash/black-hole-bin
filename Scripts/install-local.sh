#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
app_name="黑洞垃圾箱.app"
source_app="$project_dir/dist/$app_name"
install_dir=${BLACK_HOLE_BIN_INSTALL_DIR:-"$HOME/Applications"}
installed_app="$install_dir/$app_name"

if [[ "$(uname -s)" != "Darwin" ]]; then
    print -u2 "Black Hole Bin currently supports macOS only."
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    print -u2 "Swift is required. Install Xcode Command Line Tools with: xcode-select --install"
    exit 1
fi

if [[ "$install_dir" != /* ]]; then
    print -u2 "BLACK_HOLE_BIN_INSTALL_DIR must be an absolute path."
    exit 1
fi

"$project_dir/Scripts/check.sh"
"$project_dir/Scripts/build-app.sh"

mkdir -p "$install_dir"
if [[ -e "$installed_app" ]]; then
    timestamp=$(date "+%Y%m%d-%H%M%S")
    previous_app="$HOME/.Trash/黑洞垃圾箱.previous-$timestamp.app"
    mv "$installed_app" "$previous_app"
    print "Moved the previous installation to: $previous_app"
fi

/usr/bin/ditto "$source_app" "$installed_app"
/usr/bin/codesign --verify --deep --strict "$installed_app"

if [[ "${BLACK_HOLE_BIN_SKIP_LAUNCH:-0}" != "1" ]]; then
    open "$installed_app"
fi

print "Installed: $installed_app"
