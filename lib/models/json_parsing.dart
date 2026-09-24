String requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  final text = switch (value) {
    String value => value.trim(),
    num value => value.toString(),
    _ => '',
  };
  if (text.isEmpty) throw FormatException('Invalid or missing field: $key');
  return text;
}

String? optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  if (value is num) return value.toString();
  throw FormatException('Invalid field: $key');
}

num requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid or missing field: $key');
}

num? optionalNumber(Map<String, dynamic> json, String key) {
  if (json[key] == null) return null;
  return requiredNumber(json, key);
}

bool booleanValue(Map<String, dynamic> json, String key,
    {bool fallback = false}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num && (value == 0 || value == 1)) return value == 1;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  throw FormatException('Invalid field: $key');
}

String oneOfText(
  Map<String, dynamic> json,
  String key,
  Set<String> allowed,
) {
  final value = requiredText(json, key);
  if (!allowed.contains(value)) throw FormatException('Invalid field: $key');
  return value;
}

String isoDateText(Map<String, dynamic> json, String key) {
  final value = requiredText(json, key);
  if (DateTime.tryParse(value) == null) {
    throw FormatException('Invalid field: $key');
  }
  return value;
}
