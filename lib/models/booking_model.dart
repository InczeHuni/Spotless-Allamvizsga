import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String carId;
  final String carDetails; // pl. "BMW X5 - CJ 01 ABC"
  final String serviceId;
  final String serviceName;
  final double price;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'confirmed', 'completed', 'cancelled'

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.carId,
    required this.carDetails,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhone: map['userPhone'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      carDetails: map['carDetails'] as String? ?? '',
      serviceId: map['serviceId'] as String? ?? '',
      serviceName: map['serviceName'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'confirmed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'carId': carId,
      'carDetails': carDetails,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
    };
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
