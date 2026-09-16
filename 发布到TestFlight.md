# 发布到 TestFlight，并分享给任何人下载

> 面向场景：把「周目」发给 B 站观众，任何人点链接就能装。

---

> ⚠️ **如果你不打算买开发者账号（99 美元/年）**，请先看这一节 —— 它决定了整份文档对你还适不适用。
>
> **TestFlight 和上架 App Store 都必须有付费开发者账号**（Apple Developer Program）。
> 免费 Apple ID 拿不到这两个功能，所以**「发一条链接、任何人点开就能装」在没有付费账号时做不到**。
> 这是 Apple 的硬性规定，没有合法绕过的办法。

## 零分之一、不买开发者账号：能做什么、不能做什么

| | 能不能做 | 说明 |
| --- | --- | --- |
| 装到**你自己**的 iPhone | ✅ 能 | Xcode + 免费 Apple ID，7 天有效，到期重新 ⌘R 一次即可 |
| 装到**别人**的 iPhone | ⚠️ 能但很麻烦 | 对方要有电脑 + 自己的免费 Apple ID，用 Sideloadly/AltStore 签一次，**7 天后失效要重签** |
| TestFlight 公开链接 | ❌ 不能 | 必须付费账号 |
| 上架 App Store | ❌ 不能 | 必须付费账号 |
| TrollStore 免签名永久安装 | ❌ 基本不能 | TrollStore 只支持到 iOS 17.0 且限特定机型/版本，**你在 iOS 17+ 用不了** |

### 对「发到 B 站」这件事的现实判断

- 想让观众用上，只能把**工程 + 无签名 IPA** 一起发出去，让懂 sideload 的人自己签。
  门槛高（要有电脑、要会装 AltStore/Sideloadly）、而且**每 7 天就要重签一次**，
  对普通观众基本不可用，还会带来一堆「怎么打不开」的私信。
- 顺带一提：**别用企业证书**（Enterprise，299 美元/年）去公开分发。Apple 会直接吊销，
  你分享出去的 App 会集体失效。

### 更值得考虑的方案：做成网页版

「周目」的全部逻辑就是「开学日期 + 循环周数 → 今天是第几周」，这是一个**纯计算**。

如果做成一个网页，那么：**任何人用手机浏览器点开就能用，不用安装、不用签名、不用付费、永久有效，而且安卓用户也能用。**

对「让 B 站观众都能用上」这个目标来说，网页版比 iOS App 合适得多 —— iOS App 的价值主要在于**桌面小组件**和原生体验。
（需要的话我可以直接把这个网页版做出来，逻辑代码可以直接复用。）


## 零、打包 IPA 和装到实体机

### 已经打好的 IPA（两个，用途不同）

| 文件 | 大小 | 状态 | 用途 |
| --- | --- | --- | --- |
| `build/ZhouMu-1.0-unsigned.ipa` | 194 KB | **完全未签名**，无描述文件 | **自签工具的输入**（Sideloadly / AltStore / ESign / 爱思等） |
| `build/ZhouMu-1.0-signed.ipa` | 163 KB | 已用你的证书签名 | 直接装你自己手机（描述文件里已含你的 UDID） |

重新打包：

```bash
./Tools/make_ipa.sh                                  # 无签名 IPA
TEAM_ID=你的TeamID ./Tools/make_ipa.sh --signed         # 已签名 IPA（需要开发者账号）
```

### ⚠️ 用自签工具时最重要的一点：小组件

这个 App 内含一个小组件扩展 `Payload/ZhouMu.app/PlugIns/ZhouMuWidget.appex`。

**自签工具必须把 appex 也一起重新签名。** 只签主 App 的话，要么装不上（嵌入二进制校验失败），
要么装上了但小组件不可用。

Sideloadly、AltStore、ESign 这类成熟工具会自动处理子扩展；一些简易工具只签主二进制。

**验证方法**：装完后长按桌面空白处 ▸ 「+」搜「周目」——
**能搜到就说明 appex 被正确重签了**，搜不到就是没签上。

> 关于有效期：用免费 Apple ID 自签**仍然是 7 天**，和 Xcode 一样，不会变长。
> 自签工具里那些「企业证书」能到 1 年，但那属于 Apple 明令禁止的用途，
> 证书随时会被吊销、所有装过的人会一起失效 —— 不建议使用。

> 装好之后，桌面上长按空白处 ▸ 左上角「+」▸ 搜索「周目」就能添加小组件。
> 小组件的开学日期是**在小组件上单独设置**的：长按小组件 ▸ 编辑小组件。
> （原因见 README：为了让你用免费 Apple ID 也能装上，刻意没有使用 App Group。）

