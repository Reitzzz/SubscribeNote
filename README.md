# 订小阅复刻版

一个面向 Android 与 Windows 的订阅管理应用。项目参考微信小程序「订小阅」的业务规则、信息结构与视觉语言，但不继续做微信小程序，也不把手机页面原样塞进 Windows 窗口。

当前仓库中的 `Android-5.6_Sol.html` 是从录屏还原的交互式 UI 标尺，用来确认页面、状态和视觉细节；它不是正式客户端技术栈。正式产品使用 Flutter 重建。

## 仓库说明

本仓库是个人练习与自用工程，用于复刻「订小阅」的交互与视觉，与原产品作者及运营方无关联。GitHub 仓库名为 `SubscribeNote`（对应中文「订阅记」），工程内部尚未重命名，以下名称保持现状，改动时需要一起核对：

| 位置 | 当前值 | 备注 |
|---|---|---|
| 应用名称 | 订小阅 | 桌面图标与任务切换器名称在 `app/android/app/src/main/AndroidManifest.xml` 的 `android:label`，应用内标题在 `app/lib/main.dart` |
| applicationId / 包名 | `cn.dingxiaoyue.dingxiaoyue` | 对外分发后无法原地升级，改名必须在正式分发前完成 |
| Dart 包名 | `dingxiaoyue` | `app/pubspec.yaml` 的 `name`；改动波及 `lib/`、`test/` 中所有 `package:dingxiaoyue/...` 导入 |
| APK 文件名 | `dingxiaoyue-demo-0.1.0-universal.apk` | 随包名调整一并处理 |

以下内容不纳入版本库，需要时在本机重新生成或使用原始素材：

- Android 与 Windows 交付产物（`*.apk`、`*.exe`、`*.msix`）——体积大且可重建；已构建 APK 的校验值保留在 `Android/dingxiaoyue-demo-0.1.0-universal.apk.sha256`；
- 录屏源视频与截帧（`video/*.mp4`、`video/frames/`）——截帧可用 `scripts/extract-frames.ps1` 重新生成；
- 密钥与签名文件（`*.jks`、`*.keystore`、`key.properties`）——一律保留在仓库外；
- 构建缓存与本机配置（`app/build/`、`app/.dart_tool/`、`app/android/.gradle/`、`app/android/local.properties`）。

`app/assets/recording/` 的服务图标取自用户提供的录屏，仅用于本地还原，不代表取得品牌资产的再分发授权；正式分发前需核对授权（另见文末「录屏补齐与截帧」）。

## Android Demo

Flutter 工程位于 `app/`，本次只交付 Android。安装包 `Android/dingxiaoyue-demo-0.1.0-universal.apk` 包含 ARM64、ARMv7 和 x86_64，使用 release 编译和 Android 本地 debug 签名，适合自用测试，不是商店发布包；该文件体积大，不纳入版本库（见「仓库说明」），可在本机用 `flutter build apk --release` 重新生成。传到手机打开安装，或执行：

```powershell
adb install -r .\Android\dingxiaoyue-demo-0.1.0-universal.apk
```

界面按指定 HTML 的渐变、颜色、字号、间距、卡片、服务图标和底部导航重建；系统状态栏、手势区域及日期选择器使用 Android 原生行为。首页、服务库/搜索/分类、添加表单、详情、续费、订阅更新、停止/取消停止、趋势/占比和设置已接通。新增、事件、设置与手动汇率保存到应用私有目录的 SQLite；关闭重开保留数据。首次启动添加八项示例，之后不再补回或覆盖；卸载应用或清除应用数据会删除本地记录。

计费以订阅和事件为依据，金额使用整数分，汇率使用六位定点数。自动扣费按已到期账期记账，未连接支付账户确认实际扣款；手动续费按付款日入账。更改汇率保留历史账单折算，未来预测使用新汇率；历史缺失汇率的账单仍显示待换算。统计由同一批记录派生，不复用 HTML 中互相独立的录屏金额快照。立即升级仅记录今天的变更，历史账单不可回写；手动续费当前支持按月增加时长。

