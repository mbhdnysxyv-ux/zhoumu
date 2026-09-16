#!/bin/bash
# 打包 IPA。
#
# 1) 无签名 IPA —— 不需要任何证书，给 SideStore / Sideloadly / ESign 之类工具重新签名安装：
#      ./Tools/make_ipa.sh
#    产物：build/ZhouMu-<版本>-unsigned.ipa
#
# 2) 已签名 IPA —— 需要付费开发者账号 + 证书 + 已注册的设备 UDID：
#      TEAM_ID=ABCDE12345 ./Tools/make_ipa.sh --signed
#    产物：build/ZhouMu-<版本>-signed/ZhouMu.ipa
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="unsigned"
if [ "${1:-}" = "--signed" ]; then MODE="signed"; fi

BUILD_DIR="$PWD/build"
DD="$BUILD_DIR/DerivedData"

if [ "$MODE" = "unsigned" ]; then
  echo "==> Release 构建（不签名）"
  xcodebuild -project ZhouMu.xcodeproj -scheme ZhouMu -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DD" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
    build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5

  APP="$DD/Build/Products/Release-iphoneos/ZhouMu.app"
  [ -d "$APP" ] || { echo "构建产物不存在：$APP"; exit 1; }

  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Info.plist")
  OUT="$BUILD_DIR/ZhouMu-${VERSION}-unsigned.ipa"

  echo "==> 组装 IPA"
  rm -rf "$BUILD_DIR/ipa"
  mkdir -p "$BUILD_DIR/ipa/Payload"
  cp -R "$APP" "$BUILD_DIR/ipa/Payload/"
  rm -f "$OUT"
  ( cd "$BUILD_DIR/ipa" && zip -qry "$OUT" Payload )

  echo
  echo "完成：$OUT"
  echo "签名状态：$(codesign -dv "$APP" 2>&1 | head -1 || true)"
  echo
  echo "安装方式见 发布到TestFlight.md 第 0 节（无签名 IPA 怎么装）。"
  exit 0
fi

# ---------- 已签名 ----------
TEAM_ID="${TEAM_ID:-}"
if [ -z "$TEAM_ID" ]; then
  echo "已签名模式需要 TEAM_ID：TEAM_ID=ABCDE12345 ./Tools/make_ipa.sh --signed"
  exit 1
fi

BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
ARCHIVE="$BUILD_DIR/ZhouMu-ipa.xcarchive"
EXPORT="$BUILD_DIR/ZhouMu-signed"

echo "==> 归档 (Team: ${TEAM_ID}, 构建号: ${BUILD_NUMBER})"
xcodebuild -project ZhouMu.xcodeproj -scheme ZhouMu -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  archive 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)|ARCHIVE" | head -8

echo "==> 导出 IPA"
rm -rf "$EXPORT"
cat > "$BUILD_DIR/ExportOptions-ipa.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>development</string>
	<key>teamID</key>
	<string>${TEAM_ID}</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions-ipa.plist" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates 2>&1 | grep -E "error:|Exported|EXPORT" | head -8

echo
echo "完成：$EXPORT/ZhouMu.ipa"
echo "把 iPhone 连上 Mac，用 Xcode ▸ Window ▸ Devices and Simulators ▸ Install 安装，"
echo "或用 Apple Configurator / Finder 拖进去。"
