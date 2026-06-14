import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_report.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isUploading = false;
  String? _simulatedPhotoUrl;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport(String userId, String userEmail) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      final String reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';
      final report = ParkingReport(
        id: reportId,
        userId: userId,
        userEmail: userEmail,
        deskripsi: _descriptionController.text.trim(),
        fotoUrl: _simulatedPhotoUrl,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await parkingProvider.addReport(report);
      
      _descriptionController.clear();
      setState(() {
        _simulatedPhotoUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim! Petugas akan segera memeriksa.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parkingProvider = Provider.of<ParkingProvider>(context);
    
    final userId = authProvider.userDetails?['uid'] ?? '';
    final userEmail = authProvider.userDetails?['email'] ?? '';
    final primaryColor = const Color(0xFF1976D2);
    final darkColor = const Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporkan Kendala', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: darkColor,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Report Form Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Laporkan Kendaraan Bermasalah',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ada mobil menghalangi slot Anda? Atau ada motor parkir tidak rapi? Laporkan ke admin/petugas.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Tuliskan deskripsi masalah, nomor plat kendaraan, dan lokasi zona detail...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Deskripsi laporan wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),

                        // Simulated Photo Uploader
                        InkWell(
                          onTap: () {
                            setState(() {
                              _simulatedPhotoUrl = 'https://picsum.photos/400/300';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Foto bukti kendaraan ditambahkan (Simulated)')),
                            );
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _simulatedPhotoUrl != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(
                                          _simulatedPhotoUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 14,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _simulatedPhotoUrl = null;
                                              });
                                            },
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 36, color: primaryColor),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tambahkan Foto Bukti',
                                        style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isUploading ? null : () => _submitReport(userId, userEmail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('KIRIM LAPORAN', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Riwayat Laporan Anda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor),
              ),
              const SizedBox(height: 12),

              // Fetch only user reports
              StreamBuilder<List<ParkingReport>>(
                stream: parkingProvider.streamReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = (snapshot.data ?? []).where((r) => r.userId == userId).toList();

                  if (reports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Belum ada laporan yang Anda kirim.',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      report.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.deskripsi,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              if (report.fotoUrl != null) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    report.fotoUrl!,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
