import 'trade_in_detail.dart';

/// Satu baris penerimaan trade-in pada list — field-field ini sudah
/// diformat oleh backend (Tanggal jadi "DD MMM YYYY" atau "-", field
/// nullable lain jadi ""). Setiap penerimaan cuma punya 1 reject terkait
/// (bisa null kalau belum ada label reject-nya).
class TradeInTransaction {
  final String noPenerimaan;
  final String tanggal;
  final String supplier;
  final String salesPersonCode;
  final String salesPersonName;
  final TradeInRejectDetail? reject;

  const TradeInTransaction({
    required this.noPenerimaan,
    required this.tanggal,
    required this.supplier,
    required this.salesPersonCode,
    required this.salesPersonName,
    this.reject,
  });

  factory TradeInTransaction.fromJson(Map<String, dynamic> json) {
    final rejectJson = json['reject'];
    return TradeInTransaction(
      noPenerimaan: (json['NoPenerimaan'] ?? '').toString(),
      tanggal: (json['Tanggal'] ?? '-').toString(),
      supplier: (json['Supplier'] ?? '').toString(),
      salesPersonCode: (json['SalesPersonCode'] ?? '').toString(),
      salesPersonName: (json['SalesPersonName'] ?? '').toString(),
      reject: rejectJson == null
          ? null
          : TradeInRejectDetail.fromJson(
              Map<String, dynamic>.from(rejectJson as Map),
            ),
    );
  }
}
