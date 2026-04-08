/// A single decoded sensor reading from an OpenSynaptic packet body.
class SensorReading {
  final String sensorId;
  final String unit;
  final double value;
  final String state;
  final String rawB62;

  const SensorReading({
    required this.sensorId,
    required this.unit,
    required this.value,
    this.state = 'U',
    this.rawB62 = '',
  });

  @override
  String toString() => 'SensorReading($sensorId=$value $unit)';
}

