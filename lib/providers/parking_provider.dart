import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parking_zone.dart';
import '../models/parking_slot.dart';
import '../models/parking_officer.dart';
import '../models/parking_report.dart';
import '../models/parking_history.dart';
import '../services/local_db_service.dart';

class ParkingProvider extends ChangeNotifier {
  final LocalDbService _localDb = LocalDbService.instance;

  final List<ParkingZone> _zones = [];
  final List<ParkingSlot> _slots = [];
  final List<ParkingOfficer> _officers = [];
  final List<ParkingReport> _reports = [];
  ParkingHistory? _activeParking;
  bool _isLoading = false;

  // Real-time GPS simulator coordinates (GSG Unila default)
  double _userLatitude = -5.3620;
  double _userLongitude = 105.2415;

  // Stream controllers to simulate Firestore reactive streams
  final _zonesStreamController = StreamController<List<ParkingZone>>.broadcast();
  final _slotsStreamController = StreamController<List<ParkingSlot>>.broadcast();
  final _officersStreamController = StreamController<List<ParkingOfficer>>.broadcast();
  final _reportsStreamController = StreamController<List<ParkingReport>>.broadcast();

  List<ParkingZone> get zones => _zones;
  List<ParkingSlot> get slots => _slots;
  List<ParkingOfficer> get officers => _officers;
  List<ParkingReport> get reports => _reports;
  ParkingHistory? get activeParking => _activeParking;
  bool get isLoading => _isLoading;
  double get userLatitude => _userLatitude;
  double get userLongitude => _userLongitude;

  // Mapped slots for quick UI checks
  List<ParkingSlot> _currentSlots = [];
  List<ParkingSlot> get currentSlots => _currentSlots;

  ParkingProvider() {
    _seedInitialMockData();
  }

