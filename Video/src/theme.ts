// 视觉设计系统：沿用 App 本身的橙白配色，视频整体走深色 keynote 风，
// 让白色的 App 截图在深色背景上"跳"出来。

export const COLORS = {
  /** 背景：近黑，带一点点冷调 */
  bg: "#08080A",
  bgCard: "#141418",
  bgCardSoft: "#1C1C22",

  /** 文字 */
  text: "#F5F5F7",
  textDim: "#98989F",
  textFaint: "#5A5A63",

  /** App 的橙 */
  orange: "#FA7317",
  orangeBright: "#FF8C3A",
  orangeDeep: "#D54C04",
  orangeSoft: "#FFE5CD",

  white: "#FFFFFF",
  line: "rgba(255,255,255,0.10)",
};

/** macOS 上会解析成 SF Pro / PingFang SC，最接近苹果发布会的观感 */
export const FONT =
  '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro SC", "PingFang SC", "Helvetica Neue", "Microsoft YaHei", sans-serif';

/** 时间轴：30fps，全部以帧为单位 */
export const FPS = 30;

export const SCENES = {
  intro: { from: 0, dur: 165 },
  problem: { from: 165, dur: 225 },
  home: { from: 390, dur: 285 },
  schedule: { from: 675, dur: 285 },
  widget: { from: 960, dur: 225 },
  install: { from: 1185, dur: 1260 },
  outro: { from: 2445, dur: 255 },
} as const;

export const TOTAL_FRAMES = SCENES.outro.from + SCENES.outro.dur; // 2700 帧 = 90 秒
