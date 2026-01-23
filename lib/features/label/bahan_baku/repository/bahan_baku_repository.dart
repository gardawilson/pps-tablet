// lib/features/production/bahan_baku/repository/bahan_baku_repository.dart
import 'dart:math';

import '../../../../core/network/api_client.dart';
import '../model/bahan_baku_header.dart';
import '../model/bahan_baku_pallet.dart';
import '../model/bahan_baku_pallet_detail.dart';

class BahanBakuRepository {
  final ApiClient api;

  BahanBakuRepository({required this.api});

  /// Ambil daftar bahan baku header dengan pagination & search
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final body = await api.getJson(
      '/api/labels/bahan-baku',
      query: {
        'page': page,
        'limit': limit,
        'search': search,
      },
    );

    final List<dynamic> data = body['data'] ?? [];
    final items = data
        .map((e) => BahanBakuHeader.fromJson(e as Map<String, dynamic>))
        .toList();

    final int total = (body['total'] is num)
        ? (body['total'] as num).toInt()
        : (body['meta']?['total'] ?? items.length);

    final int pageOut = body['meta']?['page'] ?? page;
    final int limitOut = body['meta']?['limit'] ?? limit;

    final int totalPages = (limitOut > 0)
        ? ((total + limitOut - 1) ~/ limitOut)
        : 1;

    return {
      'items': items,
      'page': pageOut,
      'limit': limitOut,
      'total': total,
      'totalPages': max(totalPages, 1),
    };
  }

  /// Ambil daftar pallet berdasarkan NoBahanBaku
  Future<List<BahanBakuPallet>> fetchPallets(String noBahanBaku) async {
    final body = await api.getJson(
      '/api/labels/bahan-baku/$noBahanBaku/pallet',
    );

    final List<dynamic> pallets = body['data']?['pallets'] ?? [];
    return pallets
        .map((e) => BahanBakuPallet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil detail pallet (list NoSak) berdasarkan NoBahanBaku dan NoPallet
  Future<List<BahanBakuPalletDetail>> fetchPalletDetails({
    required String noBahanBaku,
    required String noPallet,
  }) async {
    final body = await api.getJson(
      '/api/labels/bahan-baku/$noBahanBaku/pallet/$noPallet',
    );

    final List<dynamic> details = body['data']?['details'] ?? [];
    return details
        .map((e) => BahanBakuPalletDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}