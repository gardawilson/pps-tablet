import 'package:intl/intl.dart';

class BongkarSusun {
  final String noBongkarSusun;
  final DateTime? tanggal;
  final int idUsername;
  final String? note;

  const BongkarSusun({
    required this.noBongkarSusun,
    required this.tanggal,
    required this.idUsername,
    this.note,
  });

  factory BongkarSusun.fromJson(Map<String, dynamic> j) {
    return BongkarSusun(
      noBongkarSusun: j['NoBongkarSusun'] ?? '',
      tanggal: j['Tanggal'] != null ? DateTime.tryParse(j['Tanggal']) : null,
      idUsername: j['IdUsername'] ?? 0,
      note: j['Note'],
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBongkarSusun': noBongkarSusun,
    'Tanggal': tanggal?.toUtc().toIso8601String(),
    'IdUsername': idUsername,
    'Note': note,
  };

  String get tanggalText {
    if (tanggal == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }
}
