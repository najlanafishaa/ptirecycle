import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  Uint8List? _pickedImageBytes;
  String? _pickedFileName;
  String? _uploadedPhotoUrl;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedFileName = file.name;
          _uploadedPhotoUrl = null; // reset URL lama
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadToStorage(String userId) async {
    if (_pickedImageBytes == null) return null;
    try {
      final fileName = 'reports/$userId/${DateTime.now().millisecondsSinceEpoch}_${_pickedFileName ?? "bukti.jpg"}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(
        _pickedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Gagal upload foto: $e');
      return null;
    }
  }

  void _submitReport(String userId, String userEmail) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // Upload foto jika ada
      String? photoUrl;
      if (_pickedImageBytes != null) {
        photoUrl = await _uploadToStorage(userId);
      }

      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      final String reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';
      final report = ParkingReport(
        id: reportId,
        userId: userId,
        userEmail: userEmail,
        deskripsi: _descriptionController.text.trim(),
        fotoUrl: photoUrl,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await parkingProvider.addReport(report);

      _descriptionController.clear();
      setState(() {
        _pickedImageBytes = null;
        _pickedFileName = null;
        _uploadedPhotoUrl = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim! Petugas akan segera memeriksa.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

                        // Real Photo Picker
                        GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _pickedImageBytes != null ? primaryColor : Colors.grey[300]!,
                                width: _pickedImageBytes != null ? 2 : 1,
                              ),
                            ),
                            child: _pickedImageBytes != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.memory(
                                          _pickedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _pickedImageBytes = null;
                                            _pickedFileName = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.photo, size: 12, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                _pickedFileName ?? 'bukti.jpg',
                                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 40, color: primaryColor),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Tambahkan Foto Bukti',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Klik untuk pilih dari Galeri atau Kamera',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
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
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Mengirim laporan...'),
                                  ],
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
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 120,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    },
                                    errorBuilder: (ctx, err, _) => const SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: Text('Gagal memuat foto', style: TextStyle(color: Colors.grey)),
                                      ),
                                    ),
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