  // ==================== SEED INITIAL MOCK DATA ====================
  void _seedInitialMockData() {
    _isLoading = true;

    // 1. Seed Zones
    _zones.addAll([
      ParkingZone(
        id: 'fmipa',
        nama: 'Parkiran FMIPA',
        deskripsi: 'Area parkir Fakultas Matematika dan Ilmu Pengetahuan Alam',
        latitude: -5.366613,
        longitude: 105.244286,
        totalSlots: 15,
      ),
      ParkingZone(
        id: 'fkip',
        nama: 'Parkiran FKIP',
        deskripsi: 'Area parkir Fakultas Keguruan dan Ilmu Pendidikan',
        latitude: -5.366752,
        longitude: 105.245564,
        totalSlots: 20,
      ),
      ParkingZone(
        id: 'fk',
        nama: 'Parkiran FK',
        deskripsi: 'Area parkir Fakultas Kedokteran',
        latitude: -5.367506,
        longitude: 105.246625,
        totalSlots: 10,
      ),
      ParkingZone(
        id: 'shuttle',
        nama: 'Parkiran Shuttle Unila',
        deskripsi: 'Area parkir dekat Shuttle Bus Universitas Lampung',
        latitude: -5.368093,
        longitude: 105.241798,
        totalSlots: 10,
      ),
      ParkingZone(
        id: 'feb',
        nama: 'Parkiran FEB',
        deskripsi: 'Area parkir Fakultas Ekonomi dan Bisnis',
        latitude: -5.362748,
        longitude: 105.243821,
        totalSlots: 15,
      ),
      ParkingZone(
        id: 'beringin',
        nama: 'Parkiran Beringin',
        deskripsi: 'Area parkir sekitar taman Beringin Unila',
        latitude: -5.365434,
        longitude: 105.243592,
        totalSlots: 25,
      ),
      ParkingZone(
        id: 'fisip',
        nama: 'Parkiran FISIP',
        deskripsi: 'Area parkir Fakultas Ilmu Sosial dan Ilmu Politik',
        latitude: -5.363123,
        longitude: 105.244257,
        totalSlots: 15,
      ),
      ParkingZone(
        id: 'fh',
        nama: 'Parkiran FH',
        deskripsi: 'Area parkir Fakultas Hukum',
        latitude: -5.363653,
        longitude: 105.244410,
        totalSlots: 15,
      ),
      ParkingZone(
        id: 'teknik',
        nama: 'Parkiran Teknik',
        deskripsi: 'Area parkir Fakultas Teknik',
        latitude: -5.362447,
        longitude: 105.241834,
        totalSlots: 20,
      ),
      ParkingZone(
        id: 'fp',
        nama: 'Parkiran FP',
        deskripsi: 'Area parkir Fakultas Pertanian',
        latitude: -5.364744,
        longitude: 105.241465,
        totalSlots: 20,
      ),
      ParkingZone(
        id: 'perpus',
        nama: 'Parkiran Perpus',
        deskripsi: 'Area parkir Perpustakaan Universitas Lampung',
        latitude: -5.3615,
        longitude: 105.2430,
        totalSlots: 12,
      ),
    ]);

    // 2. Seed Slots for each zone
    for (var zone in _zones) {
      for (int i = 1; i <= zone.totalSlots; i++) {
        final String slotId = '${zone.id}_slot_$i';
        final String kode = '${zone.id.substring(0, 1).toUpperCase()}$i';
        final bool isOccupied = i % 3 == 0; // Simulate some occupied spots
        final String type = i <= (zone.totalSlots / 2) ? 'Mobil' : 'Motor';

        _slots.add(ParkingSlot(
          id: slotId,
          zoneId: zone.id,
          kode: kode,
          isOccupied: isOccupied,
          vehiclePlate: isOccupied ? 'BE ${1000 + i} UN' : null,
          type: type,
        ));
      }
    }

    // 3. Seed Officers
    _officers.addAll([
      ParkingOfficer(
        id: 'officer_1',
        nama: 'Budi Santoso',
        email: 'budi.santoso@unila.ac.id',
        telepon: '081234567890',
        zoneId: 'rektorat',
        status: 'Aktif',
      ),
      ParkingOfficer(
        id: 'officer_2',
        nama: 'Ahmad Hidayat',
        email: 'ahmad.hidayat@unila.ac.id',
        telepon: '082198765432',
        zoneId: 'gsg',
        status: 'Aktif',
      ),
      ParkingOfficer(
        id: 'officer_3',
        nama: 'Siti Rahma',
        email: 'siti.rahma@unila.ac.id',
        telepon: '085377889900',
        zoneId: 'teknik',
        status: 'Aktif',
      ),
    ]);

    // 4. Seed Reports
    _reports.addAll([
      ParkingReport(
        id: 'report_1',
        userId: 'user_default',
        userEmail: 'user@unila.ac.id',
        deskripsi: 'Mobil Fortuner Hitam BE 8888 AA parkir serong menghalangi slot R3 Rektorat.',
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      )
    ]);

    _isLoading = false;
    _publishAllStreams();
  }

  void _publishAllStreams() {
    _zonesStreamController.add(List.from(_zones));
    _officersStreamController.add(List.from(_officers));
    _reportsStreamController.add(List.from(_reports));
    notifyListeners();
  }

  @override
  void dispose() {
    _zonesStreamController.close();
    _slotsStreamController.close();
    _officersStreamController.close();
    _reportsStreamController.close();
    super.dispose();
  }

  // ==================== REACTIVE STREAMS EMULATOR ====================
  Stream<List<ParkingZone>> streamZones() async* {
    yield List.from(_zones);
    yield* _zonesStreamController.stream;
  }
  
  Stream<List<ParkingSlot>> streamSlots(String zoneId) async* {
    final filtered = _slots.where((s) => s.zoneId == zoneId).toList();
    yield filtered;
    // We need to filter the broadcast stream as well
    await for (final slotsList in _slotsStreamController.stream) {
      yield slotsList.where((s) => s.zoneId == zoneId).toList();
    }
  }

  Stream<List<ParkingOfficer>> streamOfficers() async* {
    yield List.from(_officers);
    yield* _officersStreamController.stream;
  }

