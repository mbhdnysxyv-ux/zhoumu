import React from "react";
import {
  AbsoluteFill,
  Img,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { COLORS } from "../theme";
import { FadeUp, SceneShell } from "../anim";

/** 开场：图标弹入 + 应用名 */
export const Intro: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const iconP = spring({
    frame,
    fps,
    config: { damping: 13, mass: 0.8, stiffness: 95 },
    durationInFrames: 46,
  });

  // 落位之后开始缓慢上下浮动，避免画面"死"着
  const floatAmount = Math.min(1, Math.max(0, (frame - 46) / 34));
  const float = Math.sin((frame - 46) / 34) * 7 * floatAmount;
  const glow = 0.75 + 0.25 * Math.min(1, frame / 40);

  return (
    <SceneShell duration={duration} glow={1.15} glowY={44}>
      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
        }}
      >
        <div
          style={{
            transform: `translateY(${float}px) scale(${0.72 + 0.28 * iconP})`,
            opacity: iconP,
          }}
        >
          <Img
            src={staticFile("appicon.png")}
            style={{
              width: 248,
              height: 248,
              borderRadius: 56,
              display: "block",
              boxShadow: `0 46px 110px rgba(250,115,23,${0.34 * glow}), 0 0 0 1px rgba(255,255,255,0.10)`,
            }}
          />
        </div>

        <div style={{ height: 52 }} />

        <FadeUp delay={16} distance={34}>
          <div
            style={{
              fontSize: 124,
              fontWeight: 700,
              letterSpacing: 10,
              color: COLORS.white,
              textShadow: "0 6px 40px rgba(0,0,0,0.5)",
            }}
          >
            周目
          </div>
        </FadeUp>

        <div style={{ height: 22 }} />

        <FadeUp delay={30} distance={26}>
          <div
            style={{
              fontSize: 38,
              fontWeight: 400,
              letterSpacing: 3,
              color: COLORS.textDim,
            }}
          >
            开学第几周，打开就知道
          </div>
        </FadeUp>
      </AbsoluteFill>
    </SceneShell>
  );
};
