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
