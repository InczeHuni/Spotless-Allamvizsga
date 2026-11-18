import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/closed_day_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  /// Saját foglalások stream-je egy adott ügyfél számára
  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }

  /// Az összes foglalás stream-je (Admin számára)
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// Egy adott nap megerősített ('confirmed') foglalásainak stream-je (Anonim foglaltság megjelenítéshez)
  Stream<List<BookingModel>> getConfirmedBookingsForDayStream(DateTime date) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .where((b) =>
              b.startTime.year == date.year &&
              b.startTime.month == date.month &&
              b.startTime.day == date.day)
          .toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// Foglalás lemondása
  Future<void> cancelBooking(String bookingId) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'cancelled'});
  }

  /// Foglalás státuszának frissítése (Admin által)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus});
  }

  /// Időpontfoglalás Firestore Tranzakcióval & Szigorú Üzleti Szabályzat Ellenőrzéssel
  Future<void> createBookingWithTransaction({
    required String userId,
    required String userName,
    required String userPhone,
    required String carId,
    required String carDetails,
    required String serviceId,
    required String serviceName,
    required double price,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    // 1. ÜZLETI SZABÁLY: Vasárnapi tiltás (Kizárólag Vasárnap zárva!)
    if (startTime.weekday == DateTime.sunday) {
      throw Exception('A mosó vasárnap zárva tart!');
    }

    // 2. ÜZLETI SZABÁLY: Nyitvatartás (Hétköznap 08:00-17:00, Szombaton 08:00-14:00)
    final isSaturday = startTime.weekday == DateTime.saturday;
    final closeHour = isSaturday ? 14 : 17;

    final openTime = DateTime(startTime.year, startTime.month, startTime.day, 8, 0);
    final closeTime = DateTime(startTime.year, startTime.month, startTime.day, closeHour, 0);
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    if (startTime.isBefore(openTime)) {
      throw Exception('A nyitvatartás 08:00-kor kezdődik!');
    }

    if (endTime.isAfter(closeTime)) {
      final endHourStr = endTime.hour.toString().padLeft(2, '0');
      final endMinStr = endTime.minute.toString().padLeft(2, '0');
      final dayName = isSaturday ? 'Szombaton' : 'Hétköznap';
      throw Exception(
        'A foglalás nem nyúlhat túl a $closeHour:00 órás zárórán! ($dayName a nyitvatartás 08:00-$closeHour:00; a kiválasztott mosás befejezése $endHourStr:$endMinStr lenne).',
      );
    }

    // 3. ÜZLETI SZABÁLY: Zárvatartási nap ellenőrzése (`closed_days`)
    final dateKey = ClosedDayModel.formatDateKey(startTime);
    final closedDoc = await _firestore.collection('closed_days').doc(dateKey).get();
    if (closedDoc.exists && closedDoc.data() != null) {
      final reason = closedDoc.data()!['reason'] ?? 'Zárvatartás';
      throw Exception('A műhely ezen a napon zárva tart! (Indok: $reason)');
    }

    // 4. TRANZAKCIÓ: Ütközésmentes foglalás mentés (Race condition védelem)
    final CollectionReference bookingsRef = _firestore.collection('bookings');

    await _firestore.runTransaction((transaction) async {
      final QuerySnapshot existingSnapshot = await bookingsRef
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in existingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime existingStart = (data['startTime'] as Timestamp).toDate();
        final DateTime existingEnd = (data['endTime'] as Timestamp).toDate();

        // Intervallum-átfedés vizsgálata: (existingStart < newEnd && existingEnd > newStart)
        if (existingStart.isBefore(endTime) && existingEnd.isAfter(startTime)) {
          final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
          throw Exception(
            'Ez az időpont ($startStr) időközben foglalt lett! Kérjük, válasszon másik idősávot.',
          );
        }
      }

      final DocumentReference newBookingDoc = bookingsRef.doc();

      transaction.set(newBookingDoc, {
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
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