### ⚠️ 先说清楚：这个 IPA 不能直接双击安装

iOS 要求所有 App 必须被签名。这台 Mac 上**没有任何代码签名证书**（`security find-identity` 返回 0 个），所以打出来的是**无签名 IPA**——它必须先被「你自己的 Apple ID」重新签名，才能装进 iPhone。这是 Apple 的限制，不是打包没打对。

### 选一条路

| 方式 | 需要什么 | 有效期 | 适合 |
| --- | --- | --- | --- |
| **Xcode 直接运行** ⭐ | Mac + Xcode + 免费 Apple ID + 数据线 | 7 天 | **自己用，最省事，连 IPA 都不用** |
| Sideloadly / AltStore / SideStore | 电脑 + 免费 Apple ID | 7 天 | 用上面这个 IPA 装 |
| Ad-Hoc 签名 IPA | 付费账号 + 登记设备 UDID | 1 年 | 固定几台设备长期用 |
| TrollStore | iOS 版本在支持范围内 | 永久 | 免签名，看机型/版本运气 |
| TestFlight | 付费账号 | 90 天 | 发给别人（见下文） |

### 路线 A：Xcode 直接运行（自用首选，不用 IPA）

1. 数据线连上 iPhone，手机上点「信任此电脑」
2. **Xcode ▸ Settings ▸ Accounts** 登录你的 Apple ID（免费账号就行）
3. 项目里选中 **ZhouMu** target ▸ **Signing & Capabilities** ▸ **Team** 选你的 Personal Team
4. Xcode 顶部设备选你的 iPhone，按 **⌘R**
5. 手机上：**设置 ▸ 隐私与安全性 ▸ 开发者模式** → 打开 → 重启手机（iOS 16+ 必须）
6. **设置 ▸ 通用 ▸ VPN与设备管理** → 信任你的开发者证书
7. 打开「周目」

> 免费账号装的 App **7 天后打不开**，重新插线 ⌘R 一次就好（数据不会丢）。

### 路线 B：用这个 IPA 安装（Sideloadly / AltStore）

- **Sideloadly**（Mac / Windows）：连上手机 → 把 `build/ZhouMu-1.0-unsigned.ipa` 拖进去 → 填 Apple ID → Start
- **AltStore / SideStore**：先在手机装好 AltStore，再用它打开这个 IPA
- 同样受 7 天限制，需要定期刷新；免费账号同时最多 3 个自签 App

### 路线 C：Ad-Hoc 签名 IPA（付费账号，1 年有效）

1. 先在 App Store Connect / Xcode 里**登记设备 UDID**（付费账号每年限 100 台）
2. 打包签名版本：
   ```bash
   TEAM_ID=你的TeamID ./Tools/make_ipa.sh --signed
   ```
3. 产物 `build/ZhouMu-signed/ZhouMu.ipa`，用 Finder 或 Apple Configurator 拖进手机即可

### 路线 D：TrollStore

如果你的 iOS 版本在 TrollStore 支持范围内，可以直接用它打开这个无签名 IPA，**免签名、永久有效**。能不能用取决于机型 + 系统版本。


## 一、先看结论：能做，但有 4 个硬限制

| 限制 | 具体是什么 | 对你的影响 |
| --- | --- | --- |
| **必须付费账号** | Apple Developer Program，**99 美元/年** | 免费 Apple ID **完全用不了** TestFlight |
| **构建 90 天过期** | 上传的构建从上传日算起只有 **90 天**寿命 | 到期后所有人打开都提示「Beta 已过期」，**必须重新上传**（见第五节） |
| **上限 1 万人** | 单个 App 的外部测试者最多 10,000 人 | 对 B 站分享够用，但到顶就得转上架 |
| **要过一次审核** | 外部测试需要 Beta App Review | 通常比正式上架快，但**仍可能被拒**（见第七节） |

另外：测试者需要先装 **TestFlight** App（App Store 免费），且系统 **iOS 17 或更高**（因为「周目」最低支持 iOS 17）。

**如果你想要「永久、无需续期、谁都能下」** —— 那正确答案是**上架 App Store**（免费 App 也能上架），TestFlight 本质是测试通道。建议：**先用 TestFlight 快速发出去收集反馈，同时准备上架**。

## 二、免费账号 vs 付费账号

