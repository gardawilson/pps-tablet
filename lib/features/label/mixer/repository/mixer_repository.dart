import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pps_tablet/core/utils/date_formatter.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/mixer_header_model.dart';
import '../model/mixer_detail_model.dart';
import '../model/mixer_partial_model.dart';

class MixerRepository {
  /// Fetch mixer headers with pagination & search
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/mixer?page=$page&limit=$limit&search=$search",
    );

    print("➡️ Fetching Mixer Headers: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      // BE: { success, data: [...], meta: { page, limit, total, totalPages } }
      final List<dynamic> data = body['data'] ?? [];

      final List<MixerHeader> items = data
          .map((e) => MixerHeader.fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      final int total = (meta['total'] is num)
          ? (meta['total'] as num).toInt()
          : items.length;
      final int pageOut = meta['page'] ?? page;
      final int limitOut = meta['limit'] ?? limit;
      final int totalPages = (limitOut is int && limitOut > 0)
          ? ((total + limitOut - 1) ~/ limitOut)
          : 1;

      return {
        "items": items,
        "page": pageOut,
        "limit": limitOut,
        "total": total,
        "totalPages": totalPages,
      };
    } else {
      throw Exception(
        'Failed to fetch mixer headers (status: ${response.statusCode})',
      );
    }
  }

  /// Fetch mixer details by NoMixer
  Future<List<MixerDetail>> fetchDetails(String noMixer) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/mixer/$noMixer");

    print("➡️ Fetching Mixer Details: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      // BE: { success, data: { nomixer, details: [...] } }
      final List<dynamic> details = body['data']?['details'] ?? [];
      return details
          .map((e) => MixerDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch mixer details (status: ${response.statusCode})',
      );
    }
  }

  /// Create mixer (header + details + outputCode WAJIB)
  ///
  /// - outputCode:
  ///   - "BG.XXXX" → BongkarSusunOutputMixer
  ///   - "I.XXXX"  → MixerProduksiOutput
  Future<Map<String, dynamic>> createMixer({
    required MixerHeader header,
    required List<MixerDetail> details,
    required String outputCode, // <-- WAJIB sekarang
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/mixer");

    // --------------------------------------------------------------------------
    // 1) Build headerMap
    // --------------------------------------------------------------------------
    final headerMap = <String, dynamic>{
      "IdMixer": header.idMixer,
      "DateCreate": toDbDateString(header.dateCreate),
      // status: true → 1, false → 0
      if (header.idStatus != null) "IdStatus": header.idStatus! ? 1 : 0,
      "Blok": header.blok,
      "IdLokasi": header.idLokasi,
      "Moisture": header.moisture,
      "MaxMeltTemp": header.maxMeltTemp,
      "MinMeltTemp": header.minMeltTemp,
      "MFI": header.mfi,
      "Moisture2": header.moisture2,
      "Moisture3": header.moisture3,
      // "CreateBy" biasanya di-set di backend dari token (optional)
    }..removeWhere((key, value) => value == null);

    // --------------------------------------------------------------------------
    // 2) Build body (header + details + outputCode WAJIB)
    // --------------------------------------------------------------------------
    final body = <String, dynamic>{
      "header": headerMap,
      "details": details
          .map(
            (d) => {
              "NoSak": d.noSak,
              "Berat": d.berat,
              // no IdLokasi, no IsPartial here (IsPartial always 0 in BE)
            },
          )
          .toList(),
      "outputCode": outputCode, // <-- selalu dikirim
    };

    // --------------------------------------------------------------------------
    // 3) LOGGING SEBELUM KIRIM
    // --------------------------------------------------------------------------
    const encoder = JsonEncoder.withIndent('  ');

    debugPrint(
      '==================== [MixerRepository] createMixer ====================',
    );
    debugPrint('➡️  URL           : $url');
    debugPrint(
      '➡️  Token (short) : ${token != null && token.length > 20 ? token.substring(0, 20) + '...' : token}',
    );
    debugPrint('➡️  OutputCode    : $outputCode');
    debugPrint('➡️  HeaderMap     :\n${encoder.convert(headerMap)}');
    debugPrint('➡️  Details count : ${details.length}');
    debugPrint('➡️  Details body  :\n${encoder.convert(body["details"])}');
    debugPrint('➡️  FULL BODY     :\n${encoder.convert(body)}');

    // --------------------------------------------------------------------------
    // 4) KIRIM REQUEST
    // --------------------------------------------------------------------------
    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    debugPrint('⬅️  Response status : ${resp.statusCode}');
    debugPrint('⬅️  Response body   : ${resp.body}');
    debugPrint(
      '=====================================================================',
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to create mixer (status: ${resp.statusCode})');
  }

  /// Update mixer (header + details + optional outputCode) by NoMixer
  ///
  /// - If [outputCode] is:
  ///   - null → do not touch existing outputs
  ///   - ""   → clear all outputs
  ///   - "BG.XXXX" / "I.XXXX" → re-map outputs
  Future<Map<String, dynamic>> updateMixer({
    required String noMixer,
    required MixerHeader header,
    required List<MixerDetail> details,
    String? outputCode,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/mixer/$noMixer");

    // Only send fields you actually want to update
    final headerMap = <String, dynamic>{
      "IdMixer": header.idMixer,
      if (header.idStatus != null) "IdStatus": header.idStatus! ? 1 : 0,
      "Blok": header.blok,
      "IdLokasi": header.idLokasi,
      "Moisture": header.moisture,
      "MaxMeltTemp": header.maxMeltTemp,
      "MinMeltTemp": header.minMeltTemp,
      "MFI": header.mfi,
      "Moisture2": header.moisture2,
      "Moisture3": header.moisture3,
      // If you later allow editing DateCreate from UI, you can add:
      // "DateCreate": toDbDateString(header.dateCreate),
    }..removeWhere((k, v) => v == null);

    final body = <String, dynamic>{
      "header": headerMap,
      // As in Broker: sending "details" will REPLACE all details with DateUsage IS NULL
      "details": details
          .map((d) => {"NoSak": d.noSak, "Berat": d.berat})
          .toList(),
    };

    if (outputCode != null) {
      body["outputCode"] = outputCode;
    }

    final resp = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    print("➡️ PUT Update Mixer: $url");
    print("📦 Body: ${json.encode(body)}");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update mixer (status: ${resp.statusCode})');
  }

  /// Delete mixer by NoMixer
  Future<void> deleteMixer(String noMixer) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/mixer/$noMixer");

    final resp = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("🗑️ DELETE Mixer: $url");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200 ||
        resp.statusCode == 202 ||
        resp.statusCode == 204) {
      return;
    }

    final msg = (resp.body.isNotEmpty)
        ? resp.body
        : 'Failed to delete mixer (status: ${resp.statusCode})';
    throw Exception(msg);
  }

  /// Fetch partial info for Mixer NoMixer + NoSak
  Future<MixerPartialInfo> fetchPartialInfo({
    required String noMixer,
    required int noSak,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/mixer/partials/$noMixer/$noSak",
    );

    print("➡️ Fetching Mixer Partial Info: $url");

    final resp = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode != 200) {
      throw Exception(
        "Failed to fetch mixer partial info (${resp.statusCode})",
      );
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    return MixerPartialInfo.fromEnvelope(body);
  }
}
