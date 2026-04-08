/// OpenSynaptic protocol constants — wire-compatible unit codes, sensor IDs, states.
/// All values must match what firmware/OSynaptic-TX sends.

/// Sensor body format: {sid}>{state}.{unit}:{b62}
/// State codes used in sensor segments
const kOsStates = ['U', 'A', 'W', 'D', 'O', 'E'];
// U=Normal, A=Alert, W=Warning, D=Danger, O=Offline, E=Error

/// Node/header state codes
const kOsNodeStates = ['U', 'A', 'W', 'D', 'O', 'E', 'S', 'I'];
// U=Unknown, A=Active, W=Warning, D=Danger, O=Offline, E=Error, S=Sleep, I=Idle

/// Standard unit strings — must match firmware unit field exactly.
const kOsUnits = <String>[
  // Temperature
  '°C', '°F', 'K',
  // Humidity
  '%', '%RH',
  // Pressure
  'hPa', 'kPa', 'Pa', 'bar', 'psi',
  // Voltage
  'V', 'mV',
  // Current
  'A', 'mA',
  // Power / Energy
  'W', 'kW', 'Wh', 'kWh',
  // Distance / Level
  'mm', 'cm', 'm',
  // Volume / Flow
  'L', 'mL', 'm3/h',
  // Light
  'lux', 'klux',
  // Gas / Air quality
  'ppm', 'ppb',
  // Speed / Rotation
  'rpm', 'm/s', 'km/h', 'rad/s',
  // Mass
  'kg', 'g',
  // Sound
  'dB',
  // Frequency
  'Hz', 'kHz',
  // Digital / Logic
  'bool', 'cnt', 'raw', 'unit',
];

/// Standard sensor ID prefixes used by OpenSynaptic nodes.
const kOsSensorIds = <String>[
  // Temperature
  'TEMP', 'T1', 'T2', 'T3', 'TMP',
  // Humidity
  'HUM', 'H1', 'H2', 'RH',
  // Pressure
  'PRES', 'P1', 'BAR',
  // Level / Distance
  'LVL', 'L1', 'LEVEL', 'DIST', 'D1',
  // Voltage
  'VOLT', 'V1', 'VBAT', 'VCC',
  // Current
  'CURR', 'I1', 'IBAT',
  // Power
  'POWER', 'PW1',
  // Light
  'LUX', 'LIGHT',
  // Gas
  'CO2', 'GAS', 'PPM', 'VOC',
  // Rotation / Speed
  'RPM', 'SPEED',
  // Weight
  'WEIGHT', 'W1',
  // Sound
  'NOISE', 'DB1',
  // Counter / Status / Boolean
  'COUNT', 'CNT', 'STATUS', 'ST1', 'BOOL', 'B1',
];

/// Maps common sensor ID prefix → default unit string.
const kOsSensorDefaultUnit = <String, String>{
  'TEMP': '°C', 'T1': '°C', 'T2': '°C', 'T3': '°C', 'TMP': '°C',
  'HUM': '%RH', 'H1': '%RH', 'H2': '%RH', 'RH': '%RH',
  'PRES': 'hPa', 'P1': 'hPa', 'BAR': 'hPa',
  'LVL': 'mm',  'L1': 'mm',  'LEVEL': 'mm', 'DIST': 'cm', 'D1': 'cm',
  'VOLT': 'V',  'V1': 'V',   'VBAT': 'mV', 'VCC': 'mV',
  'CURR': 'mA', 'I1': 'mA',  'IBAT': 'mA',
  'POWER': 'W', 'PW1': 'W',
  'LUX': 'lux', 'LIGHT': 'lux',
  'CO2': 'ppm', 'GAS': 'ppm', 'PPM': 'ppm', 'VOC': 'ppb',
  'RPM': 'rpm', 'SPEED': 'm/s',
  'WEIGHT': 'kg', 'W1': 'kg',
  'NOISE': 'dB', 'DB1': 'dB',
  'COUNT': 'cnt', 'CNT': 'cnt',
  'STATUS': 'raw', 'ST1': 'raw',
  'BOOL': 'bool', 'B1': 'bool',
};