| | 免费 Apple ID | 付费开发者账号 |
| --- | --- | --- |
| 装到自己手机 | ✅ 可以，但 **7 天**就失效，要重新装 | ✅ 一年有效 |
| 同时装的 App 数 | 最多 3 个 | 不限 |
| TestFlight 分发 | ❌ 不支持 | ✅ |
| 上架 App Store | ❌ | ✅ |

所以**「自己先装到实体机上用」** 免费账号就够了（下一节）；**「分享给任何人」** 必须付费。

## 三、项目里已经帮你准备好的东西

- ✅ **App 图标**（1024×1024，TestFlight 强制要求，缺了会被拒）
- ✅ **隐私清单** `ZhouMu/PrivacyInfo.xcprivacy`
  声明了 UserDefaults 的必要理由（`CA92.1`），不做追踪、不收集数据。
  从 2024 年起缺这个可能收到 `ITMS-91053` 警告。
- ✅ **出口合规** `ITSAppUsesNonExemptEncryption = NO`
  已写进构建设置，**上传时不会再被问加密问题**，也避免每次都要在 App Store Connect 手点。
- ✅ **版本号**：版本 `1.0`，构建号由脚本用**时间戳自动递增**（每次上传必须是没用过的构建号）
- ✅ **一键归档上传脚本** `Tools/release.sh` + `Tools/ExportOptions.plist`

## 四、你需要做的（按顺序）

### 1. 注册开发者账号

到 <https://developer.apple.com/programs/> 用你的 Apple ID 注册，付 99 美元/年。
个人账号即可（不需要公司）。审核通过后收到邮件，才能在 App Store Connect 建 App。

### 2. 改 Bundle ID（很可能必须改）

当前是 `com.zhoumu.weekdisplay`。**Bundle ID 全球唯一**，如果被别人占了你就用不了。建议改成带你自己的标识，比如 `com.yourname.zhoumu`。

改两个地方（两处都要改成一样的）：
- Xcode：选中 **ZhouMu** target ▸ **Signing & Capabilities** ▸ **Bundle Identifier**
- 或直接改 `ZhouMu.xcodeproj/project.pbxproj` 里的 `PRODUCT_BUNDLE_IDENTIFIER`（Debug / Release 各一处）

### 3. Xcode 里登录账号、选团队

**Xcode ▸ Settings ▸ Accounts ▸ 加号 ▸ 登录你的 Apple ID**，然后选中 **ZhouMu** target ▸ **Signing & Capabilities** ▸ **Team** 选你的团队，勾上 **Automatically manage signing**。

顺手记下你的 **Team ID**（10 位，形如 `ABCDE12345`），后面脚本要用。

### 4. 在 App Store Connect 建 App 记录

<https://appstoreconnect.apple.com> ▸ **我的 App** ▸ **+** ▸ **新建 App**：

| 字段 | 填什么 |
| --- | --- |
| 平台 | iOS |
| 名称 | 周目（这个名字在 App Store 上也要唯一，被占就换，如「周目 · 开学周数」） |
| 主要语言 | 简体中文 |
| Bundle ID | 选第 2 步那个 |
| SKU | 随便填，比如 `zhoumu001`（内部用，不对外） |
| 用户访问权限 | 完全访问 |

### 5. 归档并上传

**命令行（推荐，构建号自动递增）：**

```bash
TEAM_ID=你的TeamID ./Tools/release.sh
```

**或者用 Xcode 图形界面：**

**Product ▸ Archive** → 等归档完 → 在 Organizer 里点 **Distribute App** → **TestFlight & App Store** → **Upload**。

上传后需要等 Apple 处理（几分钟到几十分钟），处理完会给你发邮件。

### 6. 在 App Store Connect 配置 TestFlight

进入 **你的 App ▸ TestFlight**：

1. **测试信息**（必填，Beta 审核要看）：
   - **测试内容说明**：写清楚这个版本让测试者重点试什么
   - **反馈邮箱**：你的邮箱
   - **What to Test**：同上，可写「请测试开学日期与周目循环设置是否正确」
   - **联系信息**
2. **出口合规**：因为 Info.plist 已经声明了，通常这里直接是「无需提供文档」
3. 构建那一行点 **提交审核**（Beta App Review）

### 7. 审核通过 → 开启公开链接

构建状态变成「已通过审核」后：

**TestFlight ▸ 外部测试 ▸ 你的测试组 ▸ 公开链接 ▸ 启用**

可以设置人数上限（不超过 1 万）。拿到形如 `https://testflight.apple.com/join/xxxxxxx` 的链接。

