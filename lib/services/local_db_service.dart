import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_history.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();

  LocalDbService._init();

  static const String _historyKey = 'parking_history_data';

  Future<List<ParkingHistory>> _getAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ParkingHistory.fromMap(json)).toList();
  }

  Future<void> _saveAllHistory(List<ParkingHistory> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((h) => h.toMap()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<int> insertParkingHistory(ParkingHistory history) async {
    final list = await _getAllHistory();
    // replace if conflict
    list.removeWhere((item) => item.id == history.id);
    list.insert(0, history);
    await _saveAllHistory(list);
    return 1;
  }

  Future<ParkingHistory?> getActiveParking(String userId) async {
    final list = await _getAllHistory();
    try {
      return list.firstWhere((h) => h.userId == userId && h.status == 'Aktif');
    } catch (_) {
      return null;
    }
  }

  Future<List<ParkingHistory>> getHistoryList(String userId) async {
    final list = await _getAllHistory();
    final userList = list.where((h) => h.userId == userId).toList();
    userList.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return userList;
  }

  Future<int> updateParkingHistory(ParkingHistory history) async {
    final list = await _getAllHistory();
    final idx = list.indexWhere((h) => h.id == history.id);
    if (idx != -1) {
      list[idx] = history;
      await _saveAllHistory(list);
      return 1;
    }
    return 0;
  }

  Future<int> deleteHistoryItem(String id) async {
    final list = await _getAllHistory();
    final initialLength = list.length;
    list.removeWhere((h) => h.id == id);
    if (list.length < initialLength) {
      await _saveAllHistory(list);
      return 1;
    }
    return 0;
  }

  Future close() async {
    // Nothing to close for SharedPreferences
  }
}
