#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
app_name="黑洞垃圾箱.app"
app_dir="$project_dir/dist/$app_name"
contents_dir="$app_dir/Contents"
resources_dir="$contents_dir/Resources"
iconset_dir="$project_dir/.build/AppIcon.iconset"

cd "$project_dir"
swift build -c release

rm -rf "$app_dir" "$iconset_dir"
mkdir -p "$contents_dir/MacOS" "$resources_dir" "$iconset_dir"

cp ".build/release/BlackHoleBin" "$contents_dir/MacOS/BlackHoleBin"
cp "Resources/Info.plist" "$contents_dir/Info.plist"
cp "LICENSE" "$resources_dir/LICENSE.txt"
cp "THIRD_PARTY_NOTICES.md" "$resources_dir/THIRD_PARTY_NOTICES.md"
cp -R "Licenses" "$resources_dir/Licenses"
cp -R ".build/release/BlackHoleBin_BlackHoleBin.bundle" "$resources_dir/BlackHoleBin_BlackHoleBin.bundle"

for spec in \
    "16 icon_16x16.png" \
    "32 icon_16x16@2x.png" \
    "32 icon_32x32.png" \
    "64 icon_32x32@2x.png" \
    "128 icon_128x128.png" \
    "256 icon_128x128@2x.png" \
    "256 icon_256x256.png" \
    "512 icon_256x256@2x.png" \
    "512 icon_512x512.png" \
    "1024 icon_512x512@2x.png"
do
    size=${spec%% *}
    file=${spec#* }
    sips -z "$size" "$size" "Assets/AppIcon-1024.png" --out "$iconset_dir/$file" >/dev/null
done

iconutil -c icns "$iconset_dir" -o "$resources_dir/AppIcon.icns"
rm -rf "$iconset_dir"

plutil -lint "$contents_dir/Info.plist" >/dev/null
codesign --force --deep --sign - "$app_dir" >/dev/null

print "Built: $app_dir"
