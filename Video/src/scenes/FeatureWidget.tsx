import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, Headline, Kicker, SceneShell, ScaleIn } from "../anim";

/** 桌面小组件介绍 */
export const FeatureWidget: React.FC<{ duration: number }> = ({ duration }) => {
  return (
    <SceneShell duration={duration} glow={0.7} glowY={40}>
      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
        }}
      >
        <Kicker delay={4}>桌面小组件</Kicker>
        <div style={{ height: 20 }} />
        <Headline delay={10} size={74}>
          不打开也能看到
        </Headline>
        <div style={{ height: 56 }} />

        <div style={{ display: "flex", alignItems: "center", gap: 56 }}>
          <ScaleIn delay={24} from={0.84}>
            <Img
              src={staticFile("widget-small.png")}
              style={{
                height: 320,
                borderRadius: 40,
                display: "block",
                boxShadow: "0 40px 100px rgba(0,0,0,0.6)",
              }}
            />
          </ScaleIn>

          <ScaleIn delay={34} from={0.84}>
            <Img
              src={staticFile("widget-medium.png")}
              style={{
                height: 320,
                borderRadius: 40,
                display: "block",
                boxShadow: "0 40px 100px rgba(0,0,0,0.6)",
              }}
            />
          </ScaleIn>
        </div>

        <div style={{ height: 52 }} />

        <FadeUp delay={50} distance={26}>
          <div
            style={{
              fontSize: 27,
              color: COLORS.textDim,
              letterSpacing: 1,
            }}
          >
            小号 / 中号两种尺寸 · 正常安装时与 App 里的设置自动同步
          </div>
        </FadeUp>
      </AbsoluteFill>
    </SceneShell>
  );
};