**把这个链接发到 B 站即可** —— 任何人点开、装 TestFlight、就能装「周目」，不需要你收集任何人的 Apple ID / 邮箱。

## 五、90 天续期（B 站分享最关键的坑）

**TestFlight 构建只有 90 天寿命，到期后所有测试者打开都会提示「Beta 已过期」，链接也就废了。**

续期流程很简单，**链接不用换、测试者不用重新加**：

```bash
TEAM_ID=你的TeamID ./Tools/release.sh   # 构建号会自动变成新时间戳
```

然后在 App Store Connect ▸ TestFlight ▸ 提交这个新构建审核，通过后测试者会在 TestFlight 里直接看到更新。

几点经验：
- **同一版本号（1.0）下追加构建，一般不需要重新走 Beta 审核**，但要按 App Store Connect 的实际提示为准；如果要求审核，走一遍即可。
- **提前续期**：别卡在第 90 天，建议**到期前 1~2 周**就传新的。审核偶尔会排队。
- **长期方案**：如果打算长期给别人用，还是上架 App Store 更省心 —— 上架后没有 90 天限制，也不用反复续期。

## 六、B 站分享建议

- **置顶评论/简介**里写清楚三步：
  > 1. 先在 App Store 装 **TestFlight**
  > 2. 点这个链接加入测试：https://testflight.apple.com/join/xxxxxxx
  > 3. 在 TestFlight 里点「安装」
  > （需要 iOS 17 以上；测试版有效期 90 天，到期我会更新）
- **主动说明 90 天有效期**，避免观众过了几个月来问「怎么打不开了」。
- 视频里可以演示：装好后打开就是「第 N 周」→ 进设置改开学日期和循环周数 → 回来立刻变。
- 记得在视频里提一句**数据只存在本机、不联网、不收集任何信息**（这个 App 确实如此，隐私清单也是这么写的）。

## 七、审核被拒的风险（提前知道）

**最大风险：App Review 指南 4.2「最低功能性」**（Minimum Functionality）。「周目」只有一个界面，审核员有可能认为功能过于简单而拒绝（TestFlight 的 Beta 审核和正式上架都会看这一条）。

降低风险的办法，任选几个加上去：
- **桌面小组件（WidgetKit）**：不打开 App 就能在桌面看到「第 N 周」—— 对这个 App 来说是最自然的补充，也最能提升实用性
- **每周一自动提醒**（本地通知）：周目变化时提醒
- **多个学期管理**：可以保存历史学期
- **周目进度/学期进度**可视化

另外几条别踩：
- 不要用别人的图标、名称、品牌素材
- App 内不要有隐藏功能或与描述不符的内容
- 免费 App 也要有完整可用的功能，不能是「占位版」

需要的话我可以帮你把 **桌面小组件** 做出来 —— 这对通过审核帮助最大。

## 八、几种分发方式对比

| 方式 | 谁能装 | 有效期 | 成本 | 适合 |
| --- | --- | --- | --- | --- |
| 免费账号自签 | 只有自己 | 7 天 | 免费 | 自己先用起来 |
| **TestFlight 公开链接** | **任何人（上限 1 万）** | **90 天，需续期** | **99 美元/年** | **你现在这个需求** |
| **App Store 上架** | **任何人** | **永久** | **99 美元/年** | **长期公开分享（推荐终点）** |
| Ad-Hoc / 自签工具 | 需登记 UDID，每年限 100 台 | 1 年 | 99 美元/年 | 小圈子内测 |
| ❌ 企业证书（Enterprise） | —— | —— | 299 美元/年 | **不能用于公开分发**，Apple 会吊销证书，别碰 |

## 九、常见问题

**Q：上传后一直没出现在 TestFlight？**
A：构建需要先「处理」，几分钟到几十分钟。状态在 App Store Connect ▸ TestFlight 里看，处理完会发邮件。如果卡很久，检查邮箱有没有收到「缺少出口合规信息」之类的邮件。

**Q：提示「无法添加构建版本」/ ITMS 报错？**
A：常见原因是**构建号重复**（换成更大的数字）、图标缺失、或缺少隐私清单。本项目这三点都已处理。

**Q：测试者说装不上？**
A：确认对方系统 ≥ iOS 17、装了 TestFlight、并且是用你的公开链接加入的。有时需要重启 TestFlight。

**Q：能收钱吗？**
A：这个 App 没必要。免费 App 也能上架和 TestFlight 分发。

**Q：一定要 99 美元吗？**
A：要。TestFlight 属于开发者计划的功能，免费 Apple ID 拿不到。
