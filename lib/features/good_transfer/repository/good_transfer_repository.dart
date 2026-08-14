// lib/features/good_transfer/repository/good_transfer_repository.dart
import 'package:pps_tablet/core/network/api_client.dart';

import '../model/good_transfer_header_model.dart';
import '../model/good_transfer_item_model.dart';
import '../model/good_transfer_scanned_label.dart';

class GoodTransferRepository {
  final ApiClient api;

  GoodTransferRepository({required this.api});

  /// Validasi 1 label sebelum ditambahkan ke daftar transfer: mengecek label
  /// dikenali, belum terpakai, tidak sedang IN_TRANSIT, dan bloknya saat ini
  /// memang milik [idWarehouseAsal]. Melempar [ApiException] kalau gagal.
  Future<GoodTransferScannedLabel> inspectLabel({
    required String labelCode,
    required int idWarehouseAsal,
  }) async {
    final body = await api.getJson(
      '/api/good-transfer/inspect-label',
      query: {
        'labelCode': labelCode,
        'idWarehouseAsal': idWarehouseAsal.toString(),
      },
    );
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data label tidak ditemukan');
    return GoodTransferScannedLabel.fromJson(data);
  }

  /// List semua transaksi Good Transfer (tanpa filter warehouse) — dipakai di
  /// menu utama Good Transfer, karena warehouse asal ditentukan saat create,
  /// bukan sebagai filter di layar ini.
  Future<List<GoodTransferHeader>> fetchAll({String? status}) async {
    final body = await api.getJson(
      '/api/good-transfer',
      query: {if (status != null) 'status': status},
    );
    final data = body['data'];
    if (data is! List) throw Exception('Format data transfer tidak sesuai');
    return data
        .map((e) => GoodTransferHeader.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GoodTransferDetail> fetchDetail(String noTransfer) async {
    final body = await api.getJson('/api/good-transfer/$noTransfer');
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data transfer tidak ditemukan');

    final rawItems = data['items'];
    final items = (rawItems is List ? rawItems : <dynamic>[])
        .map((e) => GoodTransferItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return GoodTransferDetail(
      header: data['header'] as Map<String, dynamic>? ?? {},
      items: items,
    );
  }

  Future<String> createTransfer({
    required int idWarehouseAsal,
    required int idWarehouseTujuan,
    required List<String> labelCodes,
    DateTime? tanggalKirim,
    String? catatan,
  }) async {
    final body = await api.postJson(
      '/api/good-transfer',
      body: {
        'idWarehouseAsal': idWarehouseAsal,
        'idWarehouseTujuan': idWarehouseTujuan,
        'labelCodes': labelCodes,
        if (tanggalKirim != null)
          'tanggalKirim': tanggalKirim.toIso8601String(),
        if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan,
      },
    );
    final data = body['data'] as Map<String, dynamic>?;
    return (data?['noTransfer'] ?? '').toString();
  }

  Future<void> cancelTransfer(String noTransfer) async {
    await api.postJson('/api/good-transfer/$noTransfer/cancel');
  }
}
