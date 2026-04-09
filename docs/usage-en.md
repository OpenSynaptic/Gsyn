# OpenSynaptic Dashboard — English User Guide

> Version v1.0 · [中文文档](usage-zh.md) · [Back to README](../README.md)

---

## Table of Contents

1. [Navigation Overview](#1-navigation-overview)
2. [First-time Connection Setup](#2-first-time-connection-setup)
3. [Real-time Dashboard](#3-real-time-dashboard)
4. [Device Management](#4-device-management)
5. [Alert Center](#5-alert-center)
6. [Send Commands](#6-send-commands)
7. [Device Map](#7-device-map)
8. [History & CSV Export](#8-history--csv-export)
9. [Rules Engine](#9-rules-engine)
10. [System Health](#10-system-health)
11. [Themes & Appearance](#11-themes--appearance)
12. [Language Settings](#12-language-settings)
13. [Data Maintenance](#13-data-maintenance)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Navigation Overview

### Mobile (Portrait)

A bottom navigation bar provides 5 main destinations:

| Icon | Page | Description |
|---|---|---|
| 🏠 | **Dashboard** | Live data overview |
| 📱 | **Devices** | Known device list |
| 🔔 | **Alerts** | Active alert list |
| 📤 | **Send** | Send commands to nodes |
| ⚙️ | **Settings** | Connection, theme, language |

Tap **☰ Menu** (top-left) to open the side drawer with access to:
- 🗺️ Device Map
- 📜 History
- ⚙️ Rules Engine
- 💊 System Health

### PC / Desktop (Wide screen)

A **NavigationRail** on the left replaces the bottom navigation bar:

- **600–1199 px**: compact rail — icons only
- **≥ 1200 px**: extended rail — icons + labels
- The 4 extra function buttons (Map / History / Rules / Health) appear in a **2×2 grid** below 1200 px, or a **single row of 4** at 1200 px+

### Mobile Landscape

When the screen height ≤ 500 px (phone in landscape), the app automatically falls back to the mobile bottom-nav layout to prevent NavigationRail overflow.

---

## 2. First-time Connection Setup

Go to **Settings → Connect** tab:

### 2.1 UDP Reception (Recommended)

```
Enable UDP Listening   ✅ On
Listen Address         0.0.0.0  (all interfaces)
Listen Port            9876     (must match firmware)
```

**Steps:**
1. Make sure your phone/PC and the OpenSynaptic node are on the **same local network** (same Wi-Fi / LAN)
2. Toggle **Enable UDP Listening** on
3. If you change the port, tap **Save Connection Settings**
4. Power on the node — data appears on the dashboard automatically

> 💡 UDP reception requires Wi-Fi or Ethernet. Mobile data (4G/5G) typically does not support LAN UDP broadcast.

### 2.2 MQTT Reception (Optional)

```
Enable MQTT      ✅ On
Broker Address   localhost  (or your broker's IP/hostname)
Broker Port      1883
```

You can enable both UDP and MQTT simultaneously. The `TransportManager` merges both streams.

### 2.3 BT-UART Bluetooth (Experimental)

> ⚠️ Requires firmware with BT-UART pass-through support.

1. Pair the device in your system's Bluetooth settings first
2. Enter the device MAC address (format: `AA:BB:CC:DD:EE:FF`)
3. Set the virtual port (default 9877)
4. Save settings and enable the Bluetooth transport toggle

### 2.4 Network Status

The **Wi-Fi / Network Status** card shows your current connection type (Wi-Fi / Ethernet / Mobile).  
Tap the 🔄 icon to manually refresh the detection.

---

## 3. Real-time Dashboard

Dashboard data refreshes every **5 seconds** automatically and also updates instantly when sensor data arrives.

### 3.1 KPI Cards

| Card | Description |
|---|---|
| **Total Devices** | Number of known devices in the database |
| **Online Rate** | Online devices / total, color-coded: green ≥90%, yellow ≥70%, red <70% |
| **Active Alerts** | Unacknowledged alert count, red when non-zero |
| **Throughput** | Current messages per second (msg/s) |

> On PC: 4 equally-sized cards in a horizontal row.  
> On mobile: 2×2 grid.

### 3.2 Line Charts

- **Temperature Trend**: scrolling display of the latest 60 temperature readings
- **Humidity Trend**: scrolling display of the latest 60 humidity readings
- Charts include warning (yellow) and danger (red) threshold lines

> On PC: charts displayed side by side.  
> On mobile: stacked vertically.

### 3.3 Gauges

| Gauge | Range | Warning / Danger |
|---|---|---|
| Temperature | -20 – 80 °C | 40°C / 60°C |
| Pressure | 900 – 1200 hPa | 1050 / 1100 |
| Liquid Level | 0 – 100% | — |
| Humidity | 0 – 100% | 80% / 95% |

> On PC: all 4 gauges in a single row.  
> On mobile: 2 rows × 2 gauges.

### 3.4 Bar & Pie Charts

- **Bar Chart**: compare sensor values across multiple devices
- **Pie Chart**: device type distribution (Sensors / Actuators / Gateways / Other)

> On PC: bar chart (60%) and pie chart (40%) side by side.

### 3.5 Customizing Visible Cards

Go to **Settings → Cards** to toggle each card/chart individually. Changes take effect immediately.

---

## 4. Device Management

The **Devices** page lists all known devices (auto-registered from incoming sensor data).

| Field | Description |
|---|---|
| Device Name | `nodeId` field from firmware |
| AID | Address ID — unique device identifier assigned by firmware |
| Transport | UDP / MQTT / BT |
| Status | Online (green) / Offline (grey) |
| Latest Readings | Most recent sensor values |
| Last Seen | Time since last data received (s/m/h ago) |

- Use the **search bar** to filter by name or AID
- Tap a device card to view detailed sensor readings

---

## 5. Alert Center

The **Alerts** page lists all unacknowledged alerts, newest first.

### Alert Levels

| Level | Color | Example Trigger |
|---|---|---|
| **Critical** | 🔴 Red | Temperature exceeds danger threshold |
| **Warning** | 🟡 Yellow | Sensor value enters warning zone |
| **Info** | 🔵 Blue | Rules engine log-only trigger |

- Alerts are automatically created by the Rules Engine
- Each alert includes the triggering device and sensor details
- A local notification fires when a new alert is created (requires notification permission)

---

## 6. Send Commands

The **Send** page provides full OpenSynaptic CMD command capability, organized in 3 tabs:

### 6.1 Target Configuration Bar (top)

| Field | Description |
|---|---|
| Target Device / AID | Select from known devices or type an AID manually |
| TID | Transaction ID (0–255) |
| SEQ | Sequence number (0–255) |
| Target IP | Node's IP address (used for UDP sending) |
| Port | Node listening port (default 9876) |

**Send priority**: connected MQTT first → UDP (if target IP is provided)

### 6.2 Control Commands Tab

| Command | Byte | Description |
|---|---|---|
| PING | `0x01` | Heartbeat probe |
| PONG | `0x02` | Reply to PING |
| HANDSHAKE_ACK | `0x05` | Confirm handshake |
| HANDSHAKE_NACK | `0x06` | Reject handshake |
| ID_REQUEST | `0x03` | Request AID assignment from server |
| ID_ASSIGN | `0x04` | Assign a specific AID to a device |
| TIME_REQUEST | `0x07` | Request server timestamp |
| SECURE_DICT_READY | `0x0A` | Notify secure dictionary is ready |

### 6.3 Data Commands Tab

**Single-sensor DATA_FULL:**
1. Select Sensor ID (TEMP / HUM / PRES / etc.)
2. Select State code (U=Normal / A=Alert / W=Warning / D=Danger)
3. Select unit
4. Enter value
5. Tap **Send Single Sensor**

**Multi-sensor DATA_FULL:**
1. Tap ➕ to add sensor rows
2. Configure each row: SID / unit / value / state
3. Tap **Send Multi Sensor**

### 6.4 Raw HEX Tab

Enter hex bytes (spaces optional):

```
Example:  01 00           → PING frame
          09 00 01 00     → DATA_FULL frame header
```

A **CMD Byte Reference** table is shown at the bottom for quick lookup.

### 6.5 Send Log

Every send operation appends an entry to the log panel:
- Timestamp
- Command name
- ✅ Success / ❌ Failed
- Target address and frame size

---

## 7. Device Map

The **Device Map** displays device locations on an OpenStreetMap layer (requires devices to have GPS coordinate data).

### Map Tile Server Configuration

Go to **Settings → Connect → Map Tile Server**:

| Preset | Description |
|---|---|
| OpenStreetMap | Default, free public tiles |
| CartoDB Light | Light-themed map |
| CartoDB Dark | Dark-themed map |
| Stadia Alidade Dark | Dark professional map |
| Custom | Enter your own URL template (`{z}/{x}/{y}.png`) |

> 💡 If OpenStreetMap tiles are slow in your region, deploy a local tile server or use CartoDB.

---

## 8. History & CSV Export

The **History** page shows sensor records from the past **24 hours** (up to 500 entries).

### Column Descriptions

| Column | Description |
|---|---|
| Timestamp | Reception time (ISO 8601) |
| Device AID | Identifier of the sending device |
| Sensor | TEMP / HUM / PRES / etc. |
| Value | Sensor reading |
| Unit | °C / %RH / hPa / etc. |

### Exporting to CSV

Tap the **⬇️** button (top-right). The file is saved to the app's document directory:

```
Filename:         export_<timestamp>.csv
Android path:     /data/user/0/<package>/files/
Windows/Linux:    User Documents directory
```

CSV format:
```csv
Timestamp,Device AID,Sensor,Value,Unit
2026-04-09T10:00:00.000,1,TEMP,25.3,°C
2026-04-09T10:00:00.000,1,HUM,60.1,%RH
```

---

## 9. Rules Engine

The **Rules Engine** page has two tabs: **Rules** and **Operation Logs**.

### 9.1 Creating a Rule

Tap the **+** FAB (bottom-right) to create a new rule:

| Field | Description | Example |
|---|---|---|
| Rule Name | Human-readable label | "High Temp Alert" |
| Sensor ID Filter | Leave empty to match all sensors | TEMP |
| Device AID Filter | Leave empty to match all devices | 1 |
| Operator | `>` / `<` / `>=` / `<=` / `==` | `>` |
| Threshold | Trigger comparison value | 60 |
| Cooldown (sec) | Minimum interval between triggers, prevents spam | 60 |
| Trigger Action | See table below | Create Alert |

### 9.2 Action Types

| Action | Description |
|---|---|
| **Create Alert** | Creates an alert in the Alert Center and fires a local notification |
| **Send Command** | Sends a custom command to the target device (empty target AID = the triggering device) |
| **Log Only** | Writes to the Operation Log without creating an alert |

### 9.3 Operation Logs

The **Operation Logs** tab shows the 100 most recent rule trigger events:
- Trigger time
- Rule name  
- Triggering device AID and sensor value
- Action outcome

### 9.4 Rule Evaluation Notes

- Rules are evaluated in real-time for every incoming sensor reading
- Events within the cooldown window **do not** re-execute the action
- Rules are persisted in the local SQLite database

---

## 10. System Health

The **System Health** page provides a runtime status overview:

| Metric | Description |
|---|---|
| UDP Status | Connected (green) / Disconnected (red) |
| MQTT Status | Connected / Disconnected |
| Messages/sec | Current throughput |
| Total Messages | Cumulative messages received this session |
| Database Size | SQLite file size in KB |
| Known Devices | Device count with online/offline status |

Pull down to refresh all metrics.

---

## 11. Themes & Appearance

Go to **Settings → Theme** tab:

### 11.1 Accent Color

8 presets control buttons, highlights, and indicators:

| Name | Color |
|---|---|
| Deep Blue | `#1A73E8` |
| Teal | `#00897B` |
| Purple | `#7B1FA2` |
| Amber | `#FF8F00` |
| Red | `#D32F2F` |
| Cyan | `#0097A7` |
| Green | `#2E7D32` |
| Pink | `#C2185B` |

Tap a swatch to apply immediately. Selection persists across restarts.

### 11.2 Background Color

**Dark presets:**

| Preset | Description |
|---|---|
| Deep Navy (default) | Blue-tinted dark, industrial feel |
| Dark Slate | Cool dark grey |
| Charcoal | Neutral dark grey |
| True Black (AMOLED) | Pure black, power-efficient on AMOLED |
| Forest Dark | Green-tinted dark |
| Warm Dark | Brownish warm dark |

**Light presets:**

| Preset | Description |
|---|---|
| Snow White | Clean pure white |
| Cloud Grey | Soft cool grey |
| Paper Cream | Warm paper tone, easy on eyes |
| Mint Light | Fresh mint green |
| Lavender Light | Gentle lavender |
| Sky Blue | Light clear blue |

Each swatch preview shows 3 layers: main background / surface / card color.

---

## 12. Language Settings

Go to **Settings → Theme → Language** section:

| Option | Description |
|---|---|
| 🌐 **System** | Auto-detect system language: Chinese system → 中文, others → English |
| 🇨🇳 **中文** | Force Simplified Chinese |
| 🇬🇧 **English** | Force English |

Changes take effect immediately without a restart. Setting is persisted.

---

## 13. Data Maintenance

Go to **Settings → Info → Maintenance** section:

### Prune Old Data

Tap **Prune data older than 7 days**:
- Permanently deletes all sensor history older than 7 days
- **This action cannot be undone** — confirm carefully before proceeding
- Alert records, device info, and rule configurations are **not affected**

> Recommended: prune periodically to keep the database size manageable.

---

## 14. Troubleshooting

### No data appears on the dashboard

**Checklist:**
1. Open **System Health** — is UDP Status `Connected`?
2. Are your device and the IoT node on the **same local network** (same Wi-Fi / subnet)?
3. Does the node firmware target the correct IP and port (default UDP 9876)?
4. **Android**: confirm the app has been granted network permissions
5. **Windows**: verify that the Windows Firewall allows inbound UDP on port 9876

---

### MQTT shows Disconnected

1. Confirm the MQTT Broker (e.g., Mosquitto) is running
2. Check the broker address (IP or hostname) is correct
3. Verify the port (1883 for standard, 8883 for TLS)
4. Ensure the firewall permits port 1883

---

### How do I send a PING to a node?

1. Open the **Send** page
2. Enter the **Target IP** and **Port** in the top bar
3. Switch to the **Control** tab
4. Tap the **Send** button next to **PING**
5. Check the **Send Log** panel at the bottom for the result

---

### Rule triggered but no notification received

1. Check that the app has **notification permission** (Android 13+ requires explicit permission)
2. Verify the rule's **Cooldown** isn't too long (e.g., 3600s = only once per hour)
3. Open **Operation Logs** to confirm the rule was actually triggered

---

### Where is the exported CSV file?

- **Android**: File Manager → Internal Storage → `Android/data/<package>/files/` or use `adb pull`
- **Windows / Linux**: User Documents folder — the SnackBar after export shows the full path

---

### Text is invisible on light themes

The app uses theme-aware colors (`colorScheme.onSurface`) throughout. If you encounter invisible text, please update to **v1.0.1 or later**, which fixes hardcoded dark-mode color constants on light backgrounds.

---

*Documentation version: v1.0 · Last updated: 2026-04-09*