尚未接入：系统到期通知、完整导入/导出、邮件发送、AI 识别、分享卡、账号同步、联网汇率、Pro/支付和平替购买跳转。对应入口显示说明，未将它们伪装成已完成操作。平替介绍和价格为录屏样例。Windows 稿保持原状。

本机复现命令（仅设置当前 PowerShell 进程环境，不修改全局 PATH）：

```powershell
. .\scripts\flutter-env.ps1
Set-Location app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

本机工具、下载记录与路径见下节。依赖版本由 `app/pubspec.lock` 固定。不要并行运行同一工程的 `flutter test` 和 `flutter build`，它们共用生成目录。

验证记录和界面截图见 [Android/验收说明.md](Android/验收说明.md)。截图采集测试使用本机已有微软雅黑字体，不向 APK 分发该字体；APK 使用 Android 字体。可重新运行 `flutter test --dart-define=CAPTURE_UI=true --update-goldens` 生成截图，普通测试不将会随日期变化的截图当作固定断言。

## 本工程使用的工具与本次下载记录

以下为当前保留的开发和构建工具，版本来自 2026-09-03 的本机安装元数据及工程配置，不代表最新版本。

### 开发、构建和验证工具

| 工具 | 本次用途 | 使用位置或方式 |
|---|---|---|
| Flutter 3.47.2 / Dart 3.13.2 | 创建原生 Flutter 工程、绘制页面、格式化、静态分析、单元/界面测试和编译 APK | `D:\DevTools\languages\Flutter\flutter`；命令为 `dart format`、`flutter analyze`、`flutter test`、`flutter build apk --release` |
| Oracle JDK 21.0.8 | 运行 Android Gradle 构建 | 复用 `D:\Java`；工程 Java/Kotlin 字节码目标为 17 |
| Gradle 9.3.1 | 解析 Android 构建依赖、编译和打包 | 使用工程 Gradle Wrapper，复用 `D:\DevTools\otherTools\Android_Tools\gradle-cache` |
| Android SDK Command-line Tools 22.0 | 通过 `sdkmanager` 管理 SDK 组件 | 当前 SDK 根目录的 `cmdline-tools\latest` |
| Android SDK Platform 36、Build-Tools 36.0.0 | 编译 Android 应用；用 `apksigner` 验证签名、`aapt` 检查包名/最低系统版本/CPU 架构 | 当前 SDK 根目录的 `platforms\android-36`、`build-tools\36.0.0` |
| Android Platform-Tools 37.0.1（ADB） | 检查设备连接，安装和启动应用 | 当前 SDK 根目录的 `platform-tools`；本次未完成设备运行验收 |
| NDK 28.2.13676358、CMake 3.22.1 | 构建原生依赖；`jni` 插件显式使用 NDK/CMake | 当前 SDK 根目录的 `ndk`、`cmake`，属于构建依赖，保留 |
| 已有 Microsoft Edge + browser-harness | 打开指定 HTML、检查交互并截取参考图 | 使用独立浏览器配置；截图保留在 `artifacts/qa/` |
| 已有 Python 3.12.10、Node.js 24.14.1 | 辅助处理原型资源；Node.js 还用于现有 `scripts/check-prototype.cjs` 检查脚本 | `D:\Python\python.exe`、`D:\NodeJS\node.exe` |
| PowerShell、ripgrep（`rg`）、Codex 文件编辑工具 | 执行脚本、搜索与修改代码、校验文件 SHA-256 | 复用系统及当前开发环境 |
| 已有 FFmpeg / ffprobe | 工程的录屏截帧、尺寸探测及品牌图标裁剪工具 | `D:\DevTools\otherTools\video_tools\ffmpeg\bin`；本次 Demo 复用已提取素材，没有重新下载此工具 |

### 本次新增且当前保留的工具

当前 Android SDK 根目录为 `D:\DevTools\otherTools\Android_Tools\android-sdk`。下表 Android 组件路径均相对此目录。

| 新增内容 | 版本 / 包标识 | 安装位置 | 来源与用途 |
|---|---|---|---|
| Flutter SDK（内含 Dart SDK） | Flutter 3.47.2 / Dart 3.13.2 | `D:\DevTools\languages\Flutter\flutter` | Flutter 官方 Windows stable 发行版；开发和构建客户端 |
| Android NDK | `ndk;28.2.13676358` | `ndk\28.2.13676358` | Google Android SDK 仓库，通过 `sdkmanager` 安装 |
| CMake | `cmake;3.22.1` | `cmake\3.22.1` | Android 构建期间自动安装的原生构建依赖 |

工程使用 Android SDK Platform 36；应用 compile/target SDK 为 36、min SDK 为 24。Android 库模块的 compile SDK 通过 [app/android/build.gradle.kts](app/android/build.gradle.kts) 中的 `finalizeDsl` 统一为 36。`flutter build apk --release --no-pub` 和 APK 签名验证通过。

Flutter SDK 来自[官方发布清单](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json)，已通过 SHA-256 校验；版本及校验信息保留在 `D:\DevTools\languages\Flutter\release.json`。Flutter 的引擎、测试和 Android 编译缓存位于 SDK 的 `bin\cache`。

### 复用的安装、项目依赖及环境改动

`D:\DevTools\otherTools\Android_Tools\android-sdk` 中复用已有的 Command-line Tools 22.0、Platform-Tools 37.0.1、Build-Tools 36.0.0、Android 36 平台及许可证；NDK 28.2.13676358 和 CMake 3.22.1 已统一放在该 SDK 根目录下。JDK、Gradle 9.3.1 缓存、浏览器、Python、Node.js 和录屏工具沿用已有安装。

项目另外通过 `flutter pub get` 解析并获取依赖：`flutter_riverpod 3.4.2`（状态管理）、`go_router 17.5.0`（路由）、`drift 2.34.4` / `drift_flutter 0.3.1`（SQLite 持久化）、`flutter_svg 2.3.0`（SVG 图标）、`flutter_lints 6.0.0`（检查规则）；SQLite 的 Dart 包为传递依赖 `sqlite3 3.5.2`。`flutter_test` 和 `flutter_localizations` 随 Flutter SDK 提供。完整依赖及校验信息以 [app/pubspec.lock](app/pubspec.lock) 为准，这些是项目依赖，不是单独安装的桌面软件。

Android 构建插件在 [app/android/settings.gradle.kts](app/android/settings.gradle.kts) 中配置为 Android Gradle Plugin 9.1.0、Kotlin 插件 2.4.0，由 Gradle 使用 Google/Maven Central/Gradle Plugin Portal 仓库解析，复用缓存并按需下载缺失依赖；没有逐项记录哪些传递依赖命中了原有缓存。

环境配置集中在 [scripts/flutter-env.ps1](scripts/flutter-env.ps1)：仅设置当前 PowerShell 进程的 `JAVA_HOME`、`ANDROID_HOME`、`ANDROID_SDK_ROOT`、`GRADLE_USER_HOME` 和 Flutter 的 PATH，不修改系统全局 PATH。Android 工程的 `local.properties` 同样指向 `D:\DevTools\otherTools\Android_Tools\android-sdk`。尚未完成的设备运行验证见 [验收说明](Android/验收说明.md)。

## 已确认的产品约束

- 首发平台只有 Android 和 Windows。
- Windows 是自适应窗口、键盘操作、文件导入导出和系统通知齐全的真桌面端。
- Android 尽量还原原版视觉；Windows 共享业务规则和设计语言，但采用桌面布局。
- 应用本地优先：断网、服务器故障和未登录时仍可完整读写。
- 初期只有一个用户在两台设备上使用，后续才可能开放注册。
- 主要使用地区是中国大陆；现有韩国 Azure Linux 服务器只用于个人同步试运行。
- 测试期交付 Android APK 和 Windows MSIX/安装包，暂不为应用商店流程阻塞开发。

## 技术栈结论

| 层 | 选择 | 用途 |
|---|---|---|
| 客户端 | Flutter + Dart | 同一工程构建 Android 与 Windows |
| 状态管理 | Riverpod | 管理本地数据流、派生统计和同步状态 |
| 路由 | go_router | 页面导航和可恢复的路由状态 |
| 本地数据库 | Drift + SQLite | 离线数据、事务、迁移和类型安全查询 |
| 本地提醒 | flutter_local_notifications | Android 与 Windows 到期提醒 |
| 服务端 | Serverpod | 同为 Dart 的单体 API、认证和同步服务 |
| 云端数据库 | PostgreSQL | 用户隔离、同步版本、事件历史和软删除 |
| 部署 | Docker Compose + TLS 反向代理 | 在现有 Azure Linux 上运行个人同步服务 |
| 发布 | APK + MSIX | 自用测试阶段直接安装，后续再接商店 |

上表包含后续完整产品的技术选型，当前 Demo 实际依赖见 `app/pubspec.yaml` 和 `app/pubspec.lock`。README 的工具版本仅记录本次构建环境；后续更新依赖时以锁文件为准。

## 为什么客户端选 Flutter

需求不是“做一个手机版网页”，而是用一套业务代码同时做 Android 和 Windows 原生应用。Flutter 对两个目标平台都有正式支持，并允许自行绘制界面，适合还原大量自定义卡片、渐变、时间线和统计图。

Flutter 还允许两端共享：

- 订阅、计费事件、优惠与升级的数据模型；
- 金额、周期、汇率和统计计算；
- 数据库、导入导出和同步逻辑；
- 设计令牌与基础组件。

两端不强行共享页面布局。Android 使用底部导航和单栏详情；Windows 可以使用侧栏、主从分栏、更高信息密度和键盘快捷键。这样保留代码复用，同时不牺牲桌面体验。

### 为什么不选另外三类方案

- **React Native**：项目没有 React/TypeScript 存量，Windows 端还需要额外生态和平台适配，收益不足以抵消维护面。
- **Uni-app / Taro**：优势集中在小程序和移动端多端发布；本项目已经放弃小程序，而且需要真 Windows 桌面体验。
- **Capacitor / Ionic**：适合把 Web 应用封装成移动端。这里既要求复杂本地数据能力，也要求 Windows 桌面交互和高精度 UI，还要长期维护离线同步，WebView 不是合适基础。
- **Compose Multiplatform**：是可行备选，但对当前这种表单、卡片、统计型产品没有明显胜过 Flutter 的收益，且会提高首个版本的不确定性。

## 为什么本地使用 Drift + SQLite

订阅数据是天然关系型数据：一个订阅拥有续费、升级、停订和恢复等事件，统计又依赖时间、币种和状态。SQLite 能提供事务、约束、索引和可靠迁移；Drift 在其上提供 Dart 类型安全查询和响应式数据流。

本地数据库是事实来源，而不是云端缓存：

```text
用户操作
  → 本地 SQLite 事务提交
  → UI 立即更新
  → 写入待同步队列
  → 有网络时后台同步
