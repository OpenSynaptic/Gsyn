/// All UI strings for the app — two-language (zh / en) bundle.
/// Access via: `ref.watch(appStringsProvider)` or `AppStrings.of(ref)`.
class AppStrings {
  final bool isZh;
  const AppStrings(this.isZh);

  // ── Navigation (bottom bar + drawer) ────────────────────────────────────────
  String get navDashboard   => isZh ? '仪表盘'   : 'Dashboard';
  String get navDevices     => isZh ? '设备'     : 'Devices';
  String get navAlerts      => isZh ? '告警'     : 'Alerts';
  String get navSend        => isZh ? '发送'     : 'Send';
  String get navSettings    => isZh ? '设置'     : 'Settings';
  String get drawerMap      => isZh ? '设备地图' : 'Device Map';
  String get drawerHistory  => isZh ? '历史数据' : 'History';
  String get drawerRules    => isZh ? '规则引擎' : 'Rules Engine';
  String get drawerHealth   => isZh ? '系统健康' : 'System Health';
  String get appSubtitle    => 'IoT Dashboard v1.0';

  // ── Dashboard ────────────────────────────────────────────────────────────────
  String get dashboardTitle       => isZh ? 'OpenSynaptic 仪表盘' : 'OpenSynaptic Dashboard';
  String get kpiTotalDevices      => isZh ? '总设备数'    : 'Total Devices';
  String get kpiOnlineRate        => isZh ? '在线率'      : 'Online Rate';
  String get kpiActiveAlerts      => isZh ? '活跃告警'    : 'Active Alerts';
  String get kpiThroughput        => isZh ? '消息吞吐量'  : 'Throughput';
  String get chartTempTrend       => isZh ? '温度趋势'    : 'Temperature Trend';
  String get chartHumTrend        => isZh ? '湿度趋势'    : 'Humidity Trend';
  String get gaugeTemp            => isZh ? '温度'        : 'Temperature';
  String get gaugePressure        => isZh ? '气压'        : 'Pressure';
  String get gaugeHumidity        => isZh ? '湿度'        : 'Humidity';
  String get gaugeLiquidLevel     => isZh ? '液位'        : 'Liquid Level';
  String get gaugeTankA           => isZh ? '水箱 A'      : 'Tank A';
  String get chartDeviceComp      => isZh ? '设备对比'    : 'Device Comparison';
  String get chartDeviceTypes     => isZh ? '设备类型'    : 'Device Types';
  String get dtSensors            => isZh ? '传感器'      : 'Sensors';
  String get dtActuators          => isZh ? '执行器'      : 'Actuators';
  String get dtGateways           => isZh ? '网关'        : 'Gateways';
  String get dtOther              => isZh ? '其他'        : 'Other';

  // ── Devices ──────────────────────────────────────────────────────────────────
  String get devicesTitle         => isZh ? '设备'        : 'Devices';
  String get searchHint           => isZh ? '搜索…'       : 'Search…';
  String get latestReadings       => isZh ? '最新读数'    : 'Latest Readings';
  String get devicePrefix         => isZh ? '设备'        : 'Device';

  // ── Alerts ───────────────────────────────────────────────────────────────────
  String get alertsTitle          => isZh ? '告警'        : 'Alerts';
  String get alertCritical        => isZh ? '严重'        : 'Critical';
  String get alertWarning         => isZh ? '警告'        : 'Warning';
  String get alertInfo            => isZh ? '信息'        : 'Info';
  String get noAlerts             => isZh ? '暂无告警'    : 'No alerts';
  String get deviceLabel          => isZh ? '设备'        : 'Device';

  // ── History ──────────────────────────────────────────────────────────────────
  String get historyTitle         => isZh ? '历史数据'    : 'History';
  String get noData               => isZh ? '暂无数据'    : 'No data';
  String exportedTo(String p)     => isZh ? '已导出至 $p' : 'Exported to $p';
  String get csvTimestamp         => isZh ? '时间戳'      : 'Timestamp';
  String get csvDeviceAid         => 'Device AID';
  String get csvSensor            => isZh ? '传感器'      : 'Sensor';
  String get csvValue             => isZh ? '数值'        : 'Value';
  String get csvUnit              => isZh ? '单位'        : 'Unit';

