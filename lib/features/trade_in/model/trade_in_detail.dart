/// Label reject yang terhubung ke satu penerimaan trade-in — null kalau
/// belum ada label reject terkait.
class TradeInRejectDetail {
  final String noReject;
  final int idReject;
  final String namaReject;
  final double berat;

  const TradeInRejectDetail({
    required this.noReject,
    required this.idReject,
    required this.namaReject,
    required this.berat,
  });

  factory TradeInRejectDetail.fromJson(Map<String, dynamic> json) {
    return TradeInRejectDetail(
      noReject: (json['NoReject'] ?? '').toString(),
      idReject: (json['IdReject'] as num?)?.toInt() ?? 0,
      namaReject: (json['NamaReject'] ?? '').toString(),
      berat: (json['Berat'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Detail satu penerimaan trade-in (header + jenis + reject terkait).
/// Beda dari [TradeInTransaction] (list) — field di sini masih raw
/// (tanggal format YYYY-MM-DD), dipakai buat prefill form edit.
class TradeInDetail {
  final String noPenerimaan;
  final DateTime? tanggal;
  final String supplier;
  final String salesPersonCode;
  final String jenis;
  final TradeInRejectDetail? reject;

  const TradeInDetail({
    required this.noPenerimaan,
    this.tanggal,
    required this.supplier,
    required this.salesPersonCode,
    required this.jenis,
    this.reject,
  });

  factory TradeInDetail.fromJson(Map<String, dynamic> json) {
    final rejectJson = json['reject'];
    return TradeInDetail(
      noPenerimaan: (json['noPenerimaan'] ?? '').toString(),
      tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      supplier: (json['supplier'] ?? '').toString(),
      salesPersonCode: (json['salesPersonCode'] ?? '').toString(),
      jenis: (json['jenis'] ?? '').toString(),
      reject: rejectJson == null
          ? null
          : TradeInRejectDetail.fromJson(
              Map<String, dynamic>.from(rejectJson as Map),
            ),
    );
  }
}
