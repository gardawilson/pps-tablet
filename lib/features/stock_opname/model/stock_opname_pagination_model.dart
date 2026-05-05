import 'stock_opname_model.dart';

class StockOpnamePaginationResponse {
  final List<StockOpname> data;
  final int total;
  final int page;
  final int limit;

  StockOpnamePaginationResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory StockOpnamePaginationResponse.fromJson(Map<String, dynamic> json) {
    return StockOpnamePaginationResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => StockOpname.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _asInt(json['total'], 0),
      page: _asInt(json['page'], 1),
      limit: _asInt(json['limit'], 10),
    );
  }
}
