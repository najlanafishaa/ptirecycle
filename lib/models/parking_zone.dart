class ParkingZone {
  final String id;
  final String nama;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final int totalSlots;

  ParkingZone({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'totalSlots': totalSlots,
    };
  }

  factory ParkingZone.fromMap(Map<String, dynamic> map, String docId) {
    return ParkingZone(
      id: docId,
      nama: map['nama'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      totalSlots: map['totalSlots'] ?? 0,
    );
  }
}
