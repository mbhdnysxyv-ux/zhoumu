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

# 所有视图文件都过一遍：去掉 #Preview，并把 ScrollView 换成 VStack
# （ImageRenderer 在无宿主环境下不会布局 ScrollView 的内容，换掉只是为了截图检查排版）。
# 只改副本，App 源码保持原样。需要绕开几处 macOS / ImageRenderer 的限制，
# 全部由下面的 python 统一处理（sed 做不了跨行替换）。
cat > "$WORK/strip.py" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding="utf-8").read()
s = s.split("#Preview")[0]
# 1) TabView：ImageRenderer 在 macOS 上渲染不了它（会出黄色占位），换成直接显示第一页
s = re.sub(r'TabView\(selection: \$page\) \{.*?\}\n\s*\.tabViewStyle\([^\n]*\)\n',
           'firstPage\n', s, flags=re.S)
# 2) ScrollView：无宿主环境下不布局内容
s = s.replace("        ScrollView {", "        VStack {")
s = s.replace("ScrollView(showsIndicators: false) {", "VStack {")
# 3) macOS 上不可用的 API
s = s.replace(".datePickerStyle(.wheel)", "")
s = s.replace(".navigationBarTitleDisplayMode(.inline)", "")
s = re.sub(r'^\s*\.toolbar\(\.hidden, for: \.navigationBar\)\n', '', s, flags=re.M)
# 4) 实时活动在 macOS 上不可用：掏空函数体，保持括号平衡
# 调用改成了多行，用正则跨行匹配
s = re.sub(r'await LiveActivityManager\.shared\.sync\(.*?\)\n', '', s, flags=re.S)
s = re.sub(r'BackgroundRefresh\.schedule\(settings: [^)]*\)\n', '', s)
open(dst, "w", encoding="utf-8").write(s)
PYEOF

for f in ZhouMu/Views/*.swift; do
  python3 "$WORK/strip.py" "$f" "$WORK/Views/$(basename "$f")"
done
cp Shared/*.swift ZhouMu/Models/*.swift "$WORK/Models/"
cp Tools/UIRender/main.swift "$WORK/main.swift"

swiftc -swift-version 5 -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  "$WORK/main.swift" \
  "$WORK/Models/"*.swift \
  "$WORK/Views/"*.swift \
  -o "$WORK/render"

"$WORK/render" "$WORK/out"
echo "PNG 输出目录：$WORK/out"
