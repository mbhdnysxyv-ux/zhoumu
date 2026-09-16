import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, Headline, Kicker, PhoneShot, SceneShell, useSpringIn } from "../anim";

const Bullet: React.FC<{
  delay: number;
  color: string;
  title: string;
  desc: string;
}> = ({ delay, color, title, desc }) => (
  <FadeUp delay={delay} distance={30}>
    <div style={{ display: "flex", alignItems: "flex-start", gap: 16 }}>
      <div
        style={{
          width: 10,
          height: 10,
          borderRadius: 5,
          backgroundColor: color,
          marginTop: 15,
          flexShrink: 0,
        }}
      />
      <div>
        <div style={{ fontSize: 32, fontWeight: 600, color: COLORS.text }}>
          {title}
        </div>
        <div
          style={{
            fontSize: 24,
            fontWeight: 400,
            color: COLORS.textDim,
            marginTop: 6,
          }}
        >
          {desc}
        </div>
      </div>
    </div>
  </FadeUp>
);

/** 主界面介绍 */
export const FeatureHome: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const shotP = useSpringIn(14, { damping: 200, mass: 0.9, stiffness: 90 });
  const zoom = interpolate(frame, [20, duration], [1, 1.06], {
    extrapolateRight: "clamp",
  });

  return (
    <SceneShell duration={duration} glow={0.6} glowY={44}>
      <AbsoluteFill
        style={{
          flexDirection: "row",
          alignItems: "center",
          paddingLeft: 168,
          paddingRight: 120,
          gap: 90,
        }}
      >
        {/* 左侧文字 */}
        <div style={{ flex: 1 }}>
          <Kicker delay={4}>主界面</Kicker>
          <div style={{ height: 22 }} />
          <Headline delay={10} size={78}>
            打开就是答案
          </Headline>
          <div style={{ height: 46 }} />

          <div style={{ display: "flex", flexDirection: "column", gap: 30 }}>
            <Bullet
              delay={22}
              color={COLORS.orange}
              title="圈内 = 今天要上的科目"
              desc="课表里今天那一格，直接显示在最中间"
            />
            <Bullet
              delay={32}
              color={COLORS.orangeBright}
              title="圈下 = 第几周"
              desc="同时标出开学第几周、以及循环到第几周"
            />
            <Bullet
              delay={42}
              color="rgba(255,255,255,0.45)"
              title="外圈 = 本周进度"
              desc="橙色弧线表示这一周已经过了几天"
            />
          </div>
        </div>

        {/* 右侧手机 */}
        <div
          style={{
            opacity: shotP,
            transform: `translateX(${(1 - shotP) * 90}px) scale(${0.92 + 0.08 * shotP})`,
          }}
        >
          <PhoneShot
            src="home.png"
            height={780}
            style={{ transform: `scale(${zoom})` }}
          />
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
