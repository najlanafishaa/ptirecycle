import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parking_zone.dart';
import '../../providers/parking_provider.dart';

class ZoneCrudPage extends StatefulWidget {
  const ZoneCrudPage({super.key});

  @override
  State<ZoneCrudPage> createState() => _ZoneCrudPageState();
}

class _ZoneCrudPageState extends State<ZoneCrudPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditZoneDialog([ParkingZone? zone]) {
    final isEdit = zone != null;
    final formKey = GlobalKey<FormState>();
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final idController = TextEditingController(text: zone?.id ?? '');
    final namaController = TextEditingController(text: zone?.nama ?? '');
    final deskripsiController = TextEditingController(text: zone?.deskripsi ?? '');
    final latController = TextEditingController(text: zone?.latitude.toString() ?? '-5.3580');
    final lngController = TextEditingController(text: zone?.longitude.toString() ?? '105.2440');
    final slotsController = TextEditingController(text: zone?.totalSlots.toString() ?? '10');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Ubah Data Zona' : 'Tambah Zona Parkir Baru'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit)
                    TextFormField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'ID Zona (Kecil, misal: rektorat)'),
                      validator: (val) => val == null || val.isEmpty ? 'ID wajib diisi' : null,
                    ),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama Zona (misal: Zona Rektorat)'),
                    validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: deskripsiController,
                    decoration: const InputDecoration(labelText: 'Deskripsi Lokasi'),
                    validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Latitude GPS'),
                          validator: (val) => double.tryParse(val ?? '') == null ? 'Nilai tidak valid' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Longitude GPS'),
                          validator: (val) => double.tryParse(val ?? '') == null ? 'Nilai tidak valid' : null,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: slotsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Slot Parkir'),
                    validator: (val) => int.tryParse(val ?? '') == null ? 'Nilai tidak valid' : null,
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
                
                final double lat = double.parse(latController.text);
                final double lng = double.parse(lngController.text);
                final int slotsCount = int.parse(slotsController.text);

                final newZone = ParkingZone(
                  id: isEdit ? zone.id : idController.text.trim().toLowerCase(),
                  nama: namaController.text.trim(),
                  deskripsi: deskripsiController.text.trim(),
                  latitude: lat,
                  longitude: lng,
                  totalSlots: slotsCount,
                );

                try {
                  if (isEdit) {
                    await parkingProvider.updateZone(newZone);
                  } else {
                    await parkingProvider.addZone(newZone);
                  }
                  if (context.mounted) Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Zona berhasil diubah!' : 'Zona berhasil ditambahkan!'),
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
  }

  void _showDeleteWarning(ParkingZone zone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Zona Parkir'),
          content: Text('Apakah Anda yakin ingin menghapus "${zone.nama}"?\nSemua slot parkir di dalamnya juga akan dihapus secara otomatis.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
                  await parkingProvider.deleteZone(zone.id);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zona berhasil dihapus!'), backgroundColor: Colors.green),
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
    final primaryColor = const Color(0xFF1976D2);
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_zone_fab',
        onPressed: () => _showAddEditZoneDialog(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Zona',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          children: [
            // Search & Filter Header
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
                        hintText: 'Cari Zona Parkir...',
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

            // Data Table Content
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: StreamBuilder<List<ParkingZone>>(
                  stream: parkingProvider.streamZones(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final list = (snapshot.data ?? []).where((zone) {
                      return zone.nama.toLowerCase().contains(_searchQuery) ||
                          zone.deskripsi.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (list.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada zona parkir yang cocok.'),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 28,
                          columns: const [
                            DataColumn(label: Text('Nama Zona', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('GPS Latitude', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('GPS Longitude', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: list.map((zone) {
                            return DataRow(
                              cells: [
                                DataCell(Text(zone.nama, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(SizedBox(width: 200, child: Text(zone.deskripsi, maxLines: 1, overflow: TextOverflow.ellipsis))),
                                DataCell(Text('${zone.totalSlots}')),
                                DataCell(Text(zone.latitude.toStringAsFixed(4))),
                                DataCell(Text(zone.longitude.toStringAsFixed(4))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.green),
                                        onPressed: () => _showAddEditZoneDialog(zone),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteWarning(zone),
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