  Stream<List<ParkingReport>> streamReports() async* {
    yield List.from(_reports);
    yield* _reportsStreamController.stream;
  }

  // Mapped Stream user history (using local db instead of Firebase!)
  Stream<List<ParkingHistory>> streamUserHistory(String userId) {
    final controller = StreamController<List<ParkingHistory>>();
    _localDb.getHistoryList(userId).then((list) {
      controller.add(list);
    });
    return controller.stream;
  }

  // ==================== ZONA PARKIR CRUD ====================
  Future<void> addZone(ParkingZone zone) async {
    _zones.add(zone);
    // Auto generate slots
    for (int i = 1; i <= zone.totalSlots; i++) {
      final String slotId = '${zone.id}_slot_$i';
      final String kode = '${zone.id.substring(0, 1).toUpperCase()}$i';
      _slots.add(ParkingSlot(
        id: slotId,
        zoneId: zone.id,
        kode: kode,
        isOccupied: false,
        type: i % 2 == 0 ? 'Motor' : 'Mobil',
      ));
    }
    _publishAllStreams();
  }

  Future<void> updateZone(ParkingZone zone) async {
    final idx = _zones.indexWhere((z) => z.id == zone.id);
    if (idx != -1) {
      _zones[idx] = zone;
      _publishAllStreams();
    }
  }

  Future<void> deleteZone(String id) async {
    _zones.removeWhere((z) => z.id == id);
    _slots.removeWhere((s) => s.zoneId == id);
    _publishAllStreams();
  }

  // ==================== SLOT PARKIR CRUD ====================
  Future<void> addSlot(ParkingSlot slot) async {
    _slots.add(slot);
    // Trigger slots updates
    final filtered = _slots.where((s) => s.zoneId == slot.zoneId).toList();
    _slotsStreamController.add(filtered);
    _publishAllStreams();
  }

  Future<void> updateSlot(ParkingSlot slot) async {
    final idx = _slots.indexWhere((s) => s.id == slot.id);
    if (idx != -1) {
      _slots[idx] = slot;
      final filtered = _slots.where((s) => s.zoneId == slot.zoneId).toList();
      _slotsStreamController.add(filtered);
      _publishAllStreams();
    }
  }

