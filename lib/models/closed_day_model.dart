import 'package:cloud_firestore/cloud_firestore.dart';

class ClosedDayModel {
  final String date; // 'YYYY-MM-DD'
  final String reason;
  final String createdBy;
  final DateTime? createdAt;

  ClosedDayModel({
    required this.date,
    required this.reason,
    required this.createdBy,
    this.createdAt,
  });

  factory ClosedDayModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClosedDayModel(
      date: docId,
      reason: map['reason'] as String? ?? 'Zárvatartás',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'reason': reason,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  static String formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
