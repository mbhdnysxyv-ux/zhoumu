import React from "react";
import { Composition, Sequence } from "remotion";
import { FPS, SCENES, TOTAL_FRAMES } from "./theme";
import { Intro } from "./scenes/Intro";
import { Problem } from "./scenes/Problem";
import { FeatureHome } from "./scenes/FeatureHome";
import { FeatureSchedule } from "./scenes/FeatureSchedule";
import { FeatureWidget } from "./scenes/FeatureWidget";
import { Install } from "./scenes/Install";
import { Outro } from "./scenes/Outro";
import { Cover } from "./Cover";

/** 整支片子：7 个场景按时间轴顺序拼接 */
const ZhoumuIntro: React.FC = () => {
  return (
    <>
      <Sequence from={SCENES.intro.from} durationInFrames={SCENES.intro.dur}>
        <Intro duration={SCENES.intro.dur} />
      </Sequence>

      <Sequence from={SCENES.problem.from} durationInFrames={SCENES.problem.dur}>
        <Problem duration={SCENES.problem.dur} />
      </Sequence>

      <Sequence from={SCENES.home.from} durationInFrames={SCENES.home.dur}>
        <FeatureHome duration={SCENES.home.dur} />
      </Sequence>

      <Sequence
        from={SCENES.schedule.from}
        durationInFrames={SCENES.schedule.dur}
      >
        <FeatureSchedule duration={SCENES.schedule.dur} />
      </Sequence>

      <Sequence from={SCENES.widget.from} durationInFrames={SCENES.widget.dur}>
        <FeatureWidget duration={SCENES.widget.dur} />
      </Sequence>

      <Sequence from={SCENES.install.from} durationInFrames={SCENES.install.dur}>
        <Install duration={SCENES.install.dur} />
      </Sequence>

      <Sequence from={SCENES.outro.from} durationInFrames={SCENES.outro.dur}>
        <Outro duration={SCENES.outro.dur} />
      </Sequence>
    </>
  );
};

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="ZhoumuIntro"
        component={ZhoumuIntro}
        durationInFrames={TOTAL_FRAMES}
        fps={FPS}
        width={1920}
        height={1080}
      />
      {/* B 站封面，单独渲染一张静态图 */}
      <Composition
        id="ZhoumuCover"
        component={Cover}
        durationInFrames={1}
        fps={FPS}
        width={1920}
        height={1080}
      />
    </>
  );
};
