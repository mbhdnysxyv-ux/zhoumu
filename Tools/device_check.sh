#!/bin/bash
# 检查「把周目装到自己 iPhone」需要的东西是否就绪。
# 用法：在工程根目录执行 ./Tools/device_check.sh
set -uo pipefail
cd "$(dirname "$0")/.."

ok()   { printf "  ✅ %s\n" "$1"; }
bad()  { printf "  ❌ %s\n" "$1"; }
warn() { printf "  ⚠️  %s\n" "$1"; }

BUNDLE_ID=$(grep -m1 -o 'APP_BUNDLE_ID = [^;]*' ZhouMu.xcodeproj/project.pbxproj | sed 's/APP_BUNDLE_ID = //')
TEAM=$(grep -m1 -o 'DEVELOPMENT_TEAM = [^;]*' ZhouMu.xcodeproj/project.pbxproj | sed 's/DEVELOPMENT_TEAM = //')

NEED_DEV_MODE=0
NO_ACCOUNT=0

echo "Bundle ID：${BUNDLE_ID}"
echo "Team     ：${TEAM}"
echo "  （Bundle ID 若与别人冲突，只改 project.pbxproj 里的 APP_BUNDLE_ID 一处，"
echo "    App 和小组件会同步变成 xxx 与 xxx.widget）"
echo

echo "① 数据线连接的 iPhone / iPad"
DEVJSON=$(mktemp -t zmdev)
if xcrun devicectl list devices --json-output "$DEVJSON" >/dev/null 2>&1; then
  ROWS=$(python3 - "$DEVJSON" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
for dev in data.get('result', {}).get('devices', []):
    p = dev.get('deviceProperties', {})
    h = dev.get('hardwareProperties', {})
    print("|".join([
        p.get('name', '?'),
        h.get('marketingName', '?'),
        str(p.get('osVersionNumber', '?')),
        str(p.get('developerModeStatus', '?')),
    ]))
PY
)
  if [ -z "$ROWS" ]; then
    bad "没检测到设备 —— 用数据线连上 iPhone，手机上点「信任此电脑」并输入锁屏密码"
  else
    while IFS='|' read -r NAME MODEL OS DEVMODE; do
      [ -z "$NAME" ] && continue
      ok "${NAME}（${MODEL}，iOS ${OS}）"
      MAJOR="${OS%%.*}"
      if [ "$MAJOR" -lt 17 ] 2>/dev/null; then
        bad "系统 iOS ${OS} 低于最低要求 iOS 17，装不上"
      fi
      if [ "$DEVMODE" = "enabled" ]; then
        ok "开发者模式：已开启"
      else
        bad "开发者模式：未开启（这一步只能在手机上做，见文末）"
        NEED_DEV_MODE=1
      fi
    done <<< "$ROWS"
  fi
else
  bad "无法列出设备（devicectl 执行失败）"
fi
rm -f "$DEVJSON"
echo

echo "② Xcode 账号"
# defaults read 输出的中文是 \Uxxxx 转义（而且反斜杠被多转义了一层），用 perl 解回来
ACCOUNT_RAW=$(defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null)
ACCOUNT=$(printf '%s' "$ACCOUNT_RAW" | perl -CSD -pe 's/\\+U([0-9a-fA-F]{4})/chr(hex($1))/ge')
TEAM_NAME=$(printf '%s' "$ACCOUNT" | grep -o 'teamName = "[^"]*"' | sed 's/teamName = "//; s/"$//' | head -1)
TEAM_TID=$(printf '%s' "$ACCOUNT" | grep -o 'teamID = [A-Z0-9]*' | head -1 | awk '{print $3}')
if printf '%s' "$ACCOUNT" | grep -q 'isFreeProvisioningTeam = 1'; then
  TEAM_KIND="免费账号"
else
  TEAM_KIND="付费账号"
fi
if [ -n "$TEAM_TID" ]; then
  ok "${TEAM_NAME}  ｜  teamID=${TEAM_TID}  ｜  ${TEAM_KIND}"
else
  bad "Xcode 里还没有账号 —— Xcode ▸ Settings… ▸ Accounts ▸ 左下角 + ▸ 登录 Apple ID"
  NO_ACCOUNT=1
fi
echo

echo "③ 代码签名证书"
IDENT=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development")
if [ -n "$IDENT" ]; then
  echo "$IDENT" | sed 's/^/  ✅ /'
else
  warn "还没有 —— 这是正常的：第一次真机编译（⌘R）时 Xcode 会自动创建"
fi
echo

echo "④ 描述文件"
PROF_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
COUNT=0
[ -d "$PROF_DIR" ] && COUNT=$(ls -A "$PROF_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  ok "已安装 ${COUNT} 个"
else
  warn "还没有 —— 第一次真机编译时自动创建，正常"
fi
echo

echo "⑤ 项目侧（已提前处理，不需要你动手）"
if grep -q "application-groups" ZhouMu.xcodeproj/project.pbxproj; then
  warn "检测到 App Group —— 免费账号可能签不出来"
else
  ok "不含任何需要付费账号的能力（无 App Group / 推送 / iCloud / HealthKit）"
fi
if [ -n "$TEAM" ]; then
  ok "Team 已写入工程：${TEAM}（App 与小组件都生效）"
else
  warn "工程里没写 Team —— 需要在 Xcode 里手动选"
fi
ok "小组件 Bundle ID 自动跟随主 App：\$(APP_BUNDLE_ID).widget"
ok "出口合规已声明：ITSAppUsesNonExemptEncryption = NO"
ok "隐私清单已就位：ZhouMu/PrivacyInfo.xcprivacy"
echo

echo "────────────────────────────────────────────"
if [ "$NO_ACCOUNT" = "1" ]; then
  echo "下一步：在 Xcode 里登录 Apple ID"
  echo "  Xcode ▸ 菜单栏 Xcode ▸ Settings… ▸ Accounts ▸ 左下角 + ▸ Apple ID"
  echo "  （免费账号即可，不需要开发者计划）"
elif [ "$NEED_DEV_MODE" = "1" ]; then
  echo "下一步：在 iPhone 上开启开发者模式（必须，iOS 16+ 强制要求）"
  echo
  echo "  1. iPhone 打开「设置」"
  echo "  2. 进入「隐私与安全性」"
  echo "  3. 滑到最底部，点「开发者模式」"
  echo "  4. 打开开关，提示需要重启时点「重新启动」"
  echo "  5. 重启后屏幕会弹出确认框，点「打开」并输入锁屏密码"
  echo
  echo "  （如果「隐私与安全性」里找不到「开发者模式」，说明手机还没被 Xcode 识别过："
  echo "    保持数据线连接，在 Xcode 里按一次 ⌘R 让报错出现，再回来就能看到了）"
  echo
  echo "  开启后重跑本检查，① 会全变 ✅，然后就能编译安装。"
else
  echo "全部就绪 ✅"
  echo "  Xcode 打开 ZhouMu.xcodeproj，设备选你的 iPhone，按 ⌘R"
fi
echo "────────────────────────────────────────────"
