class ParkingSlot {
  final String id;
  final String zoneId;
  final String kode;
  final bool isOccupied;
  final String? vehiclePlate;
  final String type; // 'Mobil' | 'Motor'

  ParkingSlot({
    required this.id,
    required this.zoneId,
    required this.kode,
    required this.isOccupied,
    this.vehiclePlate,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'kode': kode,
      'isOccupied': isOccupied,
      'vehiclePlate': vehiclePlate,
      'type': type,
    };
  }

  factory ParkingSlot.fromMap(Map<String, dynamic> map, String docId) {
    return ParkingSlot(
      id: docId,
      zoneId: map['zoneId'] ?? '',
      kode: map['kode'] ?? '',
      isOccupied: map['isOccupied'] ?? false,
      vehiclePlate: map['vehiclePlate'],
      type: map['type'] ?? 'Mobil',
    );
  }
}
