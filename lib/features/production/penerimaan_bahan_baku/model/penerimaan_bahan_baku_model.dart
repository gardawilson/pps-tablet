// lib/features/production/penerimaan_bahan_baku/model/penerimaan_bahan_baku_model.dart
//
// Mirror response dari backend `src/modules/production/penerimaan-bahan-baku/*`
// (GET/POST/DELETE /api/penerimaan-bahan-baku). Satu baris riwayat = satu
// transaksi penerimaan (NoPenerimaan) — sekarang membawa Shift/HourStart/
// HourEnd, format yang sama dengan produksi (mis. WashingProduction) — yang
// menghasilkan satu NoBahanBaku (label bahan baku) dengan satu atau lebih
// pallet.
import 'package:intl/intl.dart';

class PenerimaanBahanBaku {
  final String noPenerimaan;
  final DateTime? tglPenerimaan;
  final int idTim;
  final String namaTim;
  final int idSupplier;
  final String namaSupplier;
  final String? noPlat;
  final int shift;
  final String? hourStart; // "HH:mm"
  final String? hourEnd; // "HH:mm"
  final String? createBy;
  final DateTime? dateTimeCreate;

  final String? noBahanBaku;
  final int jumlahPallet;
  final double totalBerat;

  const PenerimaanBahanBaku({
    required this.noPenerimaan,
    required this.tglPenerimaan,
    required this.idTim,
    required this.namaTim,
    required this.idSupplier,
    required this.namaSupplier,
    this.noPlat,
    required this.shift,
    this.hourStart,
    this.hourEnd,
    this.createBy,
    this.dateTimeCreate,
    this.noBahanBaku,
    this.jumlahPallet = 0,
    this.totalBerat = 0,
  });

  static String _asString(dynamic v) => v?.toString() ?? '';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String? _asTimeHHmm(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
    if (m != null) return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)!}';
    return null;
  }

  factory PenerimaanBahanBaku.fromJson(Map<String, dynamic> j) {
    return PenerimaanBahanBaku(
      noPenerimaan: _asString(j['NoPenerimaan']),
      tglPenerimaan: _asDateTime(j['TglPenerimaan']),
      idTim: _asInt(j['IdTim']),
      namaTim: _asString(j['NamaTim']),
      idSupplier: _asInt(j['IdSupplier']),
      namaSupplier: _asString(j['NamaSupplier']),
      noPlat: j['NoPlat']?.toString(),
      shift: _asInt(j['Shift']),
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),
      createBy: j['CreateBy']?.toString(),
      dateTimeCreate: _asDateTime(j['DateTimeCreate']),
      noBahanBaku: j['NoBahanBaku']?.toString(),
      jumlahPallet: _asInt(j['JumlahPallet']),
      totalBerat: _asDouble(j['TotalBerat']),
    );
  }

  String get tglPenerimaanTextShort {
    if (tglPenerimaan == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglPenerimaan!.toLocal());
  }

  String get hourRangeText {
    if ((hourStart == null || hourStart!.isEmpty) && (hourEnd == null || hourEnd!.isEmpty)) {
      return '';
    }
    return '${hourStart ?? '--:--'} - ${hourEnd ?? '--:--'}';
  }
}

/// Satu baris output (label) dari sebuah transaksi penerimaan — hasil join
/// `PenerimaanBahanBakuOutput` + `BahanBakuPallet_h` + `BahanBaku_d`.
class PenerimaanBahanBakuOutput {
  final String noBahanBaku;
  final int noPallet;
  final int noSak;
  final int? idJenisPlastik;
  final double berat;

  const PenerimaanBahanBakuOutput({
    required this.noBahanBaku,
    required this.noPallet,
    required this.noSak,
    this.idJenisPlastik,
    required this.berat,
  });

  factory PenerimaanBahanBakuOutput.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PenerimaanBahanBakuOutput(
      noBahanBaku: j['NoBahanBaku']?.toString() ?? '',
      noPallet: toInt(j['NoPallet']),
      noSak: toInt(j['NoSak']),
      idJenisPlastik: j['IdJenisPlastik'] != null ? toInt(j['IdJenisPlastik']) : null,
      berat: toDouble(j['Berat']),
    );
  }
}

/// Detail lengkap satu transaksi penerimaan (GET /:noPenerimaan) — header +
/// seluruh output (pallet/sak) yang dihasilkan.
class PenerimaanBahanBakuDetail {
  final PenerimaanBahanBaku header;
  final List<PenerimaanBahanBakuOutput> outputs;

  const PenerimaanBahanBakuDetail({required this.header, required this.outputs});

  factory PenerimaanBahanBakuDetail.fromJson(Map<String, dynamic> j) {
    final outputsRaw = (j['outputs'] as List?) ?? [];
    return PenerimaanBahanBakuDetail(
      header: PenerimaanBahanBaku.fromJson(j),
      outputs: outputsRaw
          .map((e) => PenerimaanBahanBakuOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Group outputs by NoPallet untuk ditampilkan per pallet.
  Map<int, List<PenerimaanBahanBakuOutput>> get outputsByPallet {
    final map = <int, List<PenerimaanBahanBakuOutput>>{};
    for (final o in outputs) {
      map.putIfAbsent(o.noPallet, () => []).add(o);
    }
    return map;
  }
}
