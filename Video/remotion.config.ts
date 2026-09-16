import { Config } from "@remotion/cli/config";

Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
// 画质：keynote 风格的渐变和文字边缘，用较高的质量
Config.setCrf(16);

// 不要下载 Remotion 自带的 Chrome Headless Shell（几百 MB，而且默认下到工作区外），
// 直接用系统装的 Google Chrome。
Config.setBrowserExecutable(
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
);
