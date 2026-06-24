class SavedLocation {
  final String id;
  final String title;
  final double lat;
  final double lng;
  final double radius;
  final DateTime createdAt;
  final bool notificationEnabled;

  const SavedLocation({
    required this.id,
    required this.lat,
    required this.title,
    required this.lng,
    required this.radius,
    required this.createdAt,
    this.notificationEnabled = true,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Vị trí',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 25.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      notificationEnabled: json['notification_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'notification_enabled': notificationEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SavedLocation copyWith({
    String? id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
    DateTime? createdAt,
    bool? notificationEnabled,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      createdAt: createdAt ?? this.createdAt,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
