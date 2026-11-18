import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();

  /// Lekéri a felhasználó saját autóit stream-ként (`users/{uid}/cars`)
  Stream<List<CarModel>> getUserCarsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cars')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CarModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Új autó hozzáadása a felhasználóhoz
  Future<void> addCar(String uid, {
    required String brand,
    required String model,
    required String licensePlate,
    required String color,
    required String carType,
  }) async {
    final carMap = {
      'brand': brand.trim(),
      'model': model.trim(),
      'licensePlate': licensePlate.trim().toUpperCase(),
      'color': color.trim(),
      'carType': carType.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cars')
        .add(carMap);
  }

  /// Autó törlése
  Future<void> deleteCar(String uid, String carId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cars')
        .doc(carId)
        .delete();
  }
}
