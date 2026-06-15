import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userDetails;
  bool _isLoading = false;
  bool _isAdmin = false;

  Map<String, dynamic>? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  Map<String, dynamic>? get user => _userDetails;

  AuthProvider() {
    _seedDefaultAccounts();
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserDetails(firebaseUser.uid);
      } else {
        _userDetails = null;
        _isAdmin = false;
        notifyListeners();
      }
    });
  }

  // Buat akun default admin & user otomatis jika belum ada
  Future<void> _seedDefaultAccounts() async {
    await _createDefaultAccount(
      email: 'admin@unila.ac.id',
      password: 'admin123',
      nama: 'Admin SiParku',
      telepon: '089876543210',
      role: 'admin',
    );
    await _createDefaultAccount(
      email: 'user@unila.ac.id',
      password: 'user123',
      nama: 'Najla Nafisha',
      telepon: '081234567890',
      role: 'user',
    );
  }

  Future<void> _createDefaultAccount({
    required String email,
    required String password,
    required String nama,
    required String telepon,
    required String role,
  }) async {
    try {
      // Coba login dulu — kalau berhasil, akun sudah ada
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Pastikan data Firestore ada
      final doc = await _db.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(result.user!.uid).set({
          'nama': nama,
          'email': email,
          'telepon': telepon,
          'role': role,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        // Akun belum ada, buat baru
        try {
          final newResult = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          await _db.collection('users').doc(newResult.user!.uid).set({
            'nama': nama,
            'email': email,
            'telepon': telepon,
            'role': role,
            'created_at': FieldValue.serverTimestamp(),
          });
          await _auth.signOut();
          debugPrint('✅ Akun default dibuat: $email');
        } catch (createErr) {
          debugPrint('Gagal buat akun $email: $createErr');
        }
      }
    } catch (e) {
      debugPrint('Error seed akun $email: $e');
    }
  }

  Future<void> _loadUserDetails(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userDetails = {'uid': uid, ...doc.data()!};
        _isAdmin = _userDetails?['role'] == 'admin';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal memuat user details: $e');
    }
  }

  Future<String?> login(String email, String password, bool requestAdmin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      await _loadUserDetails(credential.user!.uid);

      // Override role jika login sebagai admin
      if (requestAdmin) {
        _isAdmin = true;
        _userDetails?['role'] = 'admin';
      }

      _isLoading = false;
      notifyListeners();
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak ditemukan. Coba daftarkan akun baru.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Password salah. Coba lagi.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        default:
          return 'Login gagal: ${e.message}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final emailTrimmed = email.trim().toLowerCase();
      final bool createAsAdmin = emailTrimmed.contains('admin');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailTrimmed,
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final Map<String, dynamic> newUser = {
        'nama': name.trim(),
        'email': emailTrimmed,
        'telepon': phone.trim(),
        'role': createAsAdmin ? 'admin' : 'user',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Simpan ke Firestore
      await _db.collection('users').doc(uid).set(newUser);

      _userDetails = {'uid': uid, ...newUser};
      _isAdmin = createAsAdmin;

      _isLoading = false;
      notifyListeners();
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan gunakan email lain.';
        case 'weak-password':
          return 'Password terlalu lemah. Minimal 6 karakter.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        default:
          return 'Registrasi gagal: ${e.message}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _auth.signOut();
    _userDetails = null;
    _isAdmin = false;
    _isLoading = false;
    notifyListeners();
  }
}
