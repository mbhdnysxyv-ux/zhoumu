#!/bin/bash
# 把小组件界面渲染成 PNG 检查排版（不需要真机，也不需要手动往桌面加小组件）。
# 做法：复制一份小组件源码，去掉 @main 的 WidgetBundle（会和 main.swift 的入口冲突），
# 然后用 macOS 目标编译渲染。
set -euo pipefail
cd "$(dirname "$0")/.."

export SWIFT_MODULECACHE_PATH="$PWD/build/ModuleCache"
mkdir -p "$SWIFT_MODULECACHE_PATH"

WORK="$PWD/build/WidgetRender"
rm -rf "$WORK"
mkdir -p "$WORK/Widget"

cp Shared/*.swift ZhouMuWidget/ZhouMuWidget.swift "$WORK/Widget/"
cp Tools/WidgetRender/main.swift "$WORK/main.swift"

# 去掉 @main 的 WidgetBundle（我们只要渲染单个 View）
sed -i '' '/^@main/,$d' "$WORK/Widget/ZhouMuWidget.swift"
# macOS 上 \.widgetFamily 是只读的，无法从外部注入，改成读一个可设置的全局量
sed -i '' 's|.*@Environment.*widgetFamily.*|    private var family: WidgetFamily { RenderFamily.current }|' \
  "$WORK/Widget/ZhouMuWidget.swift"
# ImageRenderer 不会正确布局 WidgetKit 的 containerBackground（会把内容挤到左边），
# 换成普通 background 只为截图检查内容排版；App/小组件里的真实代码仍然是 containerBackground。
sed -i '' 's|\.containerBackground(Palette\.background, for: \.widget)|.background(Palette.background)|' \
  "$WORK/Widget/ZhouMuWidget.swift"

swiftc -swift-version 5 -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  "$WORK/main.swift" "$WORK/Widget/"*.swift \
  -o "$WORK/render"

"$WORK/render" "$WORK/out"
echo "PNG 输出目录：$WORK/out"
