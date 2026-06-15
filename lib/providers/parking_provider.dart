import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_zone.dart';
import '../models/parking_slot.dart';
import '../models/parking_officer.dart';
import '../models/parking_report.dart';
import '../models/parking_history.dart';
import '../services/local_db_service.dart';


class ParkingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDbService _localDb = LocalDbService.instance;

  final List<ParkingZone> _zones = [];
  final List<ParkingSlot> _slots = [];
  final List<ParkingOfficer> _officers = [];
  final List<ParkingReport> _reports = [];
  ParkingHistory? _activeParking;
  bool _isLoading = false;

  double _userLatitude = -5.3620;
  double _userLongitude = 105.2415;

  List<ParkingZone> get zones => _zones;
  List<ParkingSlot> get slots => _slots;
  List<ParkingOfficer> get officers => _officers;
  List<ParkingReport> get reports => _reports;
  ParkingHistory? get activeParking => _activeParking;
  bool get isLoading => _isLoading;
  double get userLatitude => _userLatitude;
  double get userLongitude => _userLongitude;

  List<ParkingSlot> _currentSlots = [];
  List<ParkingSlot> get currentSlots => _currentSlots;

  StreamSubscription? _zonesSub;
  StreamSubscription? _slotsSub;
  StreamSubscription? _officersSub;
  StreamSubscription? _reportsSub;
  StreamSubscription<Position>? _locationSub;

  ParkingProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _seedIfEmpty();
    await _forceUpdateCoordinates();
    _subscribeToFirestore();
  }

  // ==================== SEED DATA AWAL KE FIRESTORE ====================
  Future<void> _seedIfEmpty() async {
    try {
      final zonesSnap = await _db.collection('parking_zones').limit(1).get();
      if (zonesSnap.docs.isNotEmpty) return; // Sudah ada data, skip

      debugPrint('Seeding data awal ke Firestore...');
      final batch = _db.batch();

      // Seed zones
      // Koordinat akurat berdasarkan posisi nyata kampus Unila
      final seedZones = [
        {'id': 'fmipa',   'nama': 'Parkiran FMIPA',           'deskripsi': 'Area parkir Fakultas Matematika dan IPA',                  'latitude': -5.36720, 'longitude': 105.24480, 'totalSlots': 15},
        {'id': 'fkip',   'nama': 'Parkiran FKIP',            'deskripsi': 'Area parkir Fakultas Keguruan dan Ilmu Pendidikan',       'latitude': -5.36490, 'longitude': 105.24625, 'totalSlots': 20},
        {'id': 'fk',     'nama': 'Parkiran FK',              'deskripsi': 'Area parkir Fakultas Kedokteran',                          'latitude': -5.36635, 'longitude': 105.24720, 'totalSlots': 10},
        {'id': 'shuttle','nama': 'Parkiran Rektorat/Shuttle','deskripsi': 'Area parkir dekat Rektorat dan Shuttle Bus Unila',         'latitude': -5.36050, 'longitude': 105.24175, 'totalSlots': 10},
        {'id': 'feb',    'nama': 'Parkiran FEB',             'deskripsi': 'Area parkir Fakultas Ekonomi dan Bisnis',                  'latitude': -5.36245, 'longitude': 105.24435, 'totalSlots': 15},
        {'id': 'beringin','nama': 'Parkiran Taman Beringin', 'deskripsi': 'Area parkir sekitar Masjid Al-Wasi\'i dan Taman Beringin',  'latitude': -5.36440, 'longitude': 105.24340, 'totalSlots': 25},
        {'id': 'fisip',  'nama': 'Parkiran FISIP',           'deskripsi': 'Area parkir Fakultas Ilmu Sosial dan Ilmu Politik',        'latitude': -5.36285, 'longitude': 105.24460, 'totalSlots': 15},
        {'id': 'fh',     'nama': 'Parkiran FH',              'deskripsi': 'Area parkir Fakultas Hukum',                               'latitude': -5.36300, 'longitude': 105.24380, 'totalSlots': 15},
        {'id': 'teknik', 'nama': 'Parkiran FT',              'deskripsi': 'Area parkir Fakultas Teknik',                              'latitude': -5.36410, 'longitude': 105.24140, 'totalSlots': 20},
        {'id': 'fp',     'nama': 'Parkiran FP',              'deskripsi': 'Area parkir Fakultas Pertanian',                           'latitude': -5.36560, 'longitude': 105.24115, 'totalSlots': 20},
        {'id': 'perpus', 'nama': 'Parkiran Perpustakaan',    'deskripsi': 'Area parkir Perpustakaan Pusat Universitas Lampung',       'latitude': -5.36170, 'longitude': 105.24280, 'totalSlots': 12},
      ];

      for (final z in seedZones) {
        final ref = _db.collection('parking_zones').doc(z['id'] as String);
        batch.set(ref, {
          'nama': z['nama'],
          'deskripsi': z['deskripsi'],
          'latitude': z['latitude'],
          'longitude': z['longitude'],
          'totalSlots': z['totalSlots'],
        });

        // Seed slots untuk setiap zone
        final totalSlots = z['totalSlots'] as int;
        final zoneId = z['id'] as String;
        for (int i = 1; i <= totalSlots; i++) {
          final slotId = '${zoneId}_slot_$i';
          final kode = '${zoneId.substring(0, 1).toUpperCase()}$i';
          final isOccupied = i % 3 == 0;
          final type = i <= (totalSlots / 2) ? 'Mobil' : 'Motor';
          final slotRef = _db.collection('parking_slots').doc(slotId);
          batch.set(slotRef, {
            'zoneId': zoneId,
            'kode': kode,
            'isOccupied': isOccupied,
            'vehiclePlate': isOccupied ? 'BE ${1000 + i} UN' : null,
            'type': type,
          });
        }
      }

      // Seed officers
      final seedOfficers = [
        {'id': 'officer_1', 'nama': 'Budi Santoso', 'email': 'budi.santoso@unila.ac.id', 'telepon': '081234567890', 'zoneId': 'fmipa', 'status': 'Aktif'},
        {'id': 'officer_2', 'nama': 'Ahmad Hidayat', 'email': 'ahmad.hidayat@unila.ac.id', 'telepon': '082198765432', 'zoneId': 'fkip', 'status': 'Aktif'},
        {'id': 'officer_3', 'nama': 'Siti Rahma', 'email': 'siti.rahma@unila.ac.id', 'telepon': '085377889900', 'zoneId': 'teknik', 'status': 'Aktif'},
      ];
      for (final o in seedOfficers) {
        final ref = _db.collection('parking_officers').doc(o['id'] as String);
        batch.set(ref, {
          'nama': o['nama'],
          'email': o['email'],
          'telepon': o['telepon'],
          'zoneId': o['zoneId'],
          'status': o['status'],
        });
      }

      // Seed report
      batch.set(_db.collection('parking_reports').doc('report_1'), {
        'userId': 'seed_user',
        'userEmail': 'user@unila.ac.id',
        'deskripsi': 'Mobil Fortuner Hitam BE 8888 AA parkir serong menghalangi slot',
        'fotoUrl': null,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('Seeding selesai!');
    } catch (e) {
      debugPrint('Gagal seeding: $e');
    }
  }

  // Update koordinat zona yang sudah ada (untuk fix data lama)
  Future<void> _forceUpdateCoordinates() async {
    final correctCoords = {
      'fmipa':    {'latitude': -5.36720, 'longitude': 105.24480},
      'fkip':     {'latitude': -5.36490, 'longitude': 105.24625},
      'fk':       {'latitude': -5.36635, 'longitude': 105.24720},
      // Shuttle: Parkir Terpadu area near Masjid Al-Wasi'i / UPT Bahasa
      'shuttle':  {'latitude': -5.36480, 'longitude': 105.24085},
      'feb':      {'latitude': -5.36245, 'longitude': 105.24435},
      'beringin': {'latitude': -5.36440, 'longitude': 105.24340},
      'fisip':    {'latitude': -5.36285, 'longitude': 105.24460},
      'fh':       {'latitude': -5.36300, 'longitude': 105.24380},
      // Teknik: FT Unila bangunan dekanat, sisi barat daya kampus
      'teknik':   {'latitude': -5.36650, 'longitude': 105.23995},
      'fp':       {'latitude': -5.36560, 'longitude': 105.24115},
      'perpus':   {'latitude': -5.36170, 'longitude': 105.24280},
    };
    try {
      final batch = _db.batch();
      for (final entry in correctCoords.entries) {
        final ref = _db.collection('parking_zones').doc(entry.key);
        batch.update(ref, entry.value);
      }
      await batch.commit();
      debugPrint('✅ Koordinat zona diperbarui');
    } catch (e) {
      debugPrint('Skip update koordinat: $e');
    }
  }

  // ==================== SUBSCRIBE KE FIRESTORE REAL-TIME ====================
  void _subscribeToFirestore() {
    // Zones
    _zonesSub = _db.collection('parking_zones').snapshots().listen((snap) {
      _zones.clear();
      for (final doc in snap.docs) {
        _zones.add(ParkingZone(
          id: doc.id,
          nama: doc['nama'],
          deskripsi: doc['deskripsi'],
          latitude: (doc['latitude'] as num).toDouble(),
          longitude: (doc['longitude'] as num).toDouble(),
          totalSlots: doc['totalSlots'],
        ));
      }
      _isLoading = false;
      notifyListeners();
    });

    // Slots
    _slotsSub = _db.collection('parking_slots').snapshots().listen((snap) {
      _slots.clear();
      for (final doc in snap.docs) {
        _slots.add(ParkingSlot(
          id: doc.id,
          zoneId: doc['zoneId'],
          kode: doc['kode'],
          isOccupied: doc['isOccupied'] ?? false,
          vehiclePlate: doc['vehiclePlate'],
          type: doc['type'],
        ));
      }
      // Refresh currentSlots jika ada zone yang sedang aktif
      if (_currentSlots.isNotEmpty) {
        final zoneId = _currentSlots.first.zoneId;
        _currentSlots = _slots.where((s) => s.zoneId == zoneId).toList();
      }
      notifyListeners();
    });

    // Officers
    _officersSub = _db.collection('parking_officers').snapshots().listen((snap) {
      _officers.clear();
      for (final doc in snap.docs) {
        _officers.add(ParkingOfficer(
          id: doc.id,
          nama: doc['nama'],
          email: doc['email'],
          telepon: doc['telepon'],
          zoneId: doc['zoneId'],
          status: doc['status'],
        ));
      }
      notifyListeners();
    });

    // Reports
    _reportsSub = _db
        .collection('parking_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _reports.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        _reports.add(ParkingReport(
          id: doc.id,
          userId: data['userId'] ?? '',
          userEmail: data['userEmail'] ?? '',
          deskripsi: data['deskripsi'] ?? '',
          fotoUrl: data['fotoUrl'],
          status: data['status'] ?? 'Pending',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _zonesSub?.cancel();
    _slotsSub?.cancel();
    _officersSub?.cancel();
    _reportsSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  // ==================== REALTIME LOCATION TRACKING ====================
  Future<void> startLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Izin lokasi ditolak permanen');
        return;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Ambil posisi awal langsung
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _userLatitude = pos.latitude;
          _userLongitude = pos.longitude;
          notifyListeners();
        } catch (_) {}

        // Stream update setiap gerak 10 meter atau setiap 3 detik
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
        _locationSub?.cancel();
        _locationSub = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position pos) {
          _userLatitude = pos.latitude;
          _userLongitude = pos.longitude;
          notifyListeners();
          debugPrint('📍 Lokasi update: ${pos.latitude}, ${pos.longitude}');
        }, onError: (e) {
          debugPrint('Error lokasi stream: $e');
        });
        debugPrint('✅ Location tracking dimulai');
      }
    } catch (e) {
      debugPrint('Gagal start location tracking: $e');
    }
  }

  void stopLocationTracking() {
    _locationSub?.cancel();
    _locationSub = null;
    debugPrint('🛑 Location tracking dihentikan');
  }

  // ==================== REACTIVE STREAMS (Firestore) ====================
  Stream<List<ParkingZone>> streamZones() {
    return _db.collection('parking_zones').snapshots().map((snap) =>
        snap.docs.map((doc) => ParkingZone(
              id: doc.id,
              nama: doc['nama'],
              deskripsi: doc['deskripsi'],
              latitude: (doc['latitude'] as num).toDouble(),
              longitude: (doc['longitude'] as num).toDouble(),
              totalSlots: doc['totalSlots'],
            )).toList());
  }

  Stream<List<ParkingSlot>> streamSlots(String zoneId) {
    return _db
        .collection('parking_slots')
        .where('zoneId', isEqualTo: zoneId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ParkingSlot(
              id: doc.id,
              zoneId: doc['zoneId'],
              kode: doc['kode'],
              isOccupied: doc['isOccupied'] ?? false,
              vehiclePlate: doc['vehiclePlate'],
              type: doc['type'],
            )).toList());
  }

  Stream<List<ParkingOfficer>> streamOfficers() {
    return _db.collection('parking_officers').snapshots().map((snap) =>
        snap.docs.map((doc) => ParkingOfficer(
              id: doc.id,
              nama: doc['nama'],
              email: doc['email'],
              telepon: doc['telepon'],
              zoneId: doc['zoneId'],
              status: doc['status'],
            )).toList());
  }

  Stream<List<ParkingReport>> streamReports() {
    return _db
        .collection('parking_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return ParkingReport(
                id: doc.id,
                userId: data['userId'] ?? '',
                userEmail: data['userEmail'] ?? '',
                deskripsi: data['deskripsi'] ?? '',
                fotoUrl: data['fotoUrl'],
                status: data['status'] ?? 'Pending',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  // Riwayat parkir dari Firestore (realtime) — sort client-side, no index needed
  Stream<List<ParkingHistory>> streamUserHistory(String userId) {
    return _db
        .collection('parking_history')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            return ParkingHistory(
              id: doc.id,
              userId: data['userId'] ?? '',
              zoneName: data['zoneName'] ?? '',
              slotCode: data['slotCode'] ?? '',
              checkInTime: (data['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
              checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
              latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
              status: data['status'] ?? 'Aktif',
            );
          }).toList();
          // Sort client-side: terbaru dulu
          list.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
          return list;
        });
  }

  // ==================== ZONA PARKIR CRUD ====================
  Future<void> addZone(ParkingZone zone) async {
    await _db.collection('parking_zones').doc(zone.id).set({
      'nama': zone.nama,
      'deskripsi': zone.deskripsi,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'totalSlots': zone.totalSlots,
    });
    // Auto-generate slots
    final batch = _db.batch();
    for (int i = 1; i <= zone.totalSlots; i++) {
      final slotId = '${zone.id}_slot_$i';
      final kode = '${zone.id.substring(0, 1).toUpperCase()}$i';
      batch.set(_db.collection('parking_slots').doc(slotId), {
        'zoneId': zone.id,
        'kode': kode,
        'isOccupied': false,
        'vehiclePlate': null,
        'type': i % 2 == 0 ? 'Motor' : 'Mobil',
      });
    }
    await batch.commit();
  }

  Future<void> updateZone(ParkingZone zone) async {
    await _db.collection('parking_zones').doc(zone.id).update({
      'nama': zone.nama,
      'deskripsi': zone.deskripsi,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'totalSlots': zone.totalSlots,
    });
  }

  Future<void> deleteZone(String id) async {
    // Delete zone
    await _db.collection('parking_zones').doc(id).delete();
    // Delete related slots
    final slotsSnap = await _db.collection('parking_slots').where('zoneId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in slotsSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==================== SLOT PARKIR CRUD ====================
  Future<void> addSlot(ParkingSlot slot) async {
    await _db.collection('parking_slots').doc(slot.id).set({
      'zoneId': slot.zoneId,
      'kode': slot.kode,
      'isOccupied': slot.isOccupied,
      'vehiclePlate': slot.vehiclePlate,
      'type': slot.type,
    });
  }

  Future<void> updateSlot(ParkingSlot slot) async {
    await _db.collection('parking_slots').doc(slot.id).update({
      'zoneId': slot.zoneId,
      'kode': slot.kode,
      'isOccupied': slot.isOccupied,
      'vehiclePlate': slot.vehiclePlate,
      'type': slot.type,
    });
  }

  Future<void> deleteSlot(String id) async {
    await _db.collection('parking_slots').doc(id).delete();
  }

  // ==================== OFFICERS CRUD ====================
  Future<void> addOfficer(ParkingOfficer officer) async {
    await _db.collection('parking_officers').doc(officer.id).set({
      'nama': officer.nama,
      'email': officer.email,
      'telepon': officer.telepon,
      'zoneId': officer.zoneId,
      'status': officer.status,
    });
  }

  Future<void> updateOfficer(ParkingOfficer officer) async {
    await _db.collection('parking_officers').doc(officer.id).update({
      'nama': officer.nama,
      'email': officer.email,
      'telepon': officer.telepon,
      'zoneId': officer.zoneId,
      'status': officer.status,
    });
  }

  Future<void> deleteOfficer(String id) async {
    await _db.collection('parking_officers').doc(id).delete();
  }

  // ==================== USER REPORTS CRUD ====================
  Future<void> addReport(ParkingReport report) async {
    await _db.collection('parking_reports').doc(report.id).set({
      'userId': report.userId,
      'userEmail': report.userEmail,
      'deskripsi': report.deskripsi,
      'fotoUrl': report.fotoUrl,
      'status': report.status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateReportStatus(String id, String newStatus) async {
    await _db.collection('parking_reports').doc(id).update({'status': newStatus});
  }

  Future<void> deleteReport(String id) async {
    await _db.collection('parking_reports').doc(id).delete();
  }

  // ==================== GPS & ACTIVE PARKING ====================
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
      debugPrint('Gagal mengambil lokasi: $e');
    }
  }

  // Load active parking dari Firestore
  Future<void> loadActiveParking(String userId) async {
    try {
      final snap = await _db
          .collection('parking_history')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Aktif')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        _activeParking = ParkingHistory(
          id: snap.docs.first.id,
          userId: data['userId'] ?? '',
          zoneName: data['zoneName'] ?? '',
          slotCode: data['slotCode'] ?? '',
          checkInTime: (data['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          checkOutTime: null,
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          status: 'Aktif',
        );
      } else {
        _activeParking = null;
      }
    } catch (e) {
      debugPrint('Gagal load active parking: $e');
      _activeParking = null;
    }
    notifyListeners();
  }

  void subscribeToSlots(String zoneId) {
    _currentSlots = _slots.where((s) => s.zoneId == zoneId).toList();
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
      final String historyId = 'history_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      // Simpan riwayat ke Firestore
      await _db.collection('parking_history').doc(historyId).set({
        'userId': userId,
        'userEmail': userEmail,
        'zoneName': zone.nama,
        'slotCode': slot.kode,
        'checkInTime': Timestamp.fromDate(now),
        'checkOutTime': null,
        'latitude': zone.latitude,
        'longitude': zone.longitude,
        'status': 'Aktif',
      });

      // Update slot di Firestore
      await _db.collection('parking_slots').doc(slot.id).update({
        'isOccupied': true,
        'vehiclePlate': 'BE ${1000 + now.second % 9000} UN',
      });

      final history = ParkingHistory(
        id: historyId,
        userId: userId,
        zoneName: zone.nama,
        slotCode: slot.kode,
        checkInTime: now,
        latitude: zone.latitude,
        longitude: zone.longitude,
        status: 'Aktif',
      );
      _activeParking = history;
      notifyListeners();
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

      // Update riwayat di Firestore
      await _db.collection('parking_history').doc(_activeParking!.id).update({
        'checkOutTime': Timestamp.fromDate(checkoutTime),
        'status': 'Selesai',
      });

      // Bebaskan slot di Firestore
      final matchedSlots = _slots.where(
        (s) =>
            s.kode == _activeParking!.slotCode &&
            _zones.any((z) => z.id == s.zoneId && z.nama == _activeParking!.zoneName),
      );
      if (matchedSlots.isNotEmpty) {
        await _db.collection('parking_slots').doc(matchedSlots.first.id).update({
          'isOccupied': false,
          'vehiclePlate': null,
        });
      }

      _activeParking = null;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Cari slot parkir terdekat
  Map<String, dynamic>? findNearestSlot() {
    if (_zones.isEmpty) return null;
    ParkingZone? nearestZone;
    double minDistance = double.infinity;
    for (var zone in _zones) {
      double dist = Geolocator.distanceBetween(
        _userLatitude, _userLongitude,
        zone.latitude, zone.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestZone = zone;
      }
    }
    return {'zone': nearestZone, 'distance': minDistance};
  }
}
