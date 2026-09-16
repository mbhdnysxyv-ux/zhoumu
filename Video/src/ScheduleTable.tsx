import React from "react";
import { spring, useCurrentFrame, useVideoConfig } from "remotion";
import { COLORS, FONT } from "./theme";

const DAYS = ["一", "二", "三", "四", "五", "六", "日"];

/** 示例课表：3 排（循环 3 周）× 周一至周日 */
const ROWS: string[][] = [
  ["数学", "语文", "英语", "物理", "化学", "", ""],
  ["历史", "", "地理", "", "政治", "", "体育"],
  ["", "生物", "", "美术", "", "音乐", ""],
];

/** 今天：第 1 排 · 周三（星期三） */
const TODAY = { row: 0, col: 2 };

const CELL_W = 76;
const CELL_H = 56;

const Cell: React.FC<{
  text: string;
  delay: number;
  highlight: boolean;
  highlightP: number;
}> = ({ text, delay, highlight, highlightP }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({
    frame: frame - delay,
    fps,
    config: { damping: 16, mass: 0.6, stiffness: 130 },
  });
  const filled = text.length > 0;

  return (
    <div
      style={{
        width: CELL_W,
        height: CELL_H,
        borderRadius: 14,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 21,
        fontWeight: filled ? 600 : 400,
        backgroundColor: filled ? "rgba(250,115,23,0.16)" : "rgba(255,255,255,0.045)",
        color: filled ? COLORS.orangeBright : COLORS.textFaint,
        border: highlight
          ? `2px solid rgba(250,115,23,${highlightP})`
          : "2px solid transparent",
        opacity: p,
        transform: `scale(${0.72 + 0.28 * p})`,
      }}
    >
      {filled ? text : "·"}
    </div>
  );
};

/** 课表：在视频里直接画出来，比截图更清楚，也方便做逐个格子的入场动画 */
export const ScheduleTable: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const cardP = spring({
    frame,
    fps,
    config: { damping: 200, mass: 0.8, stiffness: 90 },
  });

  // 所有格子填完之后，再把"今天"那一格描上橙边
  const lastCellDelay = 14 + (ROWS.length * 7 - 1) * 2.2;
  const highlightP = spring({
    frame: frame - lastCellDelay - 14,
    fps,
    config: { damping: 200, mass: 0.5, stiffness: 120 },
  });

  return (
    <div
      style={{
        opacity: cardP,
        transform: `translateY(${(1 - cardP) * 44}px) scale(${0.94 + 0.06 * cardP})`,
        padding: "34px 36px 30px",
        borderRadius: 34,
        backgroundColor: COLORS.bgCard,
        border: `1px solid ${COLORS.line}`,
        boxShadow: "0 54px 140px rgba(0,0,0,0.62)",
        fontFamily: FONT,
      }}
    >
      {/* 表头：周一 … 周日 */}
      <div style={{ display: "flex", gap: 10, marginBottom: 16, paddingLeft: 62 }}>
        {DAYS.map((d) => (
          <div
            key={d}
            style={{
              width: CELL_W,
              textAlign: "center",
              fontSize: 22,
              fontWeight: 600,
              color: COLORS.textDim,
            }}
          >
            {d}
          </div>
        ))}
      </div>

      {/* 每一排 = 一个周目 */}
      {ROWS.map((row, r) => (
        <div
          key={r}
          style={{
            display: "flex",
            gap: 10,
            alignItems: "center",
            marginBottom: 10,
          }}
        >
          <div
            style={{
              width: 52,
              fontSize: 22,
              fontWeight: 700,
              color: COLORS.orange,
            }}
          >
            {r + 1}周
          </div>
          {row.map((cell, c) => (
            <Cell
              key={c}
              text={cell}
              delay={14 + (r * 7 + c) * 2.2}
              highlight={r === TODAY.row && c === TODAY.col}
              highlightP={highlightP}
            />
          ))}
        </div>
      ))}
    </div>
  );
};
