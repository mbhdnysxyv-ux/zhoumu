# 发布到 GitHub

从零到「仓库 + Release + IPA 可下载」。所有命令直接复制就能用。

---

## 一、发布前检查（已完成）

- ✅ 工程里**没有写死 Team ID**，别人 clone 后用自己的账号即可
- ✅ 文档里没有你的 Team ID / 邮箱 / 设备 UDID
- ✅ `.gitignore` 已挡住 `build/`、`*.ipa`、`xcuserdata/`、`*.mobileprovision` 等不该提交的东西

---

## 二、登录 GitHub CLI（gh）

`gh` 已经装好了（`/opt/homebrew/bin/gh`），只差登录。

> **为什么要你自己在终端里跑**：这个流程需要你在浏览器里点「授权」，
> 我没法替你点，也没法把浏览器的登录态转过来。

### 方式 A：浏览器授权（推荐）

在你自己的**终端**里执行：

```bash
gh auth login
```

然后按下面这样选（用方向键选、回车确认）：

| 提示 | 选什么 |
| --- | --- |
| What account do you want to log into? | **GitHub.com** |
| What is your preferred protocol for Git operations? | **HTTPS** |
| Authenticate Git with your GitHub credentials? | **Yes** |
| How would you like to authenticate GitHub CLI? | **Login with a web browser** |

接着终端会打印：

```
! First copy your one-time code: 1234-ABCD
Press Enter to open github.com in your browser...
```

**按顺序做：**

1. **先把那串一次性代码抄下来**（形如 `1234-ABCD`）
2. 按 **回车**，浏览器会自动打开 <https://github.com/login/device>
3. 页面上点 **Continue**，粘进刚才的代码，再点 **Continue**
4. 点 **Authorize github**
5. 回到终端，看到 `✓ Logged in as 你的用户名` 就成功了

> 你平时用 Apple ID 登录 GitHub 完全没问题 —— 第 3 步那个页面上直接选
> **Sign in with Apple** 就行。

**想跳过前面几个选择题**，用这一条命令直接进授权：

```bash
gh auth login --hostname github.com --git-protocol https --web
```

### 方式 B：用 Personal Access Token（浏览器打不开时用）

1. 打开 <https://github.com/settings/tokens> → **Generate new token (classic)**
2. 勾选 **repo** 权限即可（建 Release 够用）
3. 生成后复制 token，然后：

```bash
gh auth login --with-token <<< '把token粘在这里'
```

### 验证是否成功

```bash
gh auth status
```

应该看到：

```
github.com
  ✓ Logged in to github.com account <你的用户名>
  ✓ Git operations for github.com configured to use https protocol.
```

### 常见问题

**Q：提示 `Press Enter to open...`，按了没反应？**
A：确保焦点在那个终端窗口里再按回车。还是不行就手动访问 <https://github.com/login/device>。

**Q：一次性代码过期了？**
A：代码约 15 分钟有效。过期就重新跑一次 `gh auth login`，会生成新的。

**Q：想换账号 / 退登？**
A：`gh auth logout` 然后重新登录。

**Q：GitHub 账号还没建？**
A：先去 <https://github.com/signup> 注册，可以用 Apple ID 直接注册。


---

## 三、初始化仓库并推送

```bash
cd "/Users/alex/Documents/周目显示"

git init -b main
git add .

# ⚠️ 先看一眼要提交什么，确认没有意外的大文件或个人信息
git status --short

git commit -m "周目 1.2：开学周目 + 课表 + 桌面小组件"
```

然后建仓库并推上去（仓库名想换就把 `zhoumu` 改掉）：

```bash
gh repo create zhoumu \
  --public \
  --source=. \
  --push \
  --description "开学周目 / 课表 / 桌面小组件 —— 极简 iOS App"
```

推送完打开 `https://github.com/<你的用户名>/zhoumu` 就能看到。

> 想用网页版手工建仓库也行：先在 GitHub 建一个空仓库，
> 然后 `git remote add origin https://github.com/<你的用户名>/zhoumu.git && git push -u origin main`。

---

## 四、建 Release 并把 IPA 传上去

IPA 在 `build/ZhouMu-1.2-unsigned.ipa`。它被 `.gitignore` 挡住了（不进仓库历史），
正好用 `gh release create` 当附件上传：

```bash
gh release create v1.2 \
  build/ZhouMu-1.2-unsigned.ipa \
  --title "周目 1.2" \
  --notes-file RELEASE_NOTES.md
```

建好之后：

- Release 页面可以直接下载 IPA
- README 里的下载链接用的是相对路径 `../../releases/latest`，**会自动指向最新的 Release**，
  以后发新版不用改 README

> 也可以直接在 GitHub 网页上操作：仓库右侧 **Releases** ▸ **Draft a new release** ▸
> 选 tag `v1.2` ▸ 把 `RELEASE_NOTES.md` 的内容粘进说明 ▸ 拖入 IPA 文件。

---

## 五、以后发新版本

```bash
# 1) 改版本号：project.pbxproj 里的 MARKETING_VERSION（共 4 处）
#    同时更新 CHANGELOG.md 和 RELEASE_NOTES.md
# 2) 回归校验 + 重新打包
./Tools/verify.sh
./Tools/make_ipa.sh
# 3) 提交推送
git add . && git commit -m "周目 1.3：……" && git push
# 4) 建新 Release（用新版本号当 tag）
gh release create v1.3 build/ZhouMu-1.3-unsigned.ipa \
  --title "周目 1.3" --notes-file RELEASE_NOTES.md
```

---

## 六、B 站简介可以这样写

> 【周目】一个 iPhone 小工具：打开就知道今天是开学第几周、今天上什么课 📅
>
> 开源免费，无广告无账号不联网
> 下载：https://github.com/<你的用户名>/zhoumu/releases
>
> 安装需要自己签名（需要一台电脑，免费 Apple ID 即可），
> 详细步骤见仓库里的「装到自己的iPhone.md」，跟着做大概 5 分钟。

**建议在视频里主动说明**：免费账号签的 App **7 天后要重新签一次**，免得观众过几天来问「怎么打不开了」。这是 Apple 的限制，不是 App 的问题。

---

## 七、常见问题

**Q：`gh repo create` 报仓库已存在？**
A：换个名字，或者 `gh repo create <用户名>/zhoumu --public --source=. --push`。

**Q：推送时提示要密码？**
A：用 `gh auth login` 走浏览器授权，或者配置 SSH key。别用账号密码，GitHub 早就不支持了。

**Q：怎么改仓库名 / 加标签？**
A：网页上进 **Settings** 改名字；**About** 右侧齿轮可以加 topics，比如
`ios` `swiftui` `widgetkit` `swift` `school` `timetable`，方便别人搜到。

**Q：想加配图到 Release 说明里？**
A：直接把 `Screenshots/` 里的 PNG 拖进网页版 Release 说明的编辑框，GitHub 会自动生成链接。
