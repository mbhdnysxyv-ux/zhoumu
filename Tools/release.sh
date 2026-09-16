#!/bin/bash
# 归档并上传到 App Store Connect（之后就能在 TestFlight 里分发给测试者）。
#
# 用法：
#   TEAM_ID=ABCDE12345 ./Tools/release.sh
#
# 每次上传都必须用「没用过的构建号」，脚本默认用时间戳，所以直接跑就行。
# 想手工指定：BUILD_NUMBER=7 TEAM_ID=ABCDE12345 ./Tools/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM_ID="${TEAM_ID:-}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"

if [ -z "$TEAM_ID" ]; then
  echo "缺少 TEAM_ID。"
  echo "在 Xcode ▸ Settings ▸ Accounts 选中你的团队，可以看到 10 位的 Team ID，然后："
  echo "  TEAM_ID=ABCDE12345 ./Tools/release.sh"
  exit 1
fi

echo "==> Team ID: $TEAM_ID"
echo "==> 构建号 (CURRENT_PROJECT_VERSION): $BUILD_NUMBER"

echo
echo "==> 1/2 归档 (Release)"
xcodebuild -project ZhouMu.xcodeproj \
  -scheme ZhouMu \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/ZhouMu.xcarchive \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  archive

echo
echo "==> 2/2 导出并上传到 App Store Connect"
xcodebuild -exportArchive \
  -archivePath build/ZhouMu.xcarchive \
  -exportOptionsPlist Tools/ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates

echo
echo "上传完成。接下来到 App Store Connect ▸ 你的 App ▸ TestFlight："
echo "  1. 等构建处理完（几分钟），处理完会有邮件通知"
echo "  2. 填写「测试信息」（测试内容说明、反馈邮箱）"
echo "  3. 提交 Beta 审核"
echo "  4. 审核通过后开启「公开链接」，把链接发出去即可"
