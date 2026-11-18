import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream a felhasználó Firestore dokumentumához
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Jövőbeli lekérés a felhasználó adatára
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Regisztráció Firebase Auth-ban és elmentés a Firestore 'users/{uid}' gyűjteménybe.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'client',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      final userModel = UserModel(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception('Regisztrációs hiba: ${e.toString()}');
    }
  }

  /// Bejelentkezés Firebase Auth-ban
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception('Bejelentkezési hiba: ${e.toString()}');
    }
  }

  /// Kijelentkezés
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nem található fiók ezzel az e-mail címmel!';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Hibás e-mail cím vagy jelszó!';
      case 'email-already-in-use':
        return 'Ezzel az e-mail címmel már regisztráltak egy fiókot!';
      case 'invalid-email':
        return 'Érvénytelen e-mail cím formátum!';
      case 'weak-password':
        return 'A jelszónak legalább 6 karakterből kell állnia!';
      default:
        return 'Autentikációs hiba ($code). Kérjük, próbálja újra.';
    }
  }
}
