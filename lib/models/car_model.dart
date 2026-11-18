class CarModel {
  final String id;
  final String brand;
  final String model;
  final String licensePlate;
  final String color;
  final String carType; // 'sedan', 'suv', 'hatchback', 'coupe', 'van', etc.

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.color,
    required this.carType,
  });

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      id: id,
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      color: map['color'] as String? ?? '',
      carType: map['carType'] as String? ?? 'sedan',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'licensePlate': licensePlate,
      'color': color,
      'carType': carType,
    };
  }

  String get displayName => '$brand $model ($licensePlate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
