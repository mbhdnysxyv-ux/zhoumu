import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { COLORS } from "../theme";
import { FadeUp, Headline, Kicker, SceneShell, useSpringIn } from "../anim";

type Step = {
  title: string;
  desc: string;
  /** 需要强调的界面路径，会以胶囊样式显示 */
  path?: string;
  note?: string;
};

const STEPS: Step[] = [
  {
    title: "下载 IPA 安装包",
    desc: "打开项目的 GitHub 页面，进入 Releases，下载最新的无签名 IPA。",
    path: "GitHub ▸ Releases ▸ ZhouMu-1.2-unsigned.ipa",
  },
  {
    title: "准备一个自签工具",
    desc: "手机没法直接装无签名包，需要借助电脑上的自签工具完成签名。",
    path: "Sideloadly（Windows / macOS）或 AltStore",
  },
  {
    title: "用数据线连上 iPhone",
    desc: "连接后在手机上点「信任此电脑」，并输入锁屏密码。",
    path: "iPhone 弹窗 ▸ 信任",
  },
  {
    title: "把 IPA 拖进工具并签名",
    desc: "填入你的 Apple ID —— 免费账号就够了，不需要开发者计划。",
    path: "Sideloadly 里选好设备 ▸ 拖入 IPA ▸ 输入 Apple ID ▸ Start",
  },
  {
    title: "在手机上信任证书",
    desc: "不信任的话，点 App 图标会提示「未受信任的开发者」。",
    path: "设置 ▸ 通用 ▸ VPN与设备管理 ▸ 信任你的 Apple ID",
  },
  {
    title: "打开开发者模式",
    desc: "iOS 16 以后必须开，否则装好的 App 打不开。开完会要求重启一次。",
    path: "设置 ▸ 隐私与安全性 ▸ 开发者模式",
    note: "如果找不到这一项，先在 Xcode 里连一次手机，或先完成上一步再来",
  },
  {
    title: "打开 App，添加小组件",
    desc: "先在 App 里设好开学日期和课表，然后长按桌面空白处添加小组件。",
    path: "长按桌面 ▸ 左上角 + ▸ 搜索「周目」",
    note: "免费 Apple ID 签的 App 7 天后会失效，重新签一次即可 —— 数据不会丢",
  },
];

const STEP_FRAMES = 165;

/** 安装教程：逐步展示，顶部有进度条 */
export const Install: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const headerFrames = duration - STEPS.length * STEP_FRAMES;

  const rawIndex = Math.floor((frame - headerFrames) / STEP_FRAMES);
  const index = Math.max(0, Math.min(STEPS.length - 1, rawIndex));
  const localFrame = frame - headerFrames - index * STEP_FRAMES;

  const step = STEPS[index];
  const enter = useSpringIn(Math.max(0, localFrame), {
    damping: 200,
    mass: 0.7,
    stiffness: 110,
  });

  const progress = Math.max(
    0,
    Math.min(1, (frame - headerFrames * 0.4) / (duration - headerFrames * 0.4)),
  );

  return (
    <SceneShell duration={duration} glow={0.5} glowY={30}>
      <AbsoluteFill style={{ paddingTop: 74, paddingLeft: 168, paddingRight: 168 }}>
        {/* 顶部标题 + 进度 */}
        <div
          style={{
            display: "flex",
            alignItems: "flex-end",
            justifyContent: "space-between",
          }}
        >
          <div>
            <Kicker>安装教程</Kicker>
            <div style={{ height: 16 }} />
            <div
              style={{
                fontSize: 62,
                fontWeight: 700,
                letterSpacing: -1,
                color: COLORS.text,
              }}
            >
              5 分钟装到手机上
            </div>
          </div>
          <div
            style={{
              fontSize: 30,
              fontWeight: 600,
              color: COLORS.textFaint,
              letterSpacing: 1,
            }}
          >
            <span style={{ color: COLORS.orange, fontSize: 40 }}>
              {index + 1}
            </span>
            {" / "}
            {STEPS.length}
          </div>
        </div>

        {/* 进度条 */}
        <div
          style={{
            marginTop: 30,
            height: 6,
            borderRadius: 3,
            backgroundColor: "rgba(255,255,255,0.10)",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              width: `${progress * 100}%`,
              height: "100%",
              borderRadius: 3,
              backgroundColor: COLORS.orange,
            }}
          />
        </div>

        {/* 当前步骤卡片 */}
        <div
          style={{
            marginTop: 74,
            opacity: enter,
            transform: `translateY(${(1 - enter) * 50}px)`,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 30,
            }}
          >
            <div
              style={{
                width: 96,
                height: 96,
                borderRadius: 28,
                backgroundColor: COLORS.orange,
                color: "#0A0A0C",
                fontSize: 52,
                fontWeight: 700,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
                boxShadow: "0 24px 60px rgba(250,115,23,0.40)",
              }}
            >
              {index + 1}
            </div>
            <div
              style={{
                fontSize: 60,
                fontWeight: 700,
                color: COLORS.text,
                letterSpacing: -0.5,
              }}
            >
              {step.title}
            </div>
          </div>

          <div
            style={{
              marginTop: 40,
              marginLeft: 126,
              fontSize: 32,
              lineHeight: 1.62,
              color: COLORS.textDim,
              maxWidth: 1240,
            }}
          >
            {step.desc}
          </div>

          {step.path ? (
            <div
              style={{
                marginTop: 34,
                marginLeft: 126,
                display: "inline-block",
                padding: "18px 30px",
                borderRadius: 18,
                backgroundColor: COLORS.bgCard,
                border: `1px solid ${COLORS.line}`,
                fontSize: 30,
                fontWeight: 600,
                color: COLORS.orangeSoft,
                letterSpacing: 0.5,
              }}
            >
              {step.path}
            </div>
          ) : null}

          {step.note ? (
            <div
              style={{
                marginTop: 30,
                marginLeft: 126,
                display: "flex",
                alignItems: "center",
                gap: 14,
                fontSize: 26,
                color: COLORS.textDim,
                maxWidth: 1240,
              }}
            >
              <span
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  justifyContent: "center",
                  width: 34,
                  height: 34,
                  borderRadius: 17,
                  backgroundColor: "rgba(250,115,23,0.16)",
                  color: COLORS.orange,
                  fontSize: 22,
                  fontWeight: 700,
                  flexShrink: 0,
                }}
              >
                !
              </span>
              {step.note}
            </div>
          ) : null}
        </div>
      </AbsoluteFill>
    </SceneShell>
  );
};
