class WeatherConfig {
  WeatherConfig.fromJson(Map<String, dynamic> j)
    : enabled = j['enabled'] == true,
      mode = j['mode'] as String,
      hasKey = j['has_key'] == true;
  final bool enabled, hasKey;
  final String mode;
}

class WeatherReport {
  WeatherReport.fromJson(Map<String, dynamic> j)
    : status = j['status'] as String,
      message = j['message'] as String,
      current = Map<String, dynamic>.from(j['current'] as Map),
      forecast = (j['forecast'] as List).cast<Map<String, dynamic>>(),
      observedAt = j['observed_at'] as String?,
      cached = j['cached'] == true;
  WeatherReport.unavailable(this.message)
    : status = 'unavailable',
      current = const {},
      forecast = const [],
      observedAt = null,
      cached = false;
  final String status, message;
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> forecast;
  final String? observedAt;
  final bool cached;
  String value(String key) =>
      current[key] is num ? (current[key] as num).toStringAsFixed(1) : '--';
}
