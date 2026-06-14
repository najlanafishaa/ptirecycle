import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_history.dart';
import '../../services/local_db_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final LocalDbService _localDb = LocalDbService.instance;
  List<ParkingHistory> _localHistory = [];
  bool _useLocal = false;

  @override
  void initState() {
    super.initState();
    _loadLocalHistory();
  }

  Future<void> _loadLocalHistory() async {
    final userDetails = Provider.of<AuthProvider>(context, listen: false).userDetails;
    final userId = userDetails?['uid'];
    if (userId != null) {
      final list = await _localDb.getHistoryList(userId);
      setState(() {
        _localHistory = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final userId = authProvider.userDetails?['uid'] ?? '';
    final primaryColor = const Color(0xFF1976D2);
    final darkColor = const Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Parkir', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_useLocal ? Icons.cloud_outlined : Icons.cloud_off, color: Colors.white),
            tooltip: _useLocal ? 'Beralih ke Online' : 'Beralih ke Offline (SQLite)',
            onPressed: () {
              setState(() {
                _useLocal = !_useLocal;
              });
              if (_useLocal) {
                _loadLocalHistory();
              }
            },
          )
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: _useLocal
            ? _buildLocalList(primaryColor, darkColor)
            : StreamBuilder<List<ParkingHistory>>(
                stream: parkingProvider.streamUserHistory(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  }

                  final histories = snapshot.data ?? [];
                  if (histories.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildHistoryList(histories, primaryColor, darkColor);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat Parkir',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat akan muncul setelah Anda parkir.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalList(Color primaryColor, Color darkColor) {
    if (_localHistory.isEmpty) {
      return _buildEmptyState();
    }
    return _buildHistoryList(_localHistory, primaryColor, darkColor);
  }

  Widget _buildHistoryList(List<ParkingHistory> histories, Color primaryColor, Color darkColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: histories.length,
      itemBuilder: (context, index) {
        final history = histories[index];
        final isCompleted = history.status == 'Selesai';
        final checkInStr = DateFormat('dd MMM yyyy, HH:mm').format(history.checkInTime);
        final checkOutStr = history.checkOutTime != null
            ? DateFormat('HH:mm').format(history.checkOutTime!)
            : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.grey[100] : Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.local_parking : Icons.play_arrow,
                            color: isCompleted ? Colors.grey[600] : Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Slot ${history.slotCode}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey[200] : Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        history.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey[700] : Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  history.zoneName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Masuk: $checkInStr',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (history.checkOutTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Keluar: ${DateFormat('dd MMM yyyy, ').format(history.checkOutTime!)}$checkOutStr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.pin_drop_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'GPS: ${history.latitude.toStringAsFixed(4)}, ${history.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Set GPS coordinate to park coordinate to show navigations
                      final provider = Provider.of<ParkingProvider>(context, listen: false);
                      
                      // Simulate navigation
                      provider.updateUserLocation(history.latitude - 0.003, history.longitude - 0.002);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menyetel GPS simulator ke arah slot ${history.slotCode}. Rute navigasi aktif!'),
                          backgroundColor: primaryColor,
                        ),
                      );
                    },
                    icon: Icon(Icons.navigation, size: 16, color: primaryColor),
                    label: const Text('Navigasi Ke Kendaraan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
