#!/bin/bash
# 把「设备逻辑坐标」换算成屏幕坐标后调用 siminput。
# 模拟器窗口大小会变，所以每次都现算。
set -euo pipefail
cd "$(dirname "$0")/.."

DEV_W=${SIM_DEV_W:-402}; DEV_H=${SIM_DEV_H:-874}   # 默认 iPhone 17 Pro；手表用环境变量覆盖
BIN=build/siminput

if [ ! -x "$BIN" ] || [ Tools/siminput.swift -nt "$BIN" ]; then
  mkdir -p build
  swiftc -O Tools/siminput.swift -o "$BIN"
fi

# 取模拟器窗口几何。开着多个设备时用 SIM_WINDOW 指定窗口标题里的关键字。
if [ -n "${SIM_WINDOW:-}" ]; then
  GEO=$(osascript <<APPLESCRIPT 2>/dev/null | tr -d ' '
tell application "System Events"
  tell process "Simulator"
    repeat with w in windows
      if name of w contains "$SIM_WINDOW" then
        return {position of w, size of w}
      end if
    end repeat
  end tell
end tell
APPLESCRIPT
)
else
  GEO=$(osascript -e 'tell application "System Events" to tell process "Simulator" to get {position, size} of window 1' 2>/dev/null | tr -d ' ')
fi
WX=$(echo "$GEO" | cut -d, -f1); WY=$(echo "$GEO" | cut -d, -f2)
WW=$(echo "$GEO" | cut -d, -f3); WH=$(echo "$GEO" | cut -d, -f4)
BAR=${SIM_TITLEBAR:-28}

read -r OX OY SCALE <<<"$(python3 -c "
ww, wh, wx, wy, bar = $WW, $WH, $WX, $WY, $BAR
cw, ch = ww, wh - bar
s = min(cw/$DEV_W, ch/$DEV_H)
ox = wx + (cw - $DEV_W*s)/2
oy = wy + bar + (ch - $DEV_H*s)/2
print(f'{ox:.1f} {oy:.1f} {s:.4f}')
")"

map() { python3 -c "print(f'{$OX + $1*$SCALE:.0f} {$OY + $2*$SCALE:.0f}')"; }

case "$1" in
  tap)
    read -r X Y <<<"$(map "$2" "$3")"
    "$BIN" tap "$X" "$Y" ;;
  longpress)
    read -r X Y <<<"$(map "$2" "$3")"
    "$BIN" longpress "$X" "$Y" "${4:-1.1}" ;;
  drag)
    read -r X1 Y1 <<<"$(map "$2" "$3")"
    read -r X2 Y2 <<<"$(map "$4" "$5")"
    "$BIN" drag "$X1" "$Y1" "$X2" "$Y2" "${6:-30}" ;;
  *)
    echo "用法: siminput.sh tap/longpress/drag ..." >&2
    exit 2 ;;
esac
