import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, SceneShell, useSpringIn } from "../anim";

/**
 * 提出痛点并立刻给出答案：
 * 「开学第 4 周，循环 3 周 → 今天是第几周？」  →  「第 1 周」
 */
export const Problem: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();

  const questionOpacity = interpolate(frame, [0, 22, 128, 152], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const answerP = useSpringIn(138, { damping: 13, mass: 0.75, stiffness: 100 });

  return (
    <SceneShell duration={duration} glow={0.85} glowY={48}>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        {/* 提问 */}
        <AbsoluteFill
          style={{
            justifyContent: "center",
            alignItems: "center",
            opacity: questionOpacity,
          }}
        >
          <FadeUp delay={0} distance={30}>
            <div
              style={{
                fontSize: 34,
                fontWeight: 500,
                letterSpacing: 2,
                color: COLORS.orange,
                textAlign: "center",
              }}
            >
              开学第 4 周 · 循环 3 周
            </div>
          </FadeUp>

          <div style={{ height: 30 }} />

          <FadeUp delay={40} distance={34}>
            <div
              style={{
                fontSize: 84,
                fontWeight: 700,
                letterSpacing: -1,
                color: COLORS.text,
              }}
            >
              今天是第几周？
            </div>
          </FadeUp>
        </AbsoluteFill>

        {/* 答案 */}
        <AbsoluteFill
          style={{
            justifyContent: "center",
            alignItems: "center",
            opacity: answerP,
            transform: `scale(${0.86 + 0.14 * answerP})`,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "baseline",
              gap: 18,
              color: COLORS.orange,
            }}
          >
            <span style={{ fontSize: 72, fontWeight: 600 }}>第</span>
            <span
              style={{
                fontSize: 250,
                fontWeight: 700,
                lineHeight: 1,
                letterSpacing: -8,
                textShadow: "0 20px 90px rgba(250,115,23,0.45)",
              }}
            >
              1
            </span>
            <span style={{ fontSize: 72, fontWeight: 600 }}>周</span>
          </div>

          <div style={{ height: 26 }} />

          <div
            style={{
              fontSize: 32,
              fontWeight: 400,
              letterSpacing: 2,
              color: COLORS.textDim,
              opacity: Math.max(0, Math.min(1, (frame - 190) / 24)),
            }}
          >
            模运算算完了，你只管看结果
          </div>
        </AbsoluteFill>
      </AbsoluteFill>
    </SceneShell>
  );
};