  Future<void> deleteSlot(String id) async {
    final idx = _slots.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final zoneId = _slots[idx].zoneId;
      _slots.removeAt(idx);
      final filtered = _slots.where((s) => s.zoneId == zoneId).toList();
      _slotsStreamController.add(filtered);
      _publishAllStreams();
    }
  }

  // ==================== OFFICERS CRUD ====================
  Future<void> addOfficer(ParkingOfficer officer) async {
    _officers.add(officer);
    _publishAllStreams();
  }

  Future<void> updateOfficer(ParkingOfficer officer) async {
    final idx = _officers.indexWhere((o) => o.id == officer.id);
    if (idx != -1) {
      _officers[idx] = officer;
      _publishAllStreams();
    }
  }

  Future<void> deleteOfficer(String id) async {
    _officers.removeWhere((o) => o.id == id);
    _publishAllStreams();
  }

  // ==================== USER REPORTS CRUD ====================
  Future<void> addReport(ParkingReport report) async {
    _reports.insert(0, report);
    _publishAllStreams();
  }

  Future<void> updateReportStatus(String id, String newStatus) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final updated = ParkingReport(
        id: _reports[idx].id,
        userId: _reports[idx].userId,
        userEmail: _reports[idx].userEmail,
        deskripsi: _reports[idx].deskripsi,
        fotoUrl: _reports[idx].fotoUrl,
        status: newStatus,
        createdAt: _reports[idx].createdAt,
      );
      _reports[idx] = updated;
      _publishAllStreams();
    }
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    _publishAllStreams();
  }

  // ==================== GPS AND ACTIVE PARKING LOGIC ====================
  void updateUserLocation(double lat, double lng) {
    _userLatitude = lat;
    _userLongitude = lng;
    notifyListeners();
  }

  Future<void> fetchRealLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        notifyListeners();
      }
    } catch (e) {
      print('Gagal mengambil lokasi perangkat: $e');
    }
  }

  Future<void> loadActiveParking(String userId) async {
    _activeParking = await _localDb.getActiveParking(userId);
    notifyListeners();
  }

  void subscribeToSlots(String zoneId) {
    _currentSlots = _slots.where((s) => s.zoneId == zoneId).toList();
    _slotsStreamController.add(_currentSlots);
    notifyListeners();
  }

  // Park vehicle (Check-in)
  Future<String?> parkVehicle({
    required String userId,
    required String userEmail,
    required ParkingZone zone,
    required ParkingSlot slot,
  }) async {
    if (_activeParking != null) {
      return 'Anda masih memiliki parkir aktif di ${_activeParking!.zoneName} - ${_activeParking!.slotCode}';
    }

    try {
      final String historyId = 'history_${DateTime.now().millisecondsSinceEpoch}';
      
      final history = ParkingHistory(
        id: historyId,
        userId: userId,
        zoneName: zone.nama,
        slotCode: slot.kode,
        checkInTime: DateTime.now(),
        latitude: zone.latitude,
        longitude: zone.longitude,
        status: 'Aktif',
      );

      // Save locally (SQLite)
      await _localDb.insertParkingHistory(history);
      
      // Update in-memory slot status
      final slotIdx = _slots.indexWhere((s) => s.id == slot.id);
      if (slotIdx != -1) {
        _slots[slotIdx] = ParkingSlot(
          id: slot.id,
          zoneId: slot.zoneId,
          kode: slot.kode,
          isOccupied: true,
          vehiclePlate: 'BE ${1000 + DateTime.now().second % 9000} UN',
          type: slot.type,
        );
      }

      _activeParking = history;
      _currentSlots = _slots.where((s) => s.zoneId == zone.id).toList();
      _slotsStreamController.add(_currentSlots);
      _publishAllStreams();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Release vehicle (Check-out)
  Future<String?> checkoutVehicle(String userId) async {
    if (_activeParking == null) {
      return 'Anda tidak memiliki parkir aktif';
    }

    try {
      final checkoutTime = DateTime.now();
      final finishedHistory = ParkingHistory(
        id: _activeParking!.id,
        userId: _activeParking!.userId,
        zoneName: _activeParking!.zoneName,
        slotCode: _activeParking!.slotCode,
        checkInTime: _activeParking!.checkInTime,
        checkOutTime: checkoutTime,
        latitude: _activeParking!.latitude,
        longitude: _activeParking!.longitude,
        status: 'Selesai',
      );

      // Update locally (SQLite)
      await _localDb.updateParkingHistory(finishedHistory);

      // Free up slot in-memory
      final slotIdx = _slots.indexWhere(
        (s) => s.kode == _activeParking!.slotCode && _zones.firstWhere((z) => z.id == s.zoneId).nama == _activeParking!.zoneName,
      );

      if (slotIdx != -1) {
        final zoneId = _slots[slotIdx].zoneId;
        _slots[slotIdx] = ParkingSlot(
          id: _slots[slotIdx].id,
          zoneId: zoneId,
          kode: _slots[slotIdx].kode,
          isOccupied: false,
          vehiclePlate: null,
          type: _slots[slotIdx].type,
        );
        _currentSlots = _slots.where((s) => s.zoneId == zoneId).toList();
        _slotsStreamController.add(_currentSlots);
      }

      _activeParking = null;
      _publishAllStreams();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Algorithm to find nearest empty parking spot
  Map<String, dynamic>? findNearestSlot() {
    if (_zones.isEmpty) return null;

    ParkingZone? nearestZone;
    double minDistance = double.infinity;

    for (var zone in _zones) {
      double dist = Geolocator.distanceBetween(
        _userLatitude,
        _userLongitude,
        zone.latitude,
        zone.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestZone = zone;
      }
    }

    return {
      'zone': nearestZone,
      'distance': minDistance,
    };
  }
}
