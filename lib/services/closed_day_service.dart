import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/closed_day_model.dart';

class ClosedDayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ClosedDayService _instance = ClosedDayService._internal();
  factory ClosedDayService() => _instance;
  ClosedDayService._internal();

  /// Az összes zárvatartási nap stream-je
  Stream<List<ClosedDayModel>> getClosedDaysStream() {
    return _firestore
        .collection('closed_days')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ClosedDayModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Új zárvatartási nap felvétele
  Future<void> addClosedDay({
    required DateTime date,
    required String reason,
    required String adminUid,
  }) async {
    final dateKey = ClosedDayModel.formatDateKey(date);
    final model = ClosedDayModel(
      date: dateKey,
      reason: reason.trim().isEmpty ? 'Zárvatartás' : reason.trim(),
      createdBy: adminUid,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('closed_days')
        .doc(dateKey)
        .set(model.toMap());
  }

  /// Zárvatartási nap törlése (újragyitása)
  Future<void> deleteClosedDay(String dateKey) async {
    await _firestore
        .collection('closed_days')
        .doc(dateKey)
        .delete();
  }

  /// Ellenőrzi, hogy egy adott nap zárva van-e
  Future<ClosedDayModel?> getClosedDayInfo(DateTime date) async {
    final dateKey = ClosedDayModel.formatDateKey(date);
    final doc = await _firestore.collection('closed_days').doc(dateKey).get();
    if (doc.exists && doc.data() != null) {
      return ClosedDayModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
