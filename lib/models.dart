class GeoPoint {
  const GeoPoint(
    this.latitude,
    this.longitude, [
    this.label = 'Current location',
  ]);
  final double latitude;
  final double longitude;
  final String label;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
  };
  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
    json['label'] ?? 'Current location',
  );
}

class AlertItem {
  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.severity,
    required this.source,
    required this.category,
    this.sourceUrl = '',
    this.coordinates,
    this.affectedAreas = const [],
  });
  final String id, title, description, severity, source, category, sourceUrl;
  final DateTime publishedAt;
  final GeoPoint? coordinates;
  final List<String> affectedAreas;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.condition,
    required this.modelCount,
    required this.rainVotes,
  });
  final Map<String, dynamic> current, hourly, daily;
  final String condition;
  final int modelCount, rainVotes;
}

class Shelter {
  const Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.coordinates,
    this.operator = '',
    this.phone = '',
    this.capacity = '',
    this.distanceKm,
    this.sourceUrl = 'https://www.openstreetmap.org',
  });
  final String id, name, address, type, operator, phone, capacity, sourceUrl;
  final GeoPoint coordinates;
  final double? distanceKm;
}

class KitItem {
  KitItem(this.id, this.label, {this.done = false});
  final String id, label;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'done': done};
  factory KitItem.fromJson(Map<String, dynamic> j) =>
      KitItem(j['id'], j['label'], done: j['done'] == true);
}

class SavedPlace {
  const SavedPlace(this.id, this.label, this.latitude, this.longitude);
  final String id, label;
  final double latitude, longitude;
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
  };
  factory SavedPlace.fromJson(Map<String, dynamic> j) => SavedPlace(
    j['id'],
    j['label'],
    (j['latitude'] as num).toDouble(),
    (j['longitude'] as num).toDouble(),
  );
}

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  final String id, name, phone, relationship;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: '${json['id']}',
        name: '${json['name']}',
        phone: '${json['phone']}',
        relationship: '${json['relationship'] ?? ''}',
      );

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) => EmergencyContact(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    relationship: relationship ?? this.relationship,
  );

  static String normalizedPhone(String value) {
    final trimmed = value.trim();
    final prefix = trimmed.startsWith('+') ? '+' : '';
    return '$prefix${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  static bool isValidPhone(String value) {
    final digits = normalizedPhone(value).replaceFirst('+', '');
    return digits.length >= 7 && digits.length <= 15;
  }
}
