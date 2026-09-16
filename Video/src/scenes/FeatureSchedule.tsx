import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, Headline, Kicker, SceneShell, useSpringIn } from "../anim";
import { ScheduleTable } from "../ScheduleTable";

const Emphasis: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span style={{ color: COLORS.orange, fontWeight: 700 }}>{children}</span>
);

/** 课表介绍：左侧文字讲规则，右侧直接把课表画出来并逐格填满 */
export const FeatureSchedule: React.FC<{ duration: number }> = ({
  duration,
}) => {
  const frame = useCurrentFrame();
  const tableP = useSpringIn(8, { damping: 200, mass: 0.9, stiffness: 90 });

  // 格子填完之后，补一句"今天取哪一格"
  const captionP = interpolate(frame, [186, 212], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <SceneShell duration={duration} glow={0.55} glowY={44}>
      <AbsoluteFill
        style={{
          flexDirection: "row",
          alignItems: "center",
          paddingLeft: 150,
          paddingRight: 130,
          gap: 70,
        }}
      >
        <div style={{ flex: 1 }}>
          <Kicker delay={4}>课表</Kicker>
          <div style={{ height: 22 }} />
          <Headline delay={10} size={78}>
            按周目排课
          </Headline>
          <div style={{ height: 24 }} />
          <FadeUp delay={18}>
            <div
              style={{
                fontSize: 26,
                color: COLORS.textDim,
                lineHeight: 1.62,
                maxWidth: 580,
              }}
            >
              每一排对应一个周目，一排里周一到周日各一节。
            </div>
          </FadeUp>
          <div style={{ height: 48 }} />

          <div style={{ display: "flex", flexDirection: "column", gap: 26 }}>
            <FadeUp delay={30} distance={28}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 14 }}>
                <span style={{ fontSize: 48, fontWeight: 700, color: COLORS.orange }}>
                  N
                </span>
                <span style={{ fontSize: 27, color: COLORS.text }}>
                  排 = 你的循环周数
                </span>
              </div>
            </FadeUp>
            <FadeUp delay={40} distance={28}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 14 }}>
                <span style={{ fontSize: 48, fontWeight: 700, color: COLORS.orange }}>
                  7
                </span>
                <span style={{ fontSize: 27, color: COLORS.text }}>
                  列 = 周一到周日，每格一节
                </span>
              </div>
            </FadeUp>
            <FadeUp delay={50} distance={28}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 14 }}>
                <span style={{ fontSize: 48, fontWeight: 700, color: COLORS.orange }}>
                  2
                </span>
                <span style={{ fontSize: 27, color: COLORS.text }}>
                  个选项 =「无」和「自定义」
                </span>
              </div>
            </FadeUp>
          </div>
        </div>

        <div
          style={{
            opacity: tableP,
            transform: `translateX(${(1 - tableP) * 70}px)`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
          }}
        >
          <ScheduleTable />

          <div
            style={{
              marginTop: 38,
              opacity: captionP,
              fontSize: 26,
              color: COLORS.textDim,
              letterSpacing: 0.5,
            }}
          >
            今天周三、显示第 <Emphasis>1</Emphasis> 周 → 自动取第{" "}
            <Emphasis>1</Emphasis> 排周三
          </div>
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
