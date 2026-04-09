# Gsyn

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.6-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-brightgreen" alt="Platforms">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
  <img src="https://img.shields.io/github/actions/workflow/status/OpenSynaptic/Gsyn/release.yml?label=CI%2FCD" alt="CI/CD">
  <img src="https://img.shields.io/badge/Language-中文%20%7C%20English-orange" alt="Bilingual">
</p>

<p align="center">
  <b>工业级 IoT 仪表盘客户端 · Industrial IoT Dashboard Client</b><br>
  基于 <a href="https://github.com/OpenSynaptic">OpenSynaptic 协议</a> 的跨平台实时数据可视化应用
</p>

---

## 目录 / Table of Contents

- [简介 Introduction](#简介-introduction)
- [功能特性 Features](#功能特性-features)
- [支持平台 Platforms](#支持平台-platforms)
- [快速开始 Quick Start](#快速开始-quick-start)
- [构建发布 Build--Release](#构建发布-build--release)
- [架构概览 Architecture](#架构概览-architecture)
- [使用文档 Documentation](#使用文档-documentation)
- [贡献 Contributing](#贡献-contributing)

---

## 简介 Introduction

**Gsyn** 是为 OpenSynaptic 物联网节点（固件）设计的实时监控客户端。通过 UDP 或 MQTT 接收传感器数据，提供图表、告警、规则引擎、历史导出等完整功能，支持 Android 手机、Windows/Linux 桌面及 Web 端。

**Gsyn** is a real-time monitoring client for OpenSynaptic IoT nodes. It receives sensor data via UDP or MQTT and provides charts, alerts, a rule engine, history export, and more — running natively on Android, Windows, Linux, and web.

---

## 功能特性 Features

| 功能 | 说明 |
|---|---|
| 📊 **实时仪表盘** | KPI 卡片、折线图、仪表盘、柱状图、饼图，每 5 秒自动刷新 |
| 📡 **多传输协议** | UDP（默认 9876）/ MQTT（默认 1883）/ BT-UART（实验性）|
| 🔔 **告警系统** | 实时推送，严重 / 警告 / 信息三级，本地通知 |
| 🗺️ **设备地图** | OpenStreetMap 可视化设备位置，支持自定义瓦片服务器 |
| 📜 **历史数据** | 最近 24h 传感器记录，一键导出 CSV |
| ⚙️ **规则引擎** | 阈值触发 → 创建告警 / 发送命令 / 仅记录日志，支持冷却时间 |
| 💊 **系统健康** | UDP/MQTT 连接状态、消息吞吐量、数据库大小实时监控 |
| 📤 **指令发送** | 完整 OpenSynaptic CMD 指令集（PING/PONG/ID_ASSIGN 等），支持原始 HEX |
| 🎨 **主题系统** | 6 深色 + 6 浅色背景预设 × 8 强调色，即时切换 |
| 🌐 **双语界面** | 中文 / English，默认跟随系统，可手动切换 |
| 📱💻 **自适应布局** | 手机 / 横屏 / 平板 / PC 桌面全端适配 |

---

## 支持平台 Platforms

| 平台 | 状态 | 发布格式 |
|---|---|---|
| 🤖 Android | ✅ 正式支持 | APK + AAB |
| 🪟 Windows x64 | ✅ 正式支持 | ZIP（绿色免安装） |
| 🐧 Linux x64 | ✅ 正式支持 | tar.gz |
| 🌐 Web | ⚠️ 可构建（UDP 不可用，需 WebSocket MQTT）| - |
| 🍎 macOS | 🔧 可手动构建 | - |

> **下载最新版本 / Latest Release** → [GitHub Releases](https://github.com/OpenSynaptic/Gsyn/releases)

---

## 快速开始 Quick Start

### 环境要求 Prerequisites

| 工具 | 最低版本 |
|---|---|
| Flutter SDK | 3.41.6 |
| Dart SDK | 3.11.4 |
| Android SDK（构建 APK）| API 21+ |
| JDK（Android 构建）| 17 |

### 克隆并安装依赖

```bash
git clone https://github.com/OpenSynaptic/Gsyn.git
cd Gsyn
flutter pub get
```

### 运行调试版

```bash
flutter run                  # Android（连接手机后）
flutter run -d windows       # Windows 桌面
flutter run -d linux         # Linux 桌面
```

### 首次连接 First-time Connection

1. 打开 App → **设置（Settings）→ 连接（Connect）**
2. 启用 **UDP 监听**，确认端口（默认 `9876`）
3. 确保设备与 OpenSynaptic 节点在同一局域网
4. 节点上电后数据自动推送至仪表盘

---

## 构建发布 Build & Release

### 手动构建

```bash
# Android APK（含混淆）
flutter build apk --release --obfuscate --split-debug-info=build/symbols/android

# Android AAB（上架 Google Play）
flutter build appbundle --release

# Windows 桌面
flutter build windows --release

# Linux 桌面（先安装系统依赖）
sudo apt-get install -y libgtk-3-dev libblkid-dev liblzma-dev \
  ninja-build cmake clang pkg-config libsqlite3-dev
flutter build linux --release
```

### 自动 CI/CD 发布

推送版本 tag 自动触发全平台构建并创建 GitHub Release：

```bash
git tag v1.2.3
git push origin v1.2.3
```

CI 流程（`.github/workflows/release.yml`）将自动：
1. 运行 `flutter analyze --fatal-infos` + `flutter test`
2. 构建 Android APK + AAB（混淆）、Windows ZIP、Linux tar.gz
3. 计算 SHA-256 校验和附加到 Release Notes

预发布版本命名：`v1.2.3-rc.1`（自动标记为 Pre-release）

---

## 架构概览 Architecture

```
lib/
├── main.dart                    # 入口，桌面 SQLite 初始化
├── app.dart                     # MaterialApp + AppShell（响应式导航）
├── core/
│   ├── constants.dart           # AppColors、Thresholds 常量
│   ├── protocol_constants.dart  # 传感器 ID、单位、状态码
│   ├── l10n/                    # 双语字符串 + LocaleNotifier
│   ├── theme/                   # 主题预设 + ThemeNotifier / BgNotifier
│   └── utils/                   # Responsive 断点工具
├── data/
│   ├── database/                # SQLite（sqflite / sqflite_ffi）
│   ├── models/                  # Device, SensorData, Alert, Rule, Log
│   └── repositories/            # CRUD Repository 层
├── features/                    # 各功能页面
│   ├── dashboard/               # KPI + 图表 + 仪表盘
│   ├── devices/                 # 设备列表
│   ├── alerts/                  # 告警
│   ├── send/                    # 指令发送
│   ├── settings/                # 连接 / 卡片 / 主题 / 信息
│   ├── history/                 # 历史 + CSV 导出
│   ├── map/                     # 设备地图
│   ├── rules_config/            # 规则引擎配置
│   └── system_health/           # 系统健康
├── protocol/
│   ├── codec/                   # OpenSynaptic Wire Protocol 编解码
│   ├── models/                  # DeviceMessage, SensorReading
│   └── transport/               # UDP + MQTT + TransportManager
├── rules/                       # 规则评估引擎
└── widgets/                     # 公共 Widget（KpiCard、GaugeWidget 等）
```

**状态管理**：Riverpod（StateNotifier + Provider）  
**数据库**：SQLite（移动端 sqflite，桌面端 sqflite_common_ffi）  
**传输层**：UDP Socket + MQTT5，由 `TransportManager` 统一合并数据流

---

## 使用文档 Documentation

| 文档 | 语言 |
|---|---|
| [📖 中文使用文档](docs/usage-zh.md) | 🇨🇳 中文 |
| [📖 English User Guide](docs/usage-en.md) | 🇬🇧 English |

---

## 贡献 Contributing

欢迎 Issue 和 Pull Request！

```bash
git checkout -b feat/your-feature
# 开发完成后
flutter analyze --fatal-infos   # 零警告
flutter test
git commit -m "feat: 描述"
git push origin feat/your-feature
# 发起 Pull Request
```

---

## License

APACHE 2.0 © 2026 OpenSynaptic