  // ── System Health ────────────────────────────────────────────────────────────
  String get healthTitle          => isZh ? '系统健康'    : 'System Health';
  String get udpStatus            => isZh ? 'UDP 状态'    : 'UDP Status';
  String get mqttStatus           => isZh ? 'MQTT 状态'   : 'MQTT Status';
  String get messagesPerSec       => isZh ? '消息/秒'     : 'Messages/sec';
  String get totalMessages        => isZh ? '总消息数'    : 'Total Messages';
  String get dbSize               => isZh ? '数据库大小'  : 'Database Size';
  String get statusConnected      => isZh ? 'Connected'   : 'Connected';
  String get statusDisconnected   => isZh ? 'Disconnected': 'Disconnected';

  // ── Rules Config ─────────────────────────────────────────────────────────────
  String get rulesTitle           => isZh ? '规则引擎'    : 'Rules Engine';
  String get tabRules             => isZh ? '规则'        : 'Rules';
  String get tabOpLogs            => isZh ? '操作日志'    : 'Operation Logs';
  String get noRules              => isZh ? '暂无规则'    : 'No rules yet';
  String get noOpLogs             => isZh ? '暂无操作记录': 'No operation logs';
  String get deleteRuleTitle      => isZh ? '删除规则'    : 'Delete Rule';
  String deleteRuleMsg(String n)  => isZh ? '确定删除规则 "$n" 吗？' : 'Delete rule "$n"?';
  String get editRule             => isZh ? '编辑规则'    : 'Edit Rule';
  String get newRule              => isZh ? '新建规则'    : 'New Rule';
  String get save                 => isZh ? '保存'        : 'Save';
  String get cancel               => isZh ? '取消'        : 'Cancel';
  String get delete               => isZh ? '删除'        : 'Delete';
  String get confirm              => isZh ? '确认'        : 'Confirm';
  String get ruleName             => isZh ? '规则名称'    : 'Rule Name';
  String get sensorIdFilter       => isZh ? '传感器 ID 过滤' : 'Sensor ID Filter';
  String get emptyForAll          => isZh ? '留空 = 所有' : 'Empty = all';
  String get deviceAidFilter      => isZh ? '设备 AID 过滤' : 'Device AID Filter';
  String get operator_            => isZh ? '运算符'      : 'Operator';
  String get threshold            => isZh ? '阈值'        : 'Threshold';
  String get triggerAction        => isZh ? '触发动作'    : 'Trigger Action';
  String get actionCreateAlert    => isZh ? '创建告警'    : 'Create Alert';
  String get actionSendCommand    => isZh ? '发送命令'    : 'Send Command';
  String get actionLogOnly        => isZh ? '仅记录日志'  : 'Log Only';
  String get targetAidLabel       => isZh ? '目标设备 AID（留空 = 触发设备）' : 'Target AID (empty = trigger device)';
  String get customCmdLabel       => isZh ? '自定义命令内容' : 'Custom Command';
  String generatedPayload(String p) => isZh ? '生成载荷: $p' : 'Generated payload: $p';
  String cooldownDisplay(int s)   => isZh ? '冷却:${s}s'  : 'Cooldown:${s}s';
  String get cooldownLabel        => isZh ? '冷却时间 (秒)' : 'Cooldown (sec)';
  String get rulesHelpText        => isZh
      ? '• 传感器 ID / 设备 AID 留空表示匹配全部\n'
        '• 冷却时间内重复触发的事件将被忽略\n'
        '• 发送命令：目标 AID 留空则发送给触发规则的设备'
      : '• Leave Sensor ID / AID empty to match all\n'
        '• Events within the cooldown window are suppressed\n'
        '• Send command: empty target AID sends to the triggering device';

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle        => isZh ? '设置'        : 'Settings';
  String get settingsTabConnect   => isZh ? '连接'        : 'Connect';
  String get settingsTabCards     => isZh ? '卡片'        : 'Cards';
  String get settingsTabTheme     => isZh ? '主题'        : 'Theme';
  String get settingsTabInfo      => isZh ? '信息'        : 'Info';

