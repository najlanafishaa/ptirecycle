import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/parking_report.dart';
import '../../providers/parking_provider.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {

  void _updateStatus(String id, String currentStatus) {
    String nextStatus = 'Diproses';
    if (currentStatus == 'Diproses') {
      nextStatus = 'Selesai';
    } else if (currentStatus == 'Selesai') {
      nextStatus = 'Pending';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Perbarui Status Laporan'),
          content: Text('Ubah status laporan dari "$currentStatus" menjadi "$nextStatus"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
                  await parkingProvider.updateReportStatus(id, nextStatus);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status diperbarui menjadi $nextStatus!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
              child: const Text('Ya, Perbarui'),
            ),
          ],
        );
      },
    );
  }

  void _deleteReport(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Laporan'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan aduan ini dari database?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
                  await parkingProvider.deleteReport(id);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan berhasil dihapus!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          children: [
            // List view content
            Expanded(
              child: StreamBuilder<List<ParkingReport>>(
                stream: parkingProvider.streamReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data ?? [];

                  if (reports.isEmpty) {
                    return const Center(
                      child: Text('Belum ada laporan aduan dari pengguna.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt);

                      Color statusColor;
                      switch (report.status) {
                        case 'Diproses':
                          statusColor = Colors.orange[700]!;
                          break;
                        case 'Selesai':
                          statusColor = Colors.green[700]!;
                          break;
                        default:
                          statusColor = Colors.blue[700]!;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.userEmail,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Waktu Laporan: $dateStr',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      report.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const Text(
                                'DESKRIPSI ADUAN:',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.deskripsi,
                                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                              ),
                              if (report.fotoUrl != null) ...[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    report.fotoUrl!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _updateStatus(report.id, report.status),
                                    icon: const Icon(Icons.change_circle_outlined, size: 18),
                                    label: const Text('UBAH STATUS'),
                                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: () => _deleteReport(report.id),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('HAPUS'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