```

因此服务器宕机不会阻止新增、修改或删除。首版不引入 SQLCipher 和应用锁：当前设备与操作系统账号被视为可信；认证令牌仍必须放在系统安全存储中。设备共享或备注包含高敏信息时，再增加应用锁和数据库加密。

## 为什么使用 Riverpod 和 go_router

Riverpod 用于连接数据库查询、计费引擎和页面状态。统计、首页概览和详情指标都应从同一份领域数据派生，不能各自在 Widget 中重复计算。

go_router 只负责导航，不承载业务状态。它比手写页面栈更适合 Android 返回键、Windows 深层页面和将来恢复窗口状态，同时没有引入完整应用框架。

## 为什么同步后端选 Serverpod + PostgreSQL

同步不是首版前置条件，但最终产品需要账号下的 Android/Windows 双设备同步。Serverpod 让客户端和服务端继续使用 Dart，减少一个人维护两套语言、模型和序列化协议的成本；PostgreSQL 提供成熟的事务、约束、备份和迁移能力。

没有先用 PocketBase 再迁移，因为个人同步只会短期省下一些代码，却会制造一次确定的数据和认证迁移。也没有采用微服务：当前规模只需要一个单体 API 和一套数据库。

Hermes 只作为服务器上的运维 Agent 使用。它可以帮助执行部署，但不能替代以下工程工作：

- TLS 证书与域名；
- PostgreSQL 备份和恢复演练；
- 数据库迁移；
- 邮件验证码送达；
- 用户隔离、限流和审计；
- 服务监控与故障恢复。

## 同步原则

数据表从第一天保留以下同步字段，即使首版尚未连接服务器：

```text
id          UUID
updatedAt   最后修改时间
deletedAt   软删除时间
version     单调递增版本
deviceId    修改来源设备
```

同步采用增量推送/拉取和本地 outbox。单用户阶段不引入 CRDT；同一记录冲突使用“最后修改覆盖”，同时保留变更历史以便恢复。删除先写 tombstone，服务端保留 30 天软删除，再执行最终清理。

本地可免登录使用；启用同步时绑定邮箱验证码。账号与管理员角色分离，不把首个账号或某个邮箱硬编码为管理员。公开注册默认关闭，直到大陆网络质量、备份恢复、邮件、限流和用户隔离全部验证完成。

## 数据模型方向

核心模型是“订阅 + 事件”，而不是只在订阅表上反复覆盖价格和日期：

```text
Subscription
  ├─ StartEvent
  ├─ RenewalEvent
  ├─ UpgradeEvent
  ├─ PriceChangeEvent
  ├─ StopEvent
  ├─ ResumeEvent
  └─ ExpireEvent
