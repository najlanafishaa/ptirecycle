class ParkingOfficer {
  final String id;
  final String nama;
  final String email;
  final String telepon;
  final String zoneId; // ID Zona tempat berjaga
  final String status; // 'Aktif' | 'Tidak Aktif'

  ParkingOfficer({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    required this.zoneId,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'zoneId': zoneId,
      'status': status,
    };
  }

  factory ParkingOfficer.fromMap(Map<String, dynamic> map, String docId) {
    return ParkingOfficer(
      id: docId,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      telepon: map['telepon'] ?? '',
      zoneId: map['zoneId'] ?? '',
      status: map['status'] ?? 'Aktif',
    );
  }
}
