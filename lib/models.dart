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
    this.officialLevel = '',
    this.actions = const [],
    this.updatedAt,
    this.effectiveAt,
    this.expiresAt,
    this.retrievedAt,
    this.referenceNumber = '',
    this.verificationStatus = 'supplementary',
    this.lifecycle = 'active',
    this.language = 'en',
    this.isCached = false,
  });
  final String id, title, description, severity, source, category, sourceUrl;
  final DateTime publishedAt;
  final GeoPoint? coordinates;
  final List<String> affectedAreas;
  final String officialLevel;
  final List<String> actions;
  final DateTime? updatedAt, effectiveAt, expiresAt, retrievedAt;
  final String referenceNumber, verificationStatus, lifecycle, language;
  final bool isCached;

  bool get isDemo => verificationStatus == 'demo' || source == 'OFFLINE DEMO';
  bool get isEnded => lifecycle == 'ended' || lifecycle == 'cancelled';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'issuedAt': publishedAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'effectiveAt': effectiveAt?.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'retrievedAt': retrievedAt?.toUtc().toIso8601String(),
    'visualPriority': severity,
    'officialLevel': officialLevel,
    'agency': source,
    'category': category,
    'sourceUrl': sourceUrl,
    'coordinates': coordinates?.toJson(),
    'affectedAreas': affectedAreas,
    'actions': actions,
    'referenceNumber': referenceNumber,
    'verificationStatus': verificationStatus,
    'lifecycle': lifecycle,
    'language': language,
    'isCached': isCached,
  };

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => DateTime.tryParse('${json[key] ?? ''}');
    final rawCoordinates = json['coordinates'];
    return AlertItem(
      id: '${json['id']}',
      title: '${json['title'] ?? 'Disaster advisory'}',
      description: '${json['description'] ?? ''}',
      publishedAt: date('issuedAt') ?? date('publishedAt') ?? DateTime.now(),
      updatedAt: date('updatedAt'),
      effectiveAt: date('effectiveAt'),
      expiresAt: date('expiresAt'),
      retrievedAt: date('retrievedAt'),
      severity: '${json['visualPriority'] ?? json['severity'] ?? 'Low'}',
      officialLevel: '${json['officialLevel'] ?? ''}',
      source: '${json['agency'] ?? json['source'] ?? 'Unknown source'}',
      category: '${json['category'] ?? 'other'}',
      sourceUrl: '${json['sourceUrl'] ?? ''}',
      coordinates: rawCoordinates is Map
          ? GeoPoint.fromJson(Map<String, dynamic>.from(rawCoordinates))
          : null,
      affectedAreas: List<String>.from(json['affectedAreas'] ?? const []),
      actions: List<String>.from(json['actions'] ?? const []),
      referenceNumber: '${json['referenceNumber'] ?? ''}',
      verificationStatus: '${json['verificationStatus'] ?? 'supplementary'}',
      lifecycle: '${json['lifecycle'] ?? 'active'}',
      language: '${json['language'] ?? 'en'}',
      isCached: json['isCached'] == true,
    );
  }

  AlertItem copyWith({bool? isCached}) => AlertItem(
    id: id,
    title: title,
    description: description,
    publishedAt: publishedAt,
    severity: severity,
    source: source,
    category: category,
    sourceUrl: sourceUrl,
    coordinates: coordinates,
    affectedAreas: affectedAreas,
    officialLevel: officialLevel,
    actions: actions,
    updatedAt: updatedAt,
    effectiveAt: effectiveAt,
    expiresAt: expiresAt,
    retrievedAt: retrievedAt,
    referenceNumber: referenceNumber,
    verificationStatus: verificationStatus,
    lifecycle: lifecycle,
    language: language,
    isCached: isCached ?? this.isCached,
  );
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