```

这样详情时间线、累计消费、本年预计消费和统计图都能由同一套事件与计费规则生成，也能保留升级前后的历史。

## 首版范围

P0：

- 订阅管理与续费历史；
- 套餐升级、补差价和计费时间线；
- 趋势、占比等统计；
- 本地通知；
- 本地保存、手动更新汇率；
- 版本化 JSON 完整导入/导出；
- Windows 自适应布局、键盘快捷键和文件操作。

后置：

- 账号云同步；
- 联网更新汇率；
- AI 截图导入；
- Webhook 与云端必达提醒；
- 分享卡；
- Pro、支付和公开注册；
- 系统托盘、开机启动、后台常驻和多窗口；
- 自动更新服务。

完整备份使用带 `schemaVersion` 的 JSON，包含订阅、事件、设置和同步元数据。CSV 只用于查看和分析，不承担恢复职责。导出前需要提示文件包含名称、价格、备注和历史等敏感数据。

## 开发顺序

1. 以 `Android-5.6_Sol.html` 和录屏为视觉与交互 Oracle，确定首个 Demo 的页面和业务状态，不以补齐全部 HTML 细节为前提。
2. 创建 Flutter 工程，先完成领域模型、计费测试和 Drift schema。
3. 实现 Android UI，再抽取共享组件和设计令牌。
4. 实现 Windows 自适应布局、快捷键、导入导出和通知。
5. 完成本地版后，再实现 Serverpod/PostgreSQL 增量同步。
6. 在韩国 Azure 上进行个人双设备试运行和恢复演练。
7. 公开发布前重新评估大陆网络节点、签名、商店、隐私和运营能力。

### 下一阶段：双端本地 Demo

现有原型与录屏足以作为开始实现的依据，不代表当前 HTML 可以直接编译为 Flutter 应用，或原型中的交互和计算已经完整可用。

首个功能 Demo 以「可安装、可离线使用、关闭重开不丢数据」为目标：共享 Flutter/Dart 业务与 Drift/SQLite 存储，实现首页、添加订阅、详情、续费/更新/停止、趋势与占比、手动汇率。统计从真实本地数据派生；Android 沿用原型视觉，Windows 采用确定的一份桌面布局基准。交付 Android APK 与 Windows 可运行程序包或安装包。

「使用兑换码」按用户要求替换为「汇率更新」，汇率说明收进该选项内部；初期手动维护并本地保存，联网更新后置。原型中的同名入口或按钮不作为功能已接通的证据。

账号同步、服务器、联网汇率、AI 与支付不阻塞这个 Demo；本地通知和完整导入/导出仍属于上文 P0，未完成时列为与完整首版的差距。工具目录、环境准备及双端验收规则见 [AGENTS.md](AGENTS.md)。

## 当前 UI 原型

无需安装依赖，使用任意静态文件服务器打开：

```powershell
py -3 -m http.server 4173 --bind 127.0.0.1
```

然后访问 `http://127.0.0.1:4173/Android-5.6_Sol.html`；Windows 稿按下列文件名访问。

