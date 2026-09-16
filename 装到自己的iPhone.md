# 把「周目」装到你自己的 iPhone 上

> 用**免费 Apple ID** 就能装，不需要 99 美元开发者账号。
> 唯一的代价：**7 天后 App 会打不开，重新 ⌘R 一次即可**（设置和数据不会丢）。

先检查一下还缺什么，两种方式任选：

**方式 A（推荐，不用懂终端）**：在访达里找到工程文件夹，**双击 `检查iPhone.command`**。
它会自动跑检查并把结果留在窗口里（不会一闪而过）。

**方式 B（终端）**：

```bash
./Tools/device_check.sh
```

> ⚠️ 不要用「双击 `Tools/device_check.sh`」的方式跑 —— 脚本执行完终端会话立刻结束，
> 你会只看到一句「A session ended very soon after starting」而看不到结果。
> 那个提示的意思是「会话刚启动就结束了」，不是脚本有错。

---

## 前置条件

- [ ] 一台 Mac（已装 Xcode）
- [ ] 一根数据线
- [ ] 你的 Apple ID（**免费账号即可**，不用买开发者计划）
- [ ] iPhone 系统 **iOS 17 或更高**

---

## 第 1 步：连上 iPhone

1. 用数据线把 iPhone 接到 Mac
2. iPhone 上会弹「要信任此电脑吗？」→ 点 **信任**，输入锁屏密码
3. 如果没弹窗，拔掉重插一次

验证：`./Tools/device_check.sh` 的 ① 应该能看到你的设备。

## 第 2 步：在 Xcode 里登录 Apple ID

1. 打开 Xcode
2. 菜单 **Xcode ▸ Settings…**（或按 `⌘,`）
3. 选 **Accounts** 标签 → 左下角 **+** → **Apple ID** → 登录

> 登录后 Xcode 会自动帮你生成一张 **Apple Development** 证书，不用手动去搞证书和描述文件。

验证：`./Tools/device_check.sh` 的 ② 应该能看到证书。

## 第 3 步：选签名团队

工程里**没有写死 Team ID**（方便别人 clone 后用自己的账号），所以这一步需要你自己选一次：

1. 打开工程：`open ZhouMu.xcodeproj`
2. 左侧点最上面的 **ZhouMu** 项目 → 中间选 **TARGETS ▸ ZhouMu** → **Signing & Capabilities**
3. 勾上 **Automatically manage signing**，**Team** 选 `你的名字 (Personal Team)`
4. 再对 **TARGETS ▸ ZhouMuWidget** 做同样操作

> ⚠️ **两个 target 都要选同一个 Team**，否则小组件会报 `requires a development team`。
>
> 选一次之后 Xcode 会记住（存在本地的 `xcuserdata` 里，不会进 git）。
>
> 如果这里出现 **App Groups 相关的红色错误**，点一下 **Fix Issue** 就行 ——
> 工程用了 App Group 让 App 和小组件共享设置，而这个能力需要 Xcode 帮你注册到开发者账号。

## 第 4 步：如果报 Bundle ID 冲突

如果 Xcode 报：

> Failed to register bundle identifier — The app identifier "com.zhoumu.weekdisplay" cannot be registered to your development team because it is not available.

说明这个 Bundle ID **已经被别人占用了**（Bundle ID 全球唯一）。改一个地方就行：

打开 `ZhouMu.xcodeproj/project.pbxproj`，找到：

```
APP_BUNDLE_ID = com.zhoumu.weekdisplay;
```

改成带你自己的，例如：

```
APP_BUNDLE_ID = com.yourname.zhoumu;
```

**App 和小组件会自动同步改成 `com.yourname.zhoumu` 和 `com.yourname.zhoumu.widget`**，不用改两处。

## 第 5 步：选设备、按 ⌘R

1. Xcode 顶部中间那个设备下拉框里，选中**你的 iPhone**
2. 按 **⌘R**（或点左上角 ▶）

第一次会慢一些（要生成签名、编译 App 和小组件）。

## 第 6 步：在 iPhone 上开启「开发者模式」

iOS 16 以后必须开，否则 App 装上后点不开。

装完后 iPhone 上会提示，或者手动开：

**设置 ▸ 隐私与安全性 ▸ 开发者模式** → 打开 → **重启手机** → 重启后点「打开」

## 第 7 步：信任开发者证书

**设置 ▸ 通用 ▸ VPN与设备管理** → 找到你的 Apple ID（显示为「开发者 App」）→ **信任**

（没有这步的话，点 App 图标会提示「未受信任的开发者」）

## 第 8 步：打开 App，添加桌面小组件

1. 先**打开一次 App**（让系统注册小组件）
2. 回到桌面，长按空白处 → 左上角 **+** → 搜索「周目」
3. 选小号或中号 → 添加
4. **长按小组件 ▸ 编辑小组件** → 设置开学日期、循环周数

> 小组件的日期是**在小组件上单独设置**的，不跟 App 里的设置联动。
> 这是刻意的设计：为了让你用免费 Apple ID 也能装上，没有使用 App Group（详见 README）。

---

## 7 天到期了怎么办

免费账号签出来的 App **只有 7 天有效期**。到期后：

- App 点不开（提示「不再可用」）
- 小组件停止更新

**解决办法：把 iPhone 连上 Mac，在 Xcode 里再按一次 ⌘R。** 数据不会丢，设置还在。

> 想省事的话，可以每次到期就 ⌘R 一次；或者接受 99 美元/年的开发者账号（那样是 1 年有效）。

---

## 常见报错对照表

| 报错 | 原因 | 怎么办 |
| --- | --- | --- |
| `Failed to register bundle identifier` | Bundle ID 被别人占用 | 改 `APP_BUNDLE_ID`（第 4 步） |
| `No signing certificate found` | 没登录 Apple ID 或没选 Team | 做第 2、3 步 |
| `Signing for "ZhouMuWidget" requires a development team` | 小组件那个 target 没选 Team | 第 3 步的第 6 小点 |
| 手机上提示「未受信任的开发者」 | 没信任证书 | 第 7 步 |
| App 装上但点开就闪退 / 打不开 | 没开开发者模式 | 第 6 步 |
| `Unable to install — maximum number of apps` | 免费账号最多同时装 3 个自签 App | 删掉别的自签 App |
| `This app is no longer available` | 7 天到期了 | 重新 ⌘R |
| 桌面小组件里搜不到「周目」 | 没启动过 App | 先打开一次 App |
| `Provisioning profile doesn't support the App Groups capability` | 不会出现（本项目没用 App Group） | —— |

---

## 免费账号的限制（提前知道）

| 限制 | 具体 |
| --- | --- |
| 有效期 | 7 天，到期要重新 ⌘R |
| 同时安装 | 最多 3 个自签 App |
| App ID | 每 7 天最多注册 10 个 |
| 设备 | 只能装到你自己的设备 |
| 分发 | **不能**用 TestFlight、不能上架 App Store |

想要「发给别人、永久有效」就得上付费账号，见 **[发布到TestFlight.md](发布到TestFlight.md)**。
如果只是想「让更多人能用」，「发布到TestFlight.md」里提到的**网页版**方案可能更合适（零成本、秒开、安卓也能用）。
