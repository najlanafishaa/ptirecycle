import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_zone.dart';
import '../../models/parking_slot.dart';
import '../widgets/custom_map_widget.dart';
import './history_page.dart';
import './report_page.dart';
import './profile_page.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  bool _isNavigating = false;
  Timer? _parkingTimer;
  String _parkingDurationStr = '00:00:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userDetails != null) {
        final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
        parkingProvider.loadActiveParking(authProvider.userDetails!['uid']).then((_) {
          _startTimerIfParked();
        });
      }
    });
  }

  @override
  void dispose() {
    _parkingTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfParked() {
    _parkingTimer?.cancel();
    final active = Provider.of<ParkingProvider>(context, listen: false).activeParking;
    if (active != null) {
      _parkingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final diff = DateTime.now().difference(active.checkInTime);
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) {
          setState(() {
            _parkingDurationStr = '$hours:$minutes:$seconds';
          });
        }
      });
    }
  }

  void _stopTimer() {
    _parkingTimer?.cancel();
    setState(() {
      _parkingDurationStr = '00:00:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userDetails = authProvider.userDetails ?? {};
    final userName = userDetails['nama'] ?? 'Pengguna';

    // Sub-pages list
    final List<Widget> pages = [
      _buildHomeScreen(userName, authProvider.userDetails?['uid'] ?? ''),
      const HistoryPage(),
      const ReportPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Lapor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen(String userName, String userId) {
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final active = parkingProvider.activeParking;
    final primaryColor = const Color(0xFF1976D2);
    final darkColor = const Color(0xFF0D47A1);

    if (active != null && _parkingTimer == null) {
      _startTimerIfParked();
    }

    return SafeArea(
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Circular profile mock
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: darkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Area taking remaining space (except bottom card)
          Expanded(
            child: Stack(
              children: [
                CustomMapWidget(
                  showNavigationRoute: _isNavigating || active != null,
                  onSlotSelected: (zone, slot) {
                    _showParkConfirmationDialog(zone, slot, userId);
                  },
                ),

                // Floating "Cari Parkir Terdekat" FAB
                if (active == null)
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: FloatingActionButton.extended(
                      heroTag: 'nearest_spot',
                      onPressed: () {
                        final nearest = parkingProvider.findNearestSlot();
                        if (nearest != null) {
                          final zone = nearest['zone'] as ParkingZone;
                          final distance = nearest['distance'] as double;
                          _showNearestSpotSheet(zone, distance);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tidak ada zona parkir tersedia')),
                          );
                        }
                      },
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.near_me),
                      label: const Text('Cari Parkir Terdekat'),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Active Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active == null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline, color: primaryColor),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Parkir: Belum Aktif',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih marker parkir di peta untuk menyimpan lokasi Anda',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_parking, color: Colors.green),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parkir Aktif: ${active.slotCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              active.zoneName,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Durasi',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            _parkingDurationStr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Toggle Navigation Mode
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isNavigating = !_isNavigating;
                            });
                          },
                          icon: Icon(_isNavigating ? Icons.navigation : Icons.explore_outlined),
                          label: Text(_isNavigating ? 'Navigasi Aktif' : 'Panduan Rute'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Finish Parking button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final error = await parkingProvider.checkoutVehicle(userId);
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            } else {
                              _stopTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Parkir selesai! Riwayat disimpan.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Selesai Parkir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Suggesting nearest spot BottomSheet
  void _showNearestSpotSheet(ParkingZone zone, double distance) {
    final primaryColor = const Color(0xFF1976D2);
    final darkColor = const Color(0xFF0D47A1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_run, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Zona Terdekat Ditemukan!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                zone.nama,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                zone.deskripsi,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'Jarak: sekitar ${distance.toStringAsFixed(0)} meter dari posisi Anda.',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Trigger GPS route navigation
                        setState(() {
                          _isNavigating = true;
                        });
                        // Automatically subscribe to slots for map selection
                        Provider.of<ParkingProvider>(context, listen: false).subscribeToSlots(zone.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menampilkan rute ke ${zone.nama}. Klik marker untuk parkir.'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pandu Rute'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Parking Confirmation Dialog
  void _showParkConfirmationDialog(ParkingZone zone, ParkingSlot slot, String userId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.local_parking, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text('Konfirmasi Parkir (${slot.kode})'),
            ],
          ),
          content: Text(
            'Apakah Anda ingin parkir kendaraan ${slot.type} Anda di ${zone.nama}, Slot ${slot.kode}?\n\nLokasi koordinat ini akan disimpan di sistem untuk riwayat dan penunjuk arah kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = Provider.of<ParkingProvider>(context, listen: false);
                final error = await provider.parkVehicle(
                  userId: userId,
                  userEmail: authProvider.userDetails?['email'] ?? '',
                  zone: zone,
                  slot: slot,
                );

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  _startTimerIfParked();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil memarkirkan kendaraan di Slot ${slot.kode}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
              child: const Text('Ya, Simpan Lokasi'),
            ),
          ],
        );
      },
    );
  }
}