  // Settings — Connection
  String get secUdp               => isZh ? 'UDP 数据接收'  : 'UDP Reception';
  String get enableUdp            => isZh ? '启用 UDP 监听' : 'Enable UDP Listening';
  String get listenAddr           => isZh ? '监听地址'      : 'Listen Address';
  String get listenAddrHint       => isZh ? '0.0.0.0 = 所有网卡' : '0.0.0.0 = all interfaces';
  String get listenPort           => isZh ? '监听端口'      : 'Listen Port';
  String get secMqtt              => isZh ? 'MQTT 数据接收' : 'MQTT Reception';
  String get enableMqtt           => isZh ? '启用 MQTT'     : 'Enable MQTT';
  String get mqttBroker           => isZh ? 'Broker 地址'   : 'Broker Address';
  String get mqttPort             => isZh ? 'Broker 端口'   : 'Broker Port';
  String get secMapTile           => isZh ? '地图瓦片服务器': 'Map Tile Server';
  String get tileProviderLabel    => isZh ? 'Tile 提供商'   : 'Tile Provider';
  String get customTileUrl        => isZh ? '自定义 Tile URL' : 'Custom Tile URL';
  String tileCurrentUrl(String u) => isZh ? '当前: $u'      : 'Current: $u';
  String get saveConnSettings     => isZh ? '保存连接设置'  : 'Save Connection Settings';
  String get connSettingsSaved    => isZh ? '连接设置已保存': 'Connection settings saved';
  String get secWifi              => isZh ? 'Wi-Fi / 网络状态' : 'Wi-Fi / Network Status';
  String get wifiHint             => isZh
      ? 'UDP 数据接收依赖 Wi-Fi / 以太网连接，请确保设备与 OpenSynaptic 节点在同一网络。'
      : 'UDP reception requires Wi-Fi / Ethernet. Ensure the device and node are on the same network.';
  String get secBluetooth         => isZh ? '蓝牙 (BT-UART) 连接' : 'Bluetooth (BT-UART)';
  String get enableBluetooth      => isZh ? '启用蓝牙传输'  : 'Enable Bluetooth Transport';
  String get btExperimentalHint   => isZh
      ? '实验性功能 — 需要固件支持 BT-UART 透传'
      : 'Experimental — requires firmware BT-UART pass-through';
  String get btMacLabel           => isZh ? '蓝牙设备地址 (MAC)' : 'Bluetooth Device Address (MAC)';
  String get btPortLabel          => isZh ? '虚拟端口 / 通道' : 'Virtual Port / Channel';
  String get btInstructions       => isZh
      ? '① 先在系统蓝牙设置中配对设备\n② 在此输入设备 MAC 地址\n③ 固件需开启 BT-UART 透传模式'
      : '① Pair the device in system Bluetooth settings\n② Enter the device MAC address here\n③ Firmware must enable BT-UART pass-through mode';

  // Settings — Cards
  String get secKpi               => isZh ? 'KPI 卡片'         : 'KPI Cards';
  String get cardDevicesLabel     => isZh ? '总设备数'          : 'Total Devices';
  String get cardOnlineRateLabel  => isZh ? '在线率'            : 'Online Rate';
  String get cardAlertsLabel      => isZh ? '活跃告警'          : 'Active Alerts';
  String get cardThroughputLabel  => isZh ? '消息吞吐量'        : 'Throughput';
  String get secLineChart         => isZh ? '折线图'            : 'Line Charts';
  String get toggleTempChart      => isZh ? '温度趋势图'        : 'Temperature Trend Chart';
  String get toggleHumChart       => isZh ? '湿度趋势图'        : 'Humidity Trend Chart';
  String get secGauges            => isZh ? '仪表盘'            : 'Gauges';
  String get toggleGaugesRow1     => isZh ? '温度 + 气压仪表'   : 'Temperature + Pressure Gauges';
  String get toggleGaugesRow2     => isZh ? '液位 + 湿度仪表'   : 'Liquid Level + Humidity Gauges';
  String get secCharts            => isZh ? '图表'              : 'Charts';
  String get toggleBarChart       => isZh ? '柱状图：设备对比'  : 'Bar Chart: Device Comparison';
  String get togglePieChart       => isZh ? '饼图：设备类型'    : 'Pie Chart: Device Types';
  String get saveCardSettings     => isZh ? '保存卡片设置'      : 'Save Card Settings';
  String get cardSettingsSaved    => isZh ? '卡片设置已保存'    : 'Card settings saved';

