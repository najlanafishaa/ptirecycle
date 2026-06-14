import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parking_officer.dart';
import '../../models/parking_zone.dart';
import '../../providers/parking_provider.dart';

class OfficerCrudPage extends StatefulWidget {
  const OfficerCrudPage({super.key});

  @override
  State<OfficerCrudPage> createState() => _OfficerCrudPageState();
}

class _OfficerCrudPageState extends State<OfficerCrudPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<ParkingZone> _zones = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      setState(() {
        _zones = parkingProvider.zones;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditOfficerDialog([ParkingOfficer? officer]) {
    final isEdit = officer != null;
    final formKey = GlobalKey<FormState>();
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final idController = TextEditingController(text: officer?.id ?? '');
    final namaController = TextEditingController(text: officer?.nama ?? '');
    final emailController = TextEditingController(text: officer?.email ?? '');
    final phoneController = TextEditingController(text: officer?.telepon ?? '');
    String selectedZoneId = officer?.zoneId ?? (_zones.isNotEmpty ? _zones.first.id : '');
    String selectedStatus = officer?.status ?? 'Aktif';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Ubah Data Petugas' : 'Tambah Petugas Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEdit)
                        TextFormField(
                          controller: idController,
                          decoration: const InputDecoration(labelText: 'ID Petugas (misal: officer_4)'),
                          validator: (val) => val == null || val.isEmpty ? 'ID wajib diisi' : null,
                        ),
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                        validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email UNILA'),
                        validator: (val) => val == null || !val.contains('@') ? 'Email tidak valid' : null,
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                        validator: (val) => val == null || val.isEmpty ? 'Telepon wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_zones.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedZoneId.isNotEmpty ? selectedZoneId : _zones.first.id,
                          decoration: const InputDecoration(labelText: 'Penugasan Zona'),
                          items: _zones.map((zone) {
                            return DropdownMenuItem(value: zone.id, child: Text(zone.nama));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedZoneId = val;
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status Keaktifan'),
                        items: const [
                          DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                          DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedStatus = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final newOfficer = ParkingOfficer(
                      id: isEdit ? officer.id : idController.text.trim().toLowerCase(),
                      nama: namaController.text.trim(),
                      email: emailController.text.trim(),
                      telepon: phoneController.text.trim(),
                      zoneId: selectedZoneId,
                      status: selectedStatus,
                    );

                    try {
                      if (isEdit) {
                        await parkingProvider.updateOfficer(newOfficer);
                      } else {
                        await parkingProvider.addOfficer(newOfficer);
                      }
                      if (context.mounted) Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Petugas berhasil diubah!' : 'Petugas berhasil ditambahkan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteWarning(ParkingOfficer officer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Petugas Parkir'),
          content: Text('Apakah Anda yakin ingin menghapus petugas "${officer.nama}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
                  await parkingProvider.deleteOfficer(officer.id);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Petugas berhasil dihapus!'), backgroundColor: Colors.green),
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

  String _getZoneName(String zoneId) {
    final zone = _zones.firstWhere((z) => z.id == zoneId, orElse: () => ParkingZone(id: '', nama: 'Tidak Ditugaskan', deskripsi: '', latitude: 0, longitude: 0, totalSlots: 0));
    return zone.nama;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1976D2);
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_officer_fab',
        onPressed: () => _showAddEditOfficerDialog(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Petugas',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          children: [
            // Search Input
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari Petugas...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table Grid content
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: StreamBuilder<List<ParkingOfficer>>(
                  stream: parkingProvider.streamOfficers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final list = (snapshot.data ?? []).where((officer) {
                      return officer.nama.toLowerCase().contains(_searchQuery) ||
                          officer.email.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (list.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada petugas parkir.'),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tugas Zona', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: list.map((officer) {
                            return DataRow(
                              cells: [
                                DataCell(Text(officer.nama, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(officer.email)),
                                DataCell(Text(officer.telepon)),
                                DataCell(Text(_getZoneName(officer.zoneId))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: officer.status == 'Aktif' ? Colors.green[50] : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      officer.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: officer.status == 'Aktif' ? Colors.green[700] : Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.green),
                                        onPressed: () => _showAddEditOfficerDialog(officer),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteWarning(officer),
                                        tooltip: 'Hapus',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
