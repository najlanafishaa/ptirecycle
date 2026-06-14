class ParkingHistory {
  final String id;
  final String userId;
  final String zoneName;
  final String slotCode;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double latitude;
  final double longitude;
  final String status; // 'Aktif' | 'Selesai'

  ParkingHistory({
    required this.id,
    required this.userId,
    required this.zoneName,
    required this.slotCode,
    required this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'zoneName': zoneName,
      'slotCode': slotCode,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory ParkingHistory.fromMap(Map<String, dynamic> map) {
    return ParkingHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      slotCode: map['slotCode'] ?? '',
      checkInTime: DateTime.parse(map['checkInTime']),
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime']) : null,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Selesai',
    );
  }
}
