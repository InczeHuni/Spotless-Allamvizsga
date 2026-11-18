import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ServiceService _instance = ServiceService._internal();
  factory ServiceService() => _instance;
  ServiceService._internal();

  /// Csak az aktív szolgáltatások stream-je az ügyfeleknek
  Stream<List<ServiceModel>> getActiveServicesStream() {
    return _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Az összes szolgáltatás stream-je az admin számára
  Stream<List<ServiceModel>> getAllServicesStream() {
    return _firestore
        .collection('services')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Új szolgáltatás hozzáadása (Admin)
  Future<void> addService({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    bool isActive = true,
  }) async {
    final map = {
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('services').add(map);
  }

  /// Szolgáltatás frissítése (Admin)
  Future<void> updateService(ServiceModel service) async {
    await _firestore
        .collection('services')
        .doc(service.id)
        .update(service.toMap());
  }

  /// Szolgáltatás aktív/inaktív státuszának átkapcsolása (Admin)
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    await _firestore
        .collection('services')
        .doc(serviceId)
        .update({'isActive': isActive});
  }

  /// Kezdeti minta szolgáltatások feltöltése, ha a 'services' gyűjtemény még üres.
  Future<void> seedInitialServicesIfEmpty() async {
    final snapshot = await _firestore.collection('services').get();
    if (snapshot.docs.isEmpty) {
      final initialServices = [
        {
          'name': 'Külső-belső mosás',
          'description': 'Alapos külső samponos mosás, porszívózás, műanyagápolás.',
          'price': 85.0,
          'durationMinutes': 45,
          'isActive': true,
        },
        {
          'name': 'Prémium polírozás & Kerámia bevonat',
          'description': 'Karcolások eltávolítása, tartós felületvédelem és ragyogó fény.',
          'price': 240.0,
          'durationMinutes': 120,
          'isActive': true,
        },
        {
          'name': 'Motortér mosás & Kárpittisztítás',
          'description': 'Mélytisztítás és szagtalanítás, higiénikus belső tér.',
          'price': 145.0,
          'durationMinutes': 60,
          'isActive': true,
        },
      ];

      for (var service in initialServices) {
        await _firestore.collection('services').add(service);
      }
    }
  }
}
