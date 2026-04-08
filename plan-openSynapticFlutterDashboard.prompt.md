## Plan: OpenSynaptic Flutter IoT Dashboard App

Replace the current empty Android Java project with a comprehensive Flutter-based industrial IoT data visualization client. The app receives and decodes OpenSynaptic binary frames (FULL/DIFF/HEART) via UDP and MQTT, stores data locally in sqflite, renders a full-featured dashboard (KPI cards, real-time charts, gauges, meters, device map), provides a reflexive rules engine for automated actions, and supports sending OpenSynaptic standard commands back to devices. Mobile-first, offline-capable, must pass `flutter analyze` and `flutter build apk`.

---

### OpenSynaptic Protocol Summary (derived from source code)

The following wire format and codec details were extracted directly from the OSynaptic-TX/RX/FX C sources and the `18-data-format-specification.md` normative spec. All Dart codec implementations MUST match these exactly.

**Wire Frame Layout (A.1):**

```
Offset  Len  Field
0       1    cmd            — command byte (63=FULL, 170=DIFF, 127=HEART, 64/171/128=secure variants)
1       1    route_count    — fixed 1
2       4    source_aid     — sender device ID (u32 big-endian)
6       1    tid            — transaction/template ID (u8)
7       6    timestamp_raw  — 48-bit big-endian timestamp
13      N    body           — business payload
13+N    1    crc8           — CRC-8/SMBUS over body only (poly=0x07, init=0x00)
14+N    2    crc16          — CRC-16/CCITT-FALSE over all preceding bytes including crc8 (poly=0x1021, init=0xFFFF)
```

Minimum frame = 16 bytes (13 header + 0 body + 3 CRC).

**Body Format (FULL single-sensor, from `ostx_sensor.c`):**

```
{aid}.{status}.{ts_b64}|{sid}>{state}.{unit}:{b62}|
```

- `aid` = decimal device ID string
- `status` / `state` = "U" (or mapped from symbols)
- `ts_b64` = 8-char base64url encoding of the 48-bit timestamp
- `sid` = sensor ID string (e.g. "TEMP", "HUM")
- `unit` = UCUM unit code (e.g. "Cel", "Pa", "%")
- `b62` = Base62-encoded `int(value * 10000)` (VALUE_SCALE=10000)

**Body Format (FULL multi-sensor, from `osfx_template_grammar.c`):**

```
{node_id}.{node_state}.{ts_token}|{s1_id}>{s1_state}.{s1_unit}:{s1_value}|{s2_id}>{s2_state}.{s2_unit}:{s2_value}|...
```

Optional extensions per sensor: `#geohash_id`, `!supplementary_message`, `@resource_url`.

**Base62 Alphabet:** `0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ` (62 chars, case-sensitive, digits first). Negative values prefixed with `-`.

**Base64url Timestamp:** 6 bytes big-endian (upper 2 bytes = 0x0000, lower 4 = unix_seconds) → 8-char base64url string (no padding).

**DIFF Protocol (from `unified_parser.py` `run_engine`):**

1. First packet always FULL → establishes template signature `{header_base}.{TS}|{tag1}>\x01:\x01|{tag2}>\x01:\x01|...`
2. Cached per `(aid, tid)` pair with `vals_bin[]` array
3. If all values identical → HEART (cmd=127, empty body)
4. If values differ → DIFF (cmd=170): body = `[bitmask_bytes (ceil(n/8) bytes, big-endian)][len1:u8][val1_bytes][len2:u8][val2_bytes]...` only for changed slots
5. Receiver applies bitmask to update cached values, then reconstructs full message using template signature

**Command Bytes (from `osfx_handshake_cmd.h`):**

| Cmd | Value | Description |
|-----|-------|-------------|
| DATA_FULL | 63 | Full data frame |
| DATA_FULL_SEC | 64 | Secure full data |
| DATA_HEART | 127 | Heartbeat (no change) |
| DATA_HEART_SEC | 128 | Secure heartbeat |
| DATA_DIFF | 170 | Delta diff frame |
| DATA_DIFF_SEC | 171 | Secure diff |
| ID_REQUEST | 1 | Request device ID |
| ID_ASSIGN | 2 | Assign device ID |
| ID_POOL_REQ | 3 | Batch ID pool request |
| ID_POOL_RES | 4 | Batch ID pool response |
| HANDSHAKE_ACK | 5 | Acknowledge |
| HANDSHAKE_NACK | 6 | Negative acknowledge |
| PING | 9 | Ping |
| PONG | 10 | Pong |
| TIME_REQUEST | 11 | Request time sync |
| TIME_RESPONSE | 12 | Time sync response |

**CRC Algorithms (from `ostx_crc.c`):**

- CRC-8/SMBUS: bit-loop, `crc ^= byte`, shift left, if MSB set XOR with poly 0x07
- CRC-16/CCITT-FALSE: bit-loop, `crc ^= (byte << 8)`, shift left, if MSB set XOR with poly 0x1021

---

### Steps

