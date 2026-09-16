import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { COLORS, FONT } from "./theme";

// ---------------------------------------------------------------- 动画基元

/** 顺滑的入场（苹果发布会那种不弹跳、稳稳落位的感觉） */
const SMOOTH = { damping: 200, mass: 0.7, stiffness: 110 };
/** 带一点点回弹，用在图标、数字这种要"蹦"出来的元素上 */
const POP = { damping: 14, mass: 0.75, stiffness: 100 };

export const useSpringIn = (delay = 0, config = SMOOTH) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config });
};

/** 场景整体的淡入淡出，避免硬切 */
export const useSceneFade = (
  durationInFrames: number,
  fadeIn = 14,
  fadeOut = 18,
) => {
  const frame = useCurrentFrame();
  return interpolate(
    frame,
    [0, fadeIn, durationInFrames - fadeOut, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
};

// ---------------------------------------------------------------- 布局组件

/** 缓慢呼吸的橙色光晕，给深色背景一点层次 */
const Glow: React.FC<{ intensity?: number; y?: number }> = ({
  intensity = 1,
  y = 44,
}) => {
  const frame = useCurrentFrame();
  const breathe = 0.86 + 0.14 * Math.sin(frame / 48);
  const alpha = 0.24 * intensity * breathe;
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(62% 56% at 50% ${y}%, rgba(250,115,23,${alpha}) 0%, rgba(250,115,23,0) 72%)`,
      }}
    />
  );
};

export const SceneShell: React.FC<{
  duration: number;
  children: React.ReactNode;
  glow?: number;
  glowY?: number;
  fadeIn?: number;
  fadeOut?: number;
}> = ({ duration, children, glow = 1, glowY = 44, fadeIn, fadeOut }) => {
  const opacity = useSceneFade(duration, fadeIn ?? 14, fadeOut ?? 18);
  return (
    <AbsoluteFill
      style={{
        backgroundColor: COLORS.bg,
        opacity,
        fontFamily: FONT,
        color: COLORS.text,
      }}
    >
      {glow > 0 ? <Glow intensity={glow} y={glowY} /> : null}
      {children}
    </AbsoluteFill>
  );
};

/** 加一点纵向位移的淡入 */
export const FadeUp: React.FC<{
  delay?: number;
  distance?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
  config?: typeof SMOOTH;
}> = ({ delay = 0, distance = 44, children, style, config }) => {
  const p = useSpringIn(delay, config ?? SMOOTH);
  return (
    <div
      style={{
        opacity: p,
        transform: `translateY(${(1 - p) * distance}px)`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** 缩放淡入 */
export const ScaleIn: React.FC<{
  delay?: number;
  from?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
  config?: typeof SMOOTH;
}> = ({ delay = 0, from = 0.86, children, style, config }) => {
  const p = useSpringIn(delay, config ?? POP);
  const scale = from + (1 - from) * p;
  return (
    <div style={{ opacity: p, transform: `scale(${scale})`, ...style }}>
      {children}
    </div>
  );
};

// ---------------------------------------------------------------- 排版组件

/** 小号橙色标签 */
export const Kicker: React.FC<{
  children: React.ReactNode;
  delay?: number;
}> = ({ children, delay = 0 }) => (
  <FadeUp delay={delay}>
    <div
      style={{
        fontSize: 26,
        fontWeight: 600,
        letterSpacing: 6,
        color: COLORS.orange,
        textTransform: "uppercase",
      }}
    >
      {children}
    </div>
  </FadeUp>
);

export const Headline: React.FC<{
  children: React.ReactNode;
  delay?: number;
  size?: number;
  weight?: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({
  children,
  delay = 0,
  size = 86,
  weight = 700,
  color = COLORS.text,
  style,
}) => (
  <FadeUp delay={delay} style={style}>
    <div
      style={{
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -1.5,
        lineHeight: 1.16,
        color,
      }}
    >
      {children}
    </div>
  </FadeUp>
);

/** App 截图，套一个圆角+投影的"机身" */
export const PhoneShot: React.FC<{
  src: string;
  height: number;
  style?: React.CSSProperties;
}> = ({ src, height, style }) => (
  <div
    style={{
      height,
      borderRadius: height * 0.09,
      overflow: "hidden",
      boxShadow:
        "0 60px 150px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.10)",
      ...style,
    }}
  >
    <Img src={staticFile(src)} style={{ height: "100%", display: "block" }} />
  </div>
);

/** 圆点指示器 */
export const Dots: React.FC<{
  count: number;
  active: number;
  delay?: number;
}> = ({ count, active, delay = 0 }) => (
  <FadeUp delay={delay}>
    <div style={{ display: "flex", gap: 12 }}>
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          style={{
            width: i === active ? 34 : 12,
            height: 12,
            borderRadius: 6,
            backgroundColor:
              i === active ? COLORS.orange : "rgba(255,255,255,0.18)",
          }}
        />
      ))}
    </div>
  </FadeUp>
);
