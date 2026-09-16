#!/bin/bash
# 在没有模拟器运行时的机器上，用 ImageRenderer 把界面渲染成 PNG 来检查排版。
# 做法：把视图源码复制一份，去掉 #Preview 宏（需要 swift-plugin-server，沙箱里跑不起来），
# 然后用 macOS 目标编译渲染，App 源码本身保持不动。
set -euo pipefail
cd "$(dirname "$0")/.."

export SWIFT_MODULECACHE_PATH="$PWD/build/ModuleCache"
mkdir -p "$SWIFT_MODULECACHE_PATH"

WORK="$PWD/build/UIHarness"
rm -rf "$WORK"
mkdir -p "$WORK/Views" "$WORK/Models"

sed '/^#Preview/,$d' ZhouMu/Views/HomeView.swift > "$WORK/Views/HomeView.swift"
# 设置页额外把 ScrollView 换成 VStack：ImageRenderer 在无宿主环境下不会布局 ScrollView 的内容，
# 换掉只是为了能截图检查卡片排版，App 里仍然是 ScrollView。
sed -e '/^#Preview/,$d' -e 's/ScrollView {/VStack {/' \
    ZhouMu/Views/SettingsView.swift > "$WORK/Views/SettingsView.swift"
cp Shared/*.swift ZhouMu/Models/AppSettings.swift "$WORK/Models/"
cp Tools/UIRender/main.swift "$WORK/main.swift"

swiftc -swift-version 5 -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  "$WORK/main.swift" \
  "$WORK/Models/"*.swift \
  "$WORK/Views/"*.swift \
  -o "$WORK/render"

"$WORK/render" "$WORK/out"
echo "PNG 输出目录：$WORK/out"
