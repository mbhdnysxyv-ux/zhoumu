# 周目 · 介绍视频

用 [Remotion](https://remotion.dev) 做的 90 秒介绍片，苹果发布会风格（深色背景 + 橙色光晕 + 弹性入场动画）。
内容包含：软件介绍 → 功能演示 → 完整安装教程 → 结尾。

## 产物

| 文件 | 规格 |
| --- | --- |
| `out/ZhouMu-intro.mp4` | 1920×1080 / 30fps / 90.0 秒 / H.264 / 约 6.3 MB / 无音轨 |
| `out/cover.png` | 1920×1080，B 站封面 |

## 重新生成

```bash
cd Video
npm install                     # 首次
npm run render                  # 渲染终版 → out/ZhouMu-intro.mp4

npx remotion still ZhoumuCover out/cover.png   # 只要封面
npx remotion studio                            # 打开预览界面，可逐帧调
```

想快速看效果（低码率、小尺寸，约 4 分钟）：

```bash
npx remotion render ZhoumuIntro out/draft.mp4 --scale=0.25 --crf=34
```

> **注意**：`remotion.config.ts` 里指定了用系统装的 Google Chrome
> （`/Applications/Google Chrome.app/...`），这样就不用下 Remotion 自带的 Headless Shell。
> 换电脑记得确认这个路径存在。

## 结构

```
src/
  theme.ts            配色、字体、时间轴（所有场景的起止帧都在这）
  anim.tsx            动画基元：FadeUp / ScaleIn / SceneShell / PhoneShot
  ScheduleTable.tsx   课表（在视频里直接画的，不是截图，方便做逐格动画）
  Cover.tsx           B 站封面
  Root.tsx            把 7 个场景按时间轴拼起来
  scenes/
    Intro.tsx           开场：图标弹入 + 应用名
    Problem.tsx         提出问题 → 给出答案（第 4 周 + 循环 3 周 → 第 1 周）
    FeatureHome.tsx     主界面：真实截图 + 三条标注
    FeatureSchedule.tsx 课表：画出 N 排 × 7 列并逐格填满
    FeatureWidget.tsx   桌面小组件
    Install.tsx         安装教程 7 步（带进度条）
    Outro.tsx           仓库地址
```

改时长就改 `theme.ts` 里的 `SCENES`，每个场景的 `from` / `dur` 都在那，`TOTAL_FRAMES` 会自动跟着算。

## 素材

`public/` 里的图都是真实产物，不是示意：

- `appicon.png` —— App 图标（`Tools/make_icon.swift` 生成）
- `home.png` —— **真机模拟器截图**（iPhone 17 Pro Max 尺寸），圈内显示「周三 / 英语」
- `settings.png` —— 同上的设置页截图
- `widget-small.png` / `widget-medium.png` —— 小组件离屏渲染图

> `home.png` / `settings.png` 是模拟器真截图。早期版本用的是离屏渲染 harness 出的图，
> 那种图上会有 AppKit 控件的黄色占位块，已经全部换掉了。

## 发布到 B 站

**分区**：科技 ▸ 软件应用

**标题建议**：

```
【开源】iPhone 开学周目 App：打开就知道第几周，还能按周目排课表
```

**简介**：

```
一个极简的 iPhone 小工具：打开就知道今天是开学第几周、今天上什么课。

✨ 功能
· 打开直接显示今天是第几周，圈内是今天要上的科目
· 按「周目循环」排课表：N 排（N = 循环周数）× 周一至周日
· 桌面小组件（小号 / 中号），不打开 App 也能看到
· 第一次启动、以及每年 1 月 / 7 月自动弹出设置，方便设新学期
· 不联网、不要账号、不收集任何数据

📦 开源免费
GitHub：https://github.com/mbhdnysxyv-ux/zhoumu
源码、图文安装说明、打包好的 IPA 都在仓库里。

⚠️ 安装说明
需要自己签名，免费 Apple ID 即可，需要一台电脑。
完整步骤从视频 00:40 开始，仓库里也有图文版。
免费账号签的 App 7 天后会失效，重新签一次就好，数据不会丢。

#iOS #开源 #效率工具 #学生党 #课表
```

**标签**：`iOS` `开源` `效率工具` `iPhone` `课表` `学生党` `校园` `SwiftUI` `小组件`

**时间轴**（方便在评论区置顶导航）：

| 时间 | 内容 |
| --- | --- |
| 00:00 | 开场 |
| 00:05 | 它是怎么算的 |
| 00:13 | 主界面 |
| 00:22 | 课表 |
| 00:32 | 桌面小组件 |
| 00:40 | 安装教程（7 步） |
| 01:22 | 结尾 |

## 音乐

视频**没有音轨** —— 避免用版权音乐被 B 站限流。
建议在 B 站发布时直接用平台的「背景音乐」功能加，或者在剪辑软件里配一首无版权音乐。
