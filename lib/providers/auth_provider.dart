import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = false;
  bool _isAdmin = false;

  Map<String, dynamic>? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  
  // Dummy getter to match auth state checking in splash
  Map<String, dynamic>? get user => _userDetails;

  // In-memory list of registered users for simulation
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'uid': 'user_default',
      'nama': 'Najla Nafisha',
      'email': 'user@unila.ac.id',
      'telepon': '081234567890',
      'role': 'user',
    },
    {
      'uid': 'admin_default',
      'nama': 'Admin SiParku',
      'email': 'admin@unila.ac.id',
      'telepon': '089876543210',
      'role': 'admin',
    }
  ];

  AuthProvider() {
    _loadSession();
  }

  // Load session from SharedPreferences
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionStr = prefs.getString('siparku_session');
      if (sessionStr != null) {
        _userDetails = jsonDecode(sessionStr);
        _isAdmin = _userDetails?['role'] == 'admin';
        notifyListeners();
      }
    } catch (e) {
      print('Gagal memuat sesi: $e');
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSession(Map<String, dynamic> userMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('siparku_session', jsonEncode(userMap));
    } catch (e) {
      print('Gagal menyimpan sesi: $e');
    }
  }

  // Clear session from SharedPreferences
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('siparku_session');
    } catch (e) {
      print('Gagal menghapus sesi: $e');
    }
  }

  Future<String?> login(String email, String password, bool requestAdmin) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency

    try {
      final emailTrimmed = email.trim().toLowerCase();
      final passTrimmed = password.trim();

      // Find user matching email
      final userIndex = _mockUsers.indexWhere((u) => u['email'] == emailTrimmed);

      if (userIndex == -1) {
        _isLoading = false;
        notifyListeners();
        return 'Email tidak ditemukan. Coba daftarkan akun baru.';
      }

      final foundUser = Map<String, dynamic>.from(_mockUsers[userIndex]);

      // Simple password check (for mock, any password >= 6 characters is fine, or match '123456' for defaults)
      if (passTrimmed.length < 6) {
        _isLoading = false;
        notifyListeners();
        return 'Password minimal 6 karakter.';
      }

      // If they requested admin login, override or verify role
      if (requestAdmin) {
        foundUser['role'] = 'admin';
        _isAdmin = true;
      } else {
        _isAdmin = foundUser['role'] == 'admin';
      }

      _userDetails = foundUser;
      await _saveSession(foundUser);

      _isLoading = false;
      notifyListeners();
      return null; // Success
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
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network latency

    try {
      final emailTrimmed = email.trim().toLowerCase();
      
      // Check if email already registered in mock users
      if (_mockUsers.any((u) => u['email'] == emailTrimmed)) {
        _isLoading = false;
        notifyListeners();
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      }

      final String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final bool createAsAdmin = emailTrimmed.contains('admin');

      final Map<String, dynamic> newUser = {
        'uid': uid,
        'nama': name.trim(),
        'email': emailTrimmed,
        'telepon': phone.trim(),
        'role': createAsAdmin ? 'admin' : 'user',
      };

      // Add to mock list
      _mockUsers.add(newUser);
      _userDetails = newUser;
      _isAdmin = createAsAdmin;

      await _saveSession(newUser);

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    await _clearSession();
    _userDetails = null;
    _isAdmin = false;
    _isLoading = false;
    notifyListeners();
  }
}
