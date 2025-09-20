// lib/models/detail_item.dart

class DetailItem {
  final String noSak;
  final String berat;

  DetailItem({
    required this.noSak,
    required this.berat,
  });

  // Constructor untuk membuat instance dari Map (berguna untuk database/API)
  factory DetailItem.fromMap(Map<String, dynamic> map) {
    return DetailItem(
      noSak: map['noSak'] ?? '',
      berat: map['berat'] ?? '',
    );
  }

  // Method untuk mengkonversi ke Map (berguna untuk menyimpan ke database/API)
  Map<String, dynamic> toMap() {
    return {
      'noSak': noSak,
      'berat': berat,
    };
  }

  // Method untuk membuat salinan dengan nilai yang dimodifikasi
  DetailItem copyWith({
    String? noSak,
    String? berat,
  }) {
    return DetailItem(
      noSak: noSak ?? this.noSak,
      berat: berat ?? this.berat,
    );
  }

  // Override toString untuk debugging yang lebih mudah
  @override
  String toString() {
    return 'DetailItem(noSak: $noSak, berat: $berat)';
  }

  // Override equality operators untuk perbandingan objek
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetailItem &&
        other.noSak == noSak &&
        other.berat == berat;
  }

  @override
  int get hashCode => noSak.hashCode ^ berat.hashCode;

  // Getter untuk mendapatkan berat sebagai double
  double get beratAsDouble => double.tryParse(berat) ?? 0.0;
}