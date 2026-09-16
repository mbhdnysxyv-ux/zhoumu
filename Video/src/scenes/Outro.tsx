import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, Headline, SceneShell, ScaleIn } from "../anim";

/** 结尾：仓库地址 + 一句话定位 */
export const Outro: React.FC<{ duration: number }> = ({ duration }) => {
  return (
    <SceneShell duration={duration} glow={1.0} glowY={44}>
      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
        }}
      >
        <ScaleIn delay={0} from={0.8}>
          <Img
            src={staticFile("appicon.png")}
            style={{
              width: 132,
              height: 132,
              borderRadius: 30,
              display: "block",
              boxShadow: "0 30px 80px rgba(250,115,23,0.32)",
            }}
          />
        </ScaleIn>

        <div style={{ height: 30 }} />

        <Headline delay={8} size={64}>
          开源免费，随意取用
        </Headline>

        <div style={{ height: 20 }} />

        <FadeUp delay={18} distance={24}>
          <div
            style={{
              fontSize: 28,
              color: COLORS.textDim,
              letterSpacing: 3,
            }}
          >
            不联网 · 不要账号 · 不收集任何数据
          </div>
        </FadeUp>

        <div style={{ height: 54 }} />

        <FadeUp delay={28} distance={26}>
          <div
            style={{
              padding: "26px 46px",
              borderRadius: 22,
              backgroundColor: COLORS.bgCard,
              border: `1px solid ${COLORS.line}`,
              fontSize: 40,
              fontWeight: 600,
              color: COLORS.orange,
              letterSpacing: 0.5,
            }}
          >
            github.com/mbhdnysxyv-ux/zhoumu
          </div>
        </FadeUp>

        <div style={{ height: 34 }} />

        <FadeUp delay={40} distance={22}>
          <div style={{ fontSize: 25, color: COLORS.textFaint, letterSpacing: 1 }}>
            源码 · 安装说明 · 打包好的 IPA，都在仓库里
          </div>
        </FadeUp>
      </AbsoluteFill>
    </SceneShell>
  );
};
