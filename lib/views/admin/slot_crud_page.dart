import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parking_zone.dart';
import '../../models/parking_slot.dart';
import '../../providers/parking_provider.dart';

class SlotCrudPage extends StatefulWidget {
  const SlotCrudPage({super.key});

  @override
  State<SlotCrudPage> createState() => _SlotCrudPageState();
}

class _SlotCrudPageState extends State<SlotCrudPage> {
  ParkingZone? _selectedZone;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditSlotDialog([ParkingSlot? slot]) {
    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih zona terlebih dahulu!')),
      );
      return;
    }

    final isEdit = slot != null;
    final formKey = GlobalKey<FormState>();
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final idController = TextEditingController(text: slot?.id ?? '');
    final kodeController = TextEditingController(text: slot?.kode ?? '');
    final vehiclePlateController = TextEditingController(text: slot?.vehiclePlate ?? '');
    String selectedType = slot?.type ?? 'Mobil';
    bool isOccupiedVal = slot?.isOccupied ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Ubah Slot Parkir' : 'Tambah Slot Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEdit) ...[
                        TextFormField(
                          controller: idController,
                          decoration: const InputDecoration(labelText: 'ID Slot (misal: rektorat_slot_11)'),
                          validator: (val) => val == null || val.isEmpty ? 'ID wajib diisi' : null,
                        ),
                      ],
                      TextFormField(
                        controller: kodeController,
                        decoration: const InputDecoration(labelText: 'Kode Slot (misal: R11)'),
                        validator: (val) => val == null || val.isEmpty ? 'Kode wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipe Kendaraan'),
                        items: const [
                          DropdownMenuItem(value: 'Mobil', child: Text('Mobil')),
                          DropdownMenuItem(value: 'Motor', child: Text('Motor')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Status Terisi'),
                        value: isOccupiedVal,
                        activeColor: const Color(0xFF1976D2),
                        onChanged: (val) {
                          setDialogState(() {
                            isOccupiedVal = val;
                          });
                        },
                      ),
                      if (isOccupiedVal)
                        TextFormField(
                          controller: vehiclePlateController,
                          decoration: const InputDecoration(labelText: 'Nomor Plat Kendaraan (Opsional)'),
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

                    final newSlot = ParkingSlot(
                      id: isEdit ? slot.id : idController.text.trim().toLowerCase(),
                      zoneId: _selectedZone!.id,
                      kode: kodeController.text.trim(),
                      isOccupied: isOccupiedVal,
                      vehiclePlate: isOccupiedVal ? vehiclePlateController.text.trim() : null,
                      type: selectedType,
                    );

                    try {
                      if (isEdit) {
                        await parkingProvider.updateSlot(newSlot);
                      } else {
                        await parkingProvider.addSlot(newSlot);
                      }
                      if (context.mounted) Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Slot berhasil diubah!' : 'Slot berhasil ditambahkan!'),
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

  void _showDeleteWarning(ParkingSlot slot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Slot Parkir'),
          content: Text('Apakah Anda yakin ingin menghapus slot "${slot.kode}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
                  await parkingProvider.deleteSlot(slot.id);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Slot berhasil dihapus!'), backgroundColor: Colors.green),
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
    final isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: _selectedZone != null
          ? FloatingActionButton(
              heroTag: 'add_slot_fab',
              onPressed: () => _showAddEditSlotDialog(),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Tambah Slot',
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          children: [
            // Dropdown Zone Selector and Search bar
            StreamBuilder<List<ParkingZone>>(
              stream: parkingProvider.streamZones(),
              builder: (context, snapshot) {
                final zones = snapshot.data ?? [];

                // Sync selected zone references
                if (_selectedZone != null && !zones.any((z) => z.id == _selectedZone!.id)) {
                  _selectedZone = null;
                }

                final selectorWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ParkingZone>(
                      value: _selectedZone,
                      hint: const Text('Pilih Zona Parkir'),
                      isExpanded: true,
                      items: zones.map((zone) {
                        return DropdownMenuItem<ParkingZone>(
                          value: zone,
                          child: Text(zone.nama),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedZone = val;
                        });
                      },
                    ),
                  ),
                );

                final searchWidget = Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari Kode Slot...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toUpperCase();
                      });
                    },
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      selectorWidget,
                      const SizedBox(height: 12),
                      searchWidget,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: selectorWidget,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: searchWidget,
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Slot Table view
            Expanded(
              child: _selectedZone == null
                  ? const Center(
                      child: Text('Silakan pilih zona terlebih dahulu untuk mengelola slot.'),
                    )
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: StreamBuilder<List<ParkingSlot>>(
                        stream: parkingProvider.streamSlots(_selectedZone!.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final list = (snapshot.data ?? []).where((slot) {
                            return slot.kode.toUpperCase().contains(_searchQuery);
                          }).toList();

                          if (list.isEmpty) {
                            return const Center(
                              child: Text('Tidak ada slot parkir di zona ini.'),
                            );
                          }

                          // Sort slots by code
                          list.sort((a, b) => a.kode.compareTo(b.kode));

                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Kode Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Tipe Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status Terisi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Plat Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: list.map((slot) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(slot.kode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(slot.type)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: slot.isOccupied ? Colors.red[50] : Colors.green[50],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            slot.isOccupied ? 'Terisi' : 'Kosong',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: slot.isOccupied ? Colors.red[700] : Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(slot.vehiclePlate ?? '-')),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.green),
                                              onPressed: () => _showAddEditSlotDialog(slot),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _showDeleteWarning(slot),
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
