import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';

typedef ActiveShift = ({int shift, String hourStart, String hourEnd});

class ShiftRepository {
  static const _timeout = Duration(seconds: 8);

  static Future<ActiveShift?> fetchCurrentShift() async {
    try {
      final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');
      final url = Uri.parse('$base/api/mst/shift/current');
      debugPrint('➡️ [GET] $url');
      final token = await TokenStorage.getToken();
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);
      debugPrint('⬅️ [${res.statusCode}] shift/current → ${res.body}');
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final shift = data['shift'] as int?;
      if (shift == null) return null;
      String trim(String? v) =>
          (v != null && v.length >= 5) ? v.substring(0, 5) : (v ?? '');
      final hourStart = trim(data['hourStart'] as String?);
      final hourEnd = trim(data['hourEnd'] as String?);
      debugPrint('✅ activeShift: shift=$shift, start=$hourStart, end=$hourEnd');
      return (shift: shift, hourStart: hourStart, hourEnd: hourEnd);
    } catch (e) {
      debugPrint('❌ ShiftRepository.fetchCurrentShift error: $e');
      return null;
    }
  }
}