该原型只验证页面、交互和视觉，不代表正式数据模型、同步协议或生产安全边界已经实现。

`windows-ds.html` 是 Windows 桌面布局示意（标题栏 + 侧栏 + 主从分栏），视觉语言沿用 Android 原型；另有 `windows-opus.html`、`windows-gemini.html`，均属于布局方案草稿。正式实现前确定采用的基准，各稿的交互和样例改动需分别核对。`node .\scripts\check-prototype.cjs` 当前只检查 `Android-5.6_Sol.html`。

### 录屏补齐与截帧

视频位于 `video/`。本机实际可用工具是 `D:\DevTools\otherTools\video_tools\ffmpeg\bin`，也支持从 PATH 查找或通过 `-ToolDirectory` 指定位置。脚本不安装依赖、不修改源视频，每次截帧创建独立目录，避免混入上次的图片。

```powershell
# 五段视频每 2 秒采样，输出单帧、4×3 分镜图和 manifest.json
.\scripts\extract-frames.ps1

# 密集采样指定片段；Start / Duration / Interval 的单位均为秒
.\scripts\extract-frames.ps1 -InputPath .\video\1000087223.mp4 -Start 12 -Duration 10 -Interval 0.5

# 从已核对的固定时间和位置提取界面图标，写入 assets/recording/
.\scripts\extract-frames.ps1 -ExtractLogos

# 不依赖测试框架的检查：语法、统计快照、日期边界、输入与转义、导航和图标
node .\scripts\check-prototype.cjs
```