#### Phase 1 — Project Scaffolding ✅ DONE

**Step 1:** Created Flutter project with `flutter create --org com.opensynaptic --project-name opensynaptic_dashboard`. Set `minSdk = 24`, added INTERNET/NETWORK/LOCATION permissions, enabled core library desugaring.

**Step 2:** Configured `pubspec.yaml` with 20+ dependencies: flutter_riverpod, fl_chart, syncfusion_flutter_gauges, flutter_map, mqtt5_client, sqflite, flutter_local_notifications, csv, go_router, shared_preferences, etc.

**Step 3:** Established folder structure: `protocol/codec/`, `protocol/transport/`, `protocol/models/`, `data/database/`, `data/models/`, `data/repositories/`, `rules/`, `features/{dashboard,devices,alerts,history,map,rules_config,settings,system_health}/`, `widgets/`.

#### Phase 2 — OpenSynaptic Protocol Codec ✅ DONE

**Step 4:** `lib/protocol/codec/base62.dart` — Base62 encode/decode matching ostx_b62.c/osrx_b62.c. Also b64url timestamp encoding.

**Step 5:** `lib/protocol/codec/crc.dart` — CRC-8/SMBUS + CRC-16/CCITT-FALSE matching ostx_crc.c.

**Step 6:** `lib/protocol/codec/packet_builder.dart` — Wire frame builder + sensor packet composer matching ostx_packet.c/ostx_sensor.c. Also PING/PONG/ID_REQUEST builders.

**Step 7:** `lib/protocol/codec/packet_decoder.dart` — Wire frame decoder matching osrx_packet.c. CRC validation.

**Step 8:** `lib/protocol/codec/body_parser.dart` — Body text parser matching osrx_sensor.c. Multi-sensor support.

**Step 9:** `lib/protocol/codec/diff_engine.dart` — DIFF/HEART template engine matching unified_parser.py.

**Step 10:** `lib/protocol/codec/commands.dart` — All command byte constants from osfx_handshake_cmd.h.

#### Phase 3 — Transport Layer ✅ DONE

**Step 11:** `lib/protocol/transport/udp_transport.dart` — RawDatagramSocket listener + sender.

**Step 12:** `lib/protocol/transport/mqtt_transport.dart` — mqtt5_client connection + pub/sub.

**Step 13:** `lib/protocol/transport/transport_manager.dart` — Merged stream + stats + Riverpod providers.

#### Phase 4 — Data Persistence ✅ DONE

**Step 14:** `lib/data/database/database_helper.dart` — SQLite schema (devices, sensor_data, alerts, rules, operation_logs, users, dashboard_layout, pending_commands).

**Step 15:** `lib/data/models/models.dart` — Device, SensorData, Alert, Rule, OperationLog, AppUser models.

**Step 16:** `lib/data/repositories/repositories.dart` — DeviceRepository, SensorDataRepository, AlertRepository, RuleRepository, OperationLogRepository with Riverpod providers.

#### Phase 5 — Dashboard & Visualization ✅ DONE

**Step 17:** `lib/widgets/kpi_card.dart` — Color-coded animated KPI cards.

**Step 18:** `lib/widgets/realtime_line_chart.dart` — fl_chart line chart with threshold lines.

**Step 19:** `lib/widgets/gauge_widget.dart` — SfRadialGauge with 3-zone color arcs.

**Step 20:** `lib/widgets/water_level_widget.dart` — Animated wave CustomPainter.

**Step 21:** `lib/widgets/bar_chart_widget.dart`, `lib/widgets/pie_chart_widget.dart` — Additional charts.

**Step 22:** `lib/features/dashboard/dashboard_page.dart` — Assembled dashboard with all widgets, live data from TransportManager.

#### Phase 6 — Device Map & Management ✅ DONE

**Step 23:** `lib/features/map/map_page.dart` — flutter_map + OpenStreetMap + color-coded markers.

**Step 24-25:** `lib/features/devices/devices_page.dart` — Device list (searchable) + detail page + control panel.

#### Phase 7 — Alerts, Rules & History ✅ DONE

**Step 26:** `lib/features/alerts/alerts_page.dart` — Tabbed alert center by severity.

**Step 27:** `lib/rules/rules_engine.dart` — Reflexive rules engine with send_command/create_alert/log_only actions.

**Step 28:** `lib/features/rules_config/rules_config_page.dart` — Rule CRUD UI.

**Step 29-30:** `lib/features/history/history_page.dart` — History query + CSV export.

#### Phase 8 — System & Polish ✅ DONE

**Step 31:** `lib/features/system_health/system_health_page.dart` — Connection status, msg/sec, DB size.

**Step 32:** `lib/features/settings/settings_page.dart` — UDP/MQTT connection config.

**Step 33-35:** `lib/app.dart` + `lib/main.dart` — App shell with bottom nav + drawer, all routes wired.

**Step 36:** ✅ `flutter analyze` — 0 errors, 0 warnings (info only). `flutter test` — 10/10 passed. `flutter build apk --debug` — ✅ SUCCESS.

