// lib/features/in_transit/repository/in_transit_repository.dart
import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/good_transfer/model/good_transfer_header_model.dart';
import 'package:pps_tablet/features/good_transfer/model/good_transfer_item_model.dart';

class InTransitRepository {
  final ApiClient api;

  InTransitRepository({required this.api});

  /// List semua transaksi Good Transfer (tanpa filter warehouse) — sama
  /// dengan yang dipakai menu Good Transfer, supaya format & datanya konsisten.
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

  /// Terima 1 label lewat scan: label akan di-update ke [blokTujuan]/
  /// [idLokasiTujuan] dan ditandai RECEIVED. Backend otomatis menentukan
  /// transfer mana yang memiliki label ini (lewat status IN_TRANSIT).
  Future<Map<String, dynamic>> acceptScan({
    required String labelCode,
    required String blokTujuan,
    required int idLokasiTujuan,
  }) async {
    final body = await api.postJson(
      '/api/good-transfer/accept-scan',
      body: {
        'labelCode': labelCode,
        'blokTujuan': blokTujuan,
        'idLokasiTujuan': idLokasiTujuan,
      },
    );
    return body['data'] as Map<String, dynamic>? ?? {};
  }
}