分镜输出保存在 `video/frames/<视频名>-<批次>/`。时间标记用于定位片段；均匀采样可能错过快速过场，可缩短 `Interval`。图标取自用户提供的录屏，仅作为本地还原素材，不代表取得品牌资产的再分发授权。

| 录屏依据（时间约数） | 本次补齐 |
| --- | --- |
| `1000087223.mp4` 8–34 秒 | 首页七项原始订阅（含腾讯视频、ChatGPT）、概览切换；WPS 手动续费、图标选择；订阅详情 |
| 同上 38–49 秒 | 年份/分类切换、月度折线、Top 订阅、2025 年空月份；2026 年占比继续对齐用户截图 |
| 同上 50–59 秒 | WPS、XSUS、Bilibili、Apple Music 的不同平替列表、提示卡关闭 |
| 同上 62–104 秒 | 服务库长列表、搜索/分类、Telegram 模板、分类/周期选择、自动/手动续费表单 |
| `1000087224.mp4` | ChatGPT 日元价格、更新弹层、币种选择和立即升级分支 |
| `Screenrecorder-…23-13-01-9.mp4` | Claude 下期更新、立即生效、扣费日选项、同扣费日错误提示 |
| `Screenrecorder-…23-14-20-209.mp4` | 币种/排序选择、订单记录空态、首页概览说明、兑换优惠码 |
| `Screenrecorder-…23-14-52-497.mp4` | 停止日期校验、最后付费账期、停止/取消停止、删除确认 |

边界：

- 当前是内存交互原型，新增、续费、更新、删除和设置只影响本次预览，刷新恢复；不存储真实业务数据。
- 首页与统计来自不同录制时刻：统计保留 **不含 Claude 的七项订阅快照**，不会随预览增删重算。2026 年总额 ¥1027.96、9 月 ¥79.14；2025 年 ¥200.00。月度数据用于复现图表，不是经过账单核验的财务记录。
- 录屏内 ChatGPT 详情月均为 ¥90.20，首页按升级后的 ¥60.14 计算；两处按各自画面保留，不据此定义正式计费规则。
- 录屏没展示的 Pro 购买、反馈、AI 识别、分享与平替详情，仅说明未接入；邮件和兑换不会实际发送或执行。新增/换色等未完整展开的行为复用现有视觉样式，不宣称是原产品已核对的细节。
- 已提取首页、主要平替和服务库首屏图标（41 张）；服务库其余图标仍有文字占位，未知模板价格不猜测。真实数据持久化、完整计费、汇率与通知留到 Flutter 阶段。
