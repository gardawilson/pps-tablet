// lib/features/bahan_pendukung/penerimaan/model/penerimaan_bahan_pendukung_model.dart
//
// Mirror response dari backend
// `src/modules/production/penerimaan-bahan-pendukung/*`
// (GET/POST/DELETE /api/penerimaan-bahan-pendukung). Satu baris riwayat =
// satu transaksi penerimaan (NoPenerimaan). Beda dengan Penerimaan Bahan
// Baku: TIDAK ada struktur pallet/sak — tiap barang (item) LANGSUNG jadi
// satu "label" (NamaBarang + Qty + Satuan), dan tidak ada split kategori
// (Pakai/Proses) — satu kategori saja.
import 'dart:convert';

import 'package:intl/intl.dart';

class PenerimaanBahanPendukung {
  final String noPenerimaan;
  final DateTime? tglPenerimaan;
  final int idTim;
  final String namaTim;
  final List<int> idOperators;
  final String? namaOperators;
  final int shift;
  final String? hourStart; // "HH:mm"
  final String? hourEnd; // "HH:mm"
  final String? createBy;
  final DateTime? dateTimeCreate;

  final int jumlahItem;
  final double totalQty;

  const PenerimaanBahanPendukung({
    required this.noPenerimaan,
    required this.tglPenerimaan,
    required this.idTim,
    required this.namaTim,
    this.idOperators = const [],
    this.namaOperators,
    required this.shift,
    this.hourStart,
    this.hourEnd,
    this.createBy,
    this.dateTimeCreate,
    this.jumlahItem = 0,
    this.totalQty = 0,
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

  static List<int> _asIntList(dynamic v) {
    if (v == null) return const [];
    final raw = v is String ? v : v.toString();
    if (raw.trim().isEmpty || raw.trim() == '[]') return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => _asInt(e)).toList();
      }
    } catch (_) {}
    return const [];
  }

  factory PenerimaanBahanPendukung.fromJson(Map<String, dynamic> j) {
    return PenerimaanBahanPendukung(
      noPenerimaan: _asString(j['NoPenerimaan']),
      tglPenerimaan: _asDateTime(j['TglPenerimaan']),
      idTim: _asInt(j['IdTim']),
      namaTim: _asString(j['NamaTim']),
      idOperators: _asIntList(j['IdOperators']),
      namaOperators: j['NamaOperators']?.toString(),
      shift: _asInt(j['Shift']),
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),
      createBy: j['CreateBy']?.toString(),
      dateTimeCreate: _asDateTime(j['DateTimeCreate']),
      jumlahItem: _asInt(j['JumlahItem']),
      totalQty: _asDouble(j['TotalQty']),
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

/// Satu baris barang ("label") dari sebuah transaksi penerimaan bahan
/// pendukung — hasil join `PenerimaanBahanPendukung_d` + `MstSupplier`.
class PenerimaanBahanPendukungItem {
  final String noPenerimaan;
  final int noUrut;
  final int idSupplier;
  final String namaSupplier;
  final String namaBarang;
  final double qty;
  final String satuan;
  final String? keterangan;

  const PenerimaanBahanPendukungItem({
    required this.noPenerimaan,
    required this.noUrut,
    required this.idSupplier,
    required this.namaSupplier,
    required this.namaBarang,
    required this.qty,
    required this.satuan,
    this.keterangan,
  });

  factory PenerimaanBahanPendukungItem.fromJson(Map<String, dynamic> j) {
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

    return PenerimaanBahanPendukungItem(
      noPenerimaan: j['NoPenerimaan']?.toString() ?? '',
      noUrut: toInt(j['NoUrut']),
      idSupplier: toInt(j['IdSupplier']),
      namaSupplier: j['NamaSupplier']?.toString() ?? '',
      namaBarang: j['NamaBarang']?.toString() ?? '',
      qty: toDouble(j['Qty']),
      satuan: j['Satuan']?.toString() ?? 'PCS',
      keterangan: j['Keterangan']?.toString(),
    );
  }
}

/// Detail lengkap satu transaksi penerimaan bahan pendukung (GET
/// /:noPenerimaan) — header + seluruh item (barang/label) di dalamnya.
class PenerimaanBahanPendukungDetail {
  final PenerimaanBahanPendukung header;
  final List<PenerimaanBahanPendukungItem> items;

  const PenerimaanBahanPendukungDetail({required this.header, required this.items});

  factory PenerimaanBahanPendukungDetail.fromJson(Map<String, dynamic> j) {
    final itemsRaw = (j['items'] as List?) ?? [];
    return PenerimaanBahanPendukungDetail(
      header: PenerimaanBahanPendukung.fromJson(j),
      items: itemsRaw
          .map((e) => PenerimaanBahanPendukungItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