  // Settings — Theme
  String get secAccent            => isZh ? '主色调'            : 'Accent Color';
  String get accentHint           => isZh
      ? '控制按钮、高亮、指示器颜色，即时生效。'
      : 'Controls button, highlight and indicator colors. Applied immediately.';
  String get secBg                => isZh ? '背景颜色'          : 'Background Color';
  String get bgHint               => isZh
      ? '调整整体背景、卡片底色，即时生效。'
      : 'Adjusts overall background and card colors. Applied immediately.';
  String get bgGroupDark          => isZh ? '深色系'            : 'Dark';
  String get bgGroupLight         => isZh ? '浅色系'            : 'Light';
  String get secLanguage          => isZh ? '语言 / Language'   : 'Language / 语言';
  String get langHint             => isZh
      ? '手动选择语言，或跟随系统设置自动切换。'
      : 'Choose a language manually, or follow the system setting.';
  String get langSystem           => isZh ? '跟随系统'           : 'System';

  // Settings — Info
  String get secAppInfo           => isZh ? '应用信息'          : 'App Info';
  String get infoAppName          => isZh ? '应用名称'          : 'App Name';
  String get infoVersion          => isZh ? '版本'              : 'Version';
  String get infoProtocol         => isZh ? '协议'              : 'Protocol';
  String get infoDbSize           => isZh ? '数据库大小'        : 'DB Size';
  String get secTransport         => isZh ? '传输状态'          : 'Transport Status';
  String get infoUdpStatus        => isZh ? 'UDP 状态'          : 'UDP Status';
  String get infoMqttStatus       => isZh ? 'MQTT 状态'         : 'MQTT Status';
  String get infoMsgPerSec        => isZh ? '消息/秒'           : 'Messages/sec';
  String get infoTotalMsg         => isZh ? '总消息数'          : 'Total Messages';
  String get connectedBadge       => isZh ? '✅ 已连接'         : '✅ Connected';
  String get disconnectedBadge    => isZh ? '❌ 未连接'         : '❌ Disconnected';
  String knownDevicesCount(int n) => isZh ? '已知设备 ($n)'     : 'Known Devices ($n)';
  String get noDeviceData         => isZh ? '暂无设备数据'      : 'No device data';
  String get secMaintenance       => isZh ? '维护'              : 'Maintenance';
  String get pruneBtn             => isZh ? '清理 7 天前历史数据': 'Prune data older than 7 days';
  String get pruneTitle           => isZh ? '确认清理'          : 'Confirm Prune';
  String get pruneMsg             => isZh
      ? '将删除 7 天前的所有传感器历史数据，此操作不可恢复。'
      : 'All sensor history older than 7 days will be deleted. This cannot be undone.';
  String get pruneDone            => isZh ? '已清理 7 天前历史数据' : 'Pruned data older than 7 days';

  // ── Common ───────────────────────────────────────────────────────────────────
  String get refresh              => isZh ? '刷新'              : 'Refresh';
  String get detecting            => isZh ? '检测中…'           : 'Detecting…';
  String get detectFailed         => isZh ? '检测失败'          : 'Detection failed';
  String get noNetwork            => isZh ? '❌ 无网络'         : '❌ No network';
  String get errorPrefix          => 'Error: ';
}

