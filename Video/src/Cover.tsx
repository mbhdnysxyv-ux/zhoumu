import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { COLORS, FONT } from "./theme";

const Pill: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    style={{
      padding: "16px 32px",
      borderRadius: 999,
      backgroundColor: "rgba(250,115,23,0.14)",
      border: "1px solid rgba(250,115,23,0.35)",
      color: COLORS.orangeSoft,
      fontSize: 30,
      fontWeight: 600,
      letterSpacing: 1,
    }}
  >
    {children}
  </div>
);

/** B 站封面：1920×1080 */
export const Cover: React.FC = () => (
  <AbsoluteFill
    style={{
      backgroundColor: COLORS.bg,
      fontFamily: FONT,
      color: COLORS.text,
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
    }}
  >
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(58% 52% at 50% 40%, rgba(250,115,23,0.30) 0%, rgba(250,115,23,0) 72%)",
      }}
    />

    <div style={{ display: "flex", alignItems: "center", gap: 46 }}>
      <Img
        src={staticFile("appicon.png")}
        style={{
          width: 190,
          height: 190,
          borderRadius: 44,
          display: "block",
          boxShadow: "0 40px 100px rgba(250,115,23,0.40)",
        }}
      />
      <div>
        <div
          style={{
            fontSize: 150,
            fontWeight: 700,
            letterSpacing: 12,
            lineHeight: 1,
          }}
        >
          周目
        </div>
        <div
          style={{
            marginTop: 16,
            fontSize: 40,
            color: COLORS.textDim,
            letterSpacing: 4,
          }}
        >
          开学第几周，打开就知道
        </div>
      </div>
    </div>

    <div style={{ height: 64 }} />

    <div style={{ display: "flex", gap: 22 }}>
      <Pill>开学周目</Pill>
      <Pill>课表</Pill>
      <Pill>桌面小组件</Pill>
    </div>

    <div
      style={{
        marginTop: 54,
        fontSize: 34,
        fontWeight: 600,
        color: COLORS.orange,
        letterSpacing: 2,
      }}
    >
      免费开源 · 附完整安装教程
    </div>
  </AbsoluteFill>
);
