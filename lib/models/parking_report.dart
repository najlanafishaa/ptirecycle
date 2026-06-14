class ParkingReport {
  final String id;
  final String userId;
  final String userEmail;
  final String deskripsi;
  final String? fotoUrl;
  final String status; // 'Pending' | 'Diproses' | 'Selesai'
  final DateTime createdAt;

  ParkingReport({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.deskripsi,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'deskripsi': deskripsi,
      'fotoUrl': fotoUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ParkingReport.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.parse(map['createdAt']);
    } else {
      parsedDate = DateTime.now();
    }

    return ParkingReport(
      id: docId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      fotoUrl: map['fotoUrl'],
      status: map['status'] ?? 'Pending',
      createdAt: parsedDate,
    );
  }
}
