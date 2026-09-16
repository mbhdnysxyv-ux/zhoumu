#!/bin/bash
# 双击这个文件即可检查 iPhone 安装环境（不需要懂终端）。
# .command 后缀会被 macOS 用「终端」打开；末尾的 read 让窗口停留，方便看结果。

cd "$(dirname "$0")" || exit 1

clear
echo "════════════════════════════════════════════"
echo "   周目 · 装到 iPhone 的就绪检查"
echo "════════════════════════════════════════════"
echo

./Tools/device_check.sh

echo
echo "────────────────────────────────────────────"
echo "接下来要做什么："
echo
echo "  如果 ② 是 ❌ （还没登录 Apple ID）："
echo "     打开 Xcode ▸ 菜单栏 Xcode ▸ Settings… ▸ Accounts ▸ 左下角 +"
echo "     ▸ 登录你的 Apple ID（免费账号即可）"
echo
echo "  如果 ① 和 ② 都是 ✅ ："
echo "     在 Xcode 里打开 ZhouMu.xcodeproj，"
echo "     给 ZhouMu 和 ZhouMuWidget 【两个 target】都选好 Team，然后按 ⌘R"
echo
echo "  详细步骤见：装到自己的iPhone.md"
echo "────────────────────────────────────────────"
echo
printf "按回车键关闭这个窗口… "
read -r _
