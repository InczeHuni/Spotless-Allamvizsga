class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price; // LEI-ben
  final int durationMinutes;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: map['durationMinutes'] as int? ?? 30,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
    };
  }

  String get formattedPrice => '${price.toStringAsFixed(0)} LEI';
  String get formattedDuration => '$durationMinutes perc';
}
