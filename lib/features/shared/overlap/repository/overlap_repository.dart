import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/utils/date_formatter.dart'; // toDbDateString(DateTime)

class OverlapConflict {
  final String noDoc;
  final String hourStart;
  final String hourEnd;
  final DateTime? startDT;
  final DateTime? endDT;

  OverlapConflict({
    required this.noDoc,
    required this.hourStart,
    required this.hourEnd,
    this.startDT,
    this.endDT,
  });

  factory OverlapConflict.fromJson(Map<String, dynamic> j) {
    DateTime? _parse(String? s) {
      if (s == null) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }

    return OverlapConflict(
      noDoc: (j['NoDoc'] ?? j['NoProduksi'] ?? j['NoCrusherProduksi'] ?? '').toString(),
      hourStart: (j['HourStart'] ?? '').toString(),
      hourEnd: (j['HourEnd'] ?? '').toString(),
      startDT: _parse(j['StartDT']?.toString()),
      endDT: _parse(j['EndDT']?.toString()),
    );
  }
}

class OverlapResult {
  final bool isOverlap;
  final List<OverlapConflict> conflicts;

  OverlapResult({required this.isOverlap, required this.conflicts});

  factory OverlapResult.fromJson(Map<String, dynamic> j) {
    final list = (j['conflicts'] as List?) ?? const [];
    return OverlapResult(
      isOverlap: j['isOverlap'] == true,
      conflicts: list.map((e) => OverlapConflict.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OverlapRepository {
  static const _timeout = Duration(seconds: 20);

  final String _base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Future<OverlapResult> check({
    required String kind, // 'broker' | 'crusher' | 'washing' | 'gilingan'
    required DateTime date,
    required int idMesin,
    required String hourStart, // "HH:mm" (detik opsional aman)
    required String hourEnd,   // "HH:mm"
    String? excludeNo,         // No dokumen saat edit
  }) async {
    final token = await TokenStorage.getToken();
    final ymd = toDbDateString(date); // YYYY-MM-DD

    final uri = Uri.parse('$_base/api/production/$kind/overlap').replace(queryParameters: {
      'date': ymd,
      'idMesin': idMesin.toString(),
      'start': hourStart,
      'end': hourEnd,
      if (excludeNo != null && excludeNo.isNotEmpty) 'exclude': excludeNo,
    });

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Overlap check failed (${res.statusCode}): ${res.body}');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    return OverlapResult.fromJson(map);
  }
}
