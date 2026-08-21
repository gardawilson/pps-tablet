// lib/features/bahan_pendukung/penerimaan/repository/penerimaan_bahan_pendukung_repository.dart
//
// Endpoint backend (D:\backend\pps_backend\src\modules\production\
// penerimaan-bahan-pendukung), mounted di /api/penerimaan-bahan-pendukung:
//   GET    /api/penerimaan-bahan-pendukung/tim-status         — status tim
//   GET    /api/penerimaan-bahan-pendukung                     — riwayat (paginated)
//   GET    /api/penerimaan-bahan-pendukung/:noPenerimaan
//   POST   /api/penerimaan-bahan-pendukung                     — fase 1: create header
//   POST   /api/penerimaan-bahan-pendukung/:noPenerimaan/items — fase 2: add items
//   DELETE /api/penerimaan-bahan-pendukung/:noPenerimaan
//
// Alur create 2 fase, sama seperti Penerimaan Bahan Baku: dialog header
// (Tanggal/Shift/Jam/Regu/Operator) langsung hit createHeader() begitu
// SIMPAN ditekan → dapat NoPenerimaan → baru di screen input, addItems()
// dipanggil (bisa berkali-kali) untuk NoPenerimaan yang sama. Beda dengan
// bahan baku: item di sini sederhana (Nama Barang + Qty + Satuan), tanpa
// pallet/sak, dan tidak ada kategori.
import '../../../../core/network/api_client.dart';
import '../model/penerimaan_bahan_pendukung_model.dart';
import '../model/tim_penerimaan_model.dart';

/// Satu barang yang dikirim sebagai bagian dari payload addItems.
class PenerimaanBahanPendukungItemInput {
  final int idSupplier;
  final String namaBarang;
  final double qty;
  final String satuan;
  final String? keterangan;

  const PenerimaanBahanPendukungItemInput({
    required this.idSupplier,
    required this.namaBarang,
    required this.qty,
    this.satuan = 'PCS',
    this.keterangan,
  });

  Map<String, dynamic> toJson() => {
    'idSupplier': idSupplier,
    'namaBarang': namaBarang,
    'qty': qty,
    'satuan': satuan,
    if (keterangan != null && keterangan!.trim().isNotEmpty) 'keterangan': keterangan!.trim(),
  };
}

/// Header yang baru dibuat lewat
/// [PenerimaanBahanPendukungRepository.createHeader] — hasil fase 1 (POST
/// /api/penerimaan-bahan-pendukung), sebelum barang apapun ditambahkan.
class PenerimaanBahanPendukungHeaderResult {
  final String noPenerimaan;
  final DateTime tanggal;
  final int idTim;
  final int shift;
  final String hourStart;
  final String hourEnd;
  final List<int> idOperators;
  final String namaOperators;

  const PenerimaanBahanPendukungHeaderResult({
    required this.noPenerimaan,
    required this.tanggal,
    required this.idTim,
    required this.shift,
    required this.hourStart,
    required this.hourEnd,
    required this.idOperators,
    required this.namaOperators,
  });
}

class PenerimaanBahanPendukungRepository {
  final ApiClient api;

  PenerimaanBahanPendukungRepository({required this.api});

  // ==========================================
  //  STATUS TIM
  //  GET /api/penerimaan-bahan-pendukung/tim-status
  // ==========================================
  Future<List<TimPenerimaanInfo>> fetchTimStatus() async {
    final body = await api.getJson('/api/penerimaan-bahan-pendukung/tim-status');
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => TimPenerimaanInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  RIWAYAT (paginated)
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? filter,
  }) async {
    final body = await api.getJson(
      '/api/penerimaan-bahan-pendukung',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
    );

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => PenerimaanBahanPendukung.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] as int?) ?? 1;
    final total = (body['totalData'] ?? items.length) as int;

    return {
      'items': items,
      'page': currentPage,
      'totalPages': totalPages,
      'total': total,
    };
  }

  Future<PenerimaanBahanPendukungDetail> fetchDetail(String noPenerimaan) async {
    final body = await api.getJson('/api/penerimaan-bahan-pendukung/$noPenerimaan');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data penerimaan tidak ditemukan');
    return PenerimaanBahanPendukungDetail.fromJson(data);
  }

  // ==========================================
  //  FASE 1: CREATE HEADER
  //  POST /api/penerimaan-bahan-pendukung
  // ==========================================
  Future<PenerimaanBahanPendukungHeaderResult> createHeader({
    required DateTime tglPenerimaan,
    required int idTim,
    required int shift,
    required String hourStart,
    required String hourEnd,
    required List<int> idOperators,
    required String namaOperators,
  }) async {
    final body = await api.postJson(
      '/api/penerimaan-bahan-pendukung',
      body: {
        'tglPenerimaan': _dateOnly(tglPenerimaan),
        'idTim': idTim,
        'shift': shift,
        'hourStart': _normalizeTime(hourStart),
        'hourEnd': _normalizeTime(hourEnd),
        'idOperators': idOperators,
      },
    );

    final data = body['data'] as Map<String, dynamic>?;
    final noPenerimaan = data?['noPenerimaan']?.toString();
    if (noPenerimaan == null) {
      throw Exception('Response create header penerimaan tidak valid');
    }
    return PenerimaanBahanPendukungHeaderResult(
      noPenerimaan: noPenerimaan,
      tanggal: tglPenerimaan,
      idTim: idTim,
      shift: shift,
      hourStart: hourStart,
      hourEnd: hourEnd,
      idOperators: idOperators,
      namaOperators: namaOperators,
    );
  }

  // ==========================================
  //  FASE 2: ADD ITEMS ke header yang sudah ada
  //  POST /api/penerimaan-bahan-pendukung/:noPenerimaan/items
  //  Boleh dipanggil >1x per NoPenerimaan.
  // ==========================================
  Future<void> addItems({
    required String noPenerimaan,
    required List<PenerimaanBahanPendukungItemInput> items,
  }) async {
    await api.postJson(
      '/api/penerimaan-bahan-pendukung/$noPenerimaan/items',
      body: {'items': items.map((it) => it.toJson()).toList()},
    );
  }

  Future<void> delete(String noPenerimaan) async {
    await api.deleteJson('/api/penerimaan-bahan-pendukung/$noPenerimaan');
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _normalizeTime(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    return t.length == 5 ? '$t:00' : t;
  }
}
