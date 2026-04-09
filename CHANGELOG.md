# Changelog

All notable changes to Gsyn will be documented in this file.

---

## [v1.0.0-rc.1] — 2026-04-09 · Pre-release

> 🎉 **首个公开预发布版本 / First Public Pre-release**  
> 本版本为 v1.0.0 正式版的候选发布，核心功能已完整实现，欢迎测试反馈。  
> This is the release candidate for v1.0.0. All core features are complete — community testing and feedback are welcome.

---

### ✨ 新增功能 / New Features

#### 📊 实时仪表盘 Real-time Dashboard
- KPI 卡片展示在线率、平均温度、平均湿度、最后更新时间
- 折线图（温度 / 湿度）、仪表盘（压力 / 电池）、柱状图、饼图
- 每 5 秒自动刷新，支持平均 / 最新值切换
- KPI cards: online rate, avg. temperature, avg. humidity, last-seen time
- Line charts (temp/humidity), gauges (pressure/battery), bar chart, pie chart
- 5-second auto-refresh; toggle average vs. latest values

#### 📡 多传输协议 Multi-transport Protocol
- **UDP**（默认端口 9876）原始帧接收，零配置开箱即用
- **MQTT5**（默认端口 1883）发布/订阅，支持自定义 Broker 地址与 Topic
- **TransportManager** 统一合并双路数据流，上层无感切换
- UDP (default port 9876) raw-frame reception — zero-config, plug-and-play
- MQTT5 (default port 1883) pub/sub with custom broker & topic
- `TransportManager` merges both streams transparently

#### 🔔 告警系统 Alert System
- 实时推送三级告警：严重（Critical）/ 警告（Warning）/ 信息（Info）
- 集成 `flutter_local_notifications` 本地通知
- 告警历史列表，支持按级别筛选与一键清除
- Three-level real-time alerts: Critical / Warning / Info
- Local notifications via `flutter_local_notifications`
- Alert history list with level filtering and one-tap clear

#### 🗺️ 设备地图 Device Map
- 基于 OpenStreetMap + flutter_map 可视化设备 GPS 位置
- 支持自定义瓦片服务器地址
- OpenStreetMap-powered device GPS visualization via `flutter_map`
- Custom tile server URL support

#### 📜 历史数据 History & Export
- 最近 24 小时传感器记录，SQLite 持久化
- 一键导出 CSV，通过系统分享菜单发送
- Last-24h sensor records persisted in SQLite
- One-tap CSV export via system share sheet

#### ⚙️ 规则引擎 Rule Engine
- 可视化规则配置：阈值触发 → 创建告警 / 发送指令 / 仅记录
- 支持冷却时间防止频繁触发
- Visual rule config: threshold trigger → create alert / send command / log only
- Cooldown period to prevent rapid-fire triggers

#### 💊 系统健康 System Health
- UDP/MQTT 连接状态、消息吞吐量、数据库文件大小实时监控
- UDP/MQTT connection state, message throughput, DB file size — all live

#### 📤 指令发送 Command Sender
- 完整 OpenSynaptic CMD 指令集（PING / PONG / ID_ASSIGN / REBOOT 等）
- 支持原始 HEX 帧手动输入与发送
- Full OpenSynaptic CMD set (PING / PONG / ID_ASSIGN / REBOOT …)
- Raw HEX frame manual input & send

#### 🎨 主题系统 Theme System
- 6 深色 + 6 浅色背景预设 × 8 强调色 = 96 种组合，即时切换
- 所有 Widget 完整适配亮色 / 暗色模式
- 6 dark + 6 light background presets × 8 accent colors = 96 combos, hot-swap
- All widgets fully theme-aware for light and dark mode

#### 🌐 双语界面 Bilingual UI
- 中文 / English，默认跟随系统语言，可手动切换
- Chinese / English; follows system locale by default, manual override available

#### 📱💻 自适应响应式布局 Adaptive Responsive Layout
- `< 600 dp`：底部 NavigationBar + Drawer（手机竖屏）
- `600–1199 dp`：紧凑 NavigationRail（平板 / 横屏）
- `≥ 1200 dp`：展开 NavigationRail + 标签（PC 桌面）
- 仪表盘桌面视图：KPI 横排、图表两列并排、仪表盘四宫格
- `< 600 dp`: bottom NavigationBar + Drawer (portrait phone)
- `600–1199 dp`: compact NavigationRail (tablet / landscape)
- `≥ 1200 dp`: expanded NavigationRail with labels (desktop)
- Desktop dashboard: horizontal KPI row, side-by-side charts, 4-column gauges

---

### 🏗️ 工程 / Engineering

- **状态管理**：Riverpod `StateNotifier` + `Provider`
- **数据库**：SQLite — 移动端 `sqflite`，桌面端 `sqflite_common_ffi`
- **CI/CD**：`.github/workflows/ci.yml`（每次推送：analyze + test + debug APK）
- **Release 流程**：`.github/workflows/release.yml`（version tag 触发全平台构建）
  - Android APK + AAB（含混淆 / obfuscated）
  - Windows x64 ZIP（绿色免安装）
  - Linux x64 tar.gz
  - 自动 SHA-256 校验和附至 Release Notes
- **代码质量**：`flutter analyze --fatal-infos` 零警告，`dart format` 统一格式化
- **行尾统一**：`.gitattributes` 强制 LF，CI `dart format --set-exit-if-changed` 门卫

---

### 🐛 已知问题 / Known Issues

- **Web 平台**：UDP 原生套接字不可用，需使用 WebSocket MQTT；构建可成功但功能受限
- **蓝牙 UART**：实验性，协议层已预留接口但 UI 尚未完整接入
- **macOS**：可手动构建，未经充分测试，暂不提供预构建包
- **Web**: UDP native socket unavailable; requires WebSocket MQTT — builds but limited
- **BT-UART**: experimental, protocol stubs present but UI not fully wired
- **macOS**: manual build possible but untested; no pre-built binary provided

---

### 📦 下载 / Downloads

前往 [GitHub Releases](https://github.com/OpenSynaptic/Gsyn/releases/tag/v1.0.0-rc.1) 下载：  
Go to [GitHub Releases](https://github.com/OpenSynaptic/Gsyn/releases/tag/v1.0.0-rc.1) to download:

| 平台 Platform | 文件 File |
|---|---|
| 🤖 Android | `opensynaptic-dashboard-android.apk` |
| 🤖 Android (Play Store) | `opensynaptic-dashboard.aab` |
| 🪟 Windows x64 | `opensynaptic-dashboard-windows-x64.zip` |
| 🐧 Linux x64 | `opensynaptic-dashboard-linux-x64.tar.gz` |

---

*完整变更历史请参阅 [git log](https://github.com/OpenSynaptic/Gsyn/commits/main)。*  
*For full commit history see [git log](https://github.com/OpenSynaptic/Gsyn/commits/main).*

