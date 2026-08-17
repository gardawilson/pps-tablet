// lib/features/production/penerimaan_bahan_baku/repository/penerimaan_bahan_baku_repository.dart
//
// Endpoint backend (D:\backend\pps_backend\src\modules\production\
// penerimaan-bahan-baku), mounted di /api/penerimaan-bahan-baku:
//   GET    /api/penerimaan-bahan-baku/tim-status   — status tim (analog
//                                                     GET /api/mst-mesin/washing)
//   GET    /api/penerimaan-bahan-baku              — riwayat (paginated)
//   GET    /api/penerimaan-bahan-baku/:noPenerimaan
//   POST   /api/penerimaan-bahan-baku               — create atomic
//   DELETE /api/penerimaan-bahan-baku/:noPenerimaan
import '../../../../core/network/api_client.dart';
import '../model/penerimaan_bahan_baku_model.dart';
import '../model/tim_penerimaan_bahan_baku_model.dart';

/// Satu pallet + sak-sak-nya, dikirim sebagai bagian dari payload create.
class PenerimaanPalletInput {
  final int idJenisPlastik;
  final int? idWarehouse;
  final String? keterangan;
  final List<PenerimaanSakInput> saks;

  const PenerimaanPalletInput({
    required this.idJenisPlastik,
    this.idWarehouse,
    this.keterangan,
    required this.saks,
  });

  Map<String, dynamic> toJson() => {
    'idJenisPlastik': idJenisPlastik,
    if (idWarehouse != null) 'idWarehouse': idWarehouse,
    if (keterangan != null && keterangan!.trim().isNotEmpty)
      'keterangan': keterangan!.trim(),
    'saks': saks.map((s) => s.toJson()).toList(),
  };
}

class PenerimaanSakInput {
  final int noSak;
  final double berat;

  const PenerimaanSakInput({required this.noSak, required this.berat});

  Map<String, dynamic> toJson() => {'noSak': noSak, 'berat': berat};
}

class PenerimaanBahanBakuRepository {
  final ApiClient api;

  PenerimaanBahanBakuRepository({required this.api});

  // ==========================================
  //  STATUS TIM (untuk grid ala mesin washing)
  //  GET /api/penerimaan-bahan-baku/tim-status
  // ==========================================
  Future<List<TimPenerimaanInfo>> fetchTimStatus() async {
    final body = await api.getJson('/api/penerimaan-bahan-baku/tim-status');
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
    String? kodeKategori,
  }) async {
    final body = await api.getJson(
      '/api/penerimaan-bahan-baku',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        if (kodeKategori != null && kodeKategori.isNotEmpty) 'kodeKategori': kodeKategori,
      },
    );

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => PenerimaanBahanBaku.fromJson(e as Map<String, dynamic>))
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

  Future<PenerimaanBahanBakuDetail> fetchDetail(String noPenerimaan) async {
    final body = await api.getJson('/api/penerimaan-bahan-baku/$noPenerimaan');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data penerimaan tidak ditemukan');
    return PenerimaanBahanBakuDetail.fromJson(data);
  }

  // ==========================================
  //  CREATE (atomic: header + semua pallet + semua sak)
  //  POST /api/penerimaan-bahan-baku
  // ==========================================
  Future<String> create({
    required DateTime tglPenerimaan,
    required int idTim,
    required int idSupplier,
    String? noPlat,
    required int shift,
    required String hourStart,
    required String hourEnd,
    required String kodeKategori, // KodeKategori dari dbo.MstKategori
    required List<PenerimaanPalletInput> pallets,
  }) async {
    final body = await api.postJson(
      '/api/penerimaan-bahan-baku',
      body: {
        'tglPenerimaan': _dateOnly(tglPenerimaan),
        'idTim': idTim,
        'idSupplier': idSupplier,
        if (noPlat != null && noPlat.trim().isNotEmpty) 'noPlat': noPlat.trim(),
        'shift': shift,
        'hourStart': _normalizeTime(hourStart),
        'hourEnd': _normalizeTime(hourEnd),
        'kodeKategori': kodeKategori,
        'pallets': pallets.map((p) => p.toJson()).toList(),
      },
    );

    final data = body['data'] as Map<String, dynamic>?;
    final noPenerimaan = data?['noPenerimaan']?.toString();
    if (noPenerimaan == null) {
      throw Exception('Response create penerimaan tidak valid');
    }
    return noPenerimaan;
  }

  Future<void> delete(String noPenerimaan) async {
    await api.deleteJson('/api/penerimaan-bahan-baku/$noPenerimaan');
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _normalizeTime(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    return t.length == 5 ? '$t:00' : t;
  }
}
