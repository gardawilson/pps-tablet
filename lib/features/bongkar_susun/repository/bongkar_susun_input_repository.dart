// lib/features/shared/bongkar_susun/repository/bongkar_susun_input_repository.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../production/shared/models/production_label_lookup_result.dart';
import '../model/bongkar_susun_inputs_model.dart';

class BongkarSusunInputRepository {
  final ApiClient _apiClient;

  BongkarSusunInputRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final Map<String, BongkarSusunInputs> _inputsCache = {};

  // -----------------------------
  // fetchInputs
  // -----------------------------
  static BongkarSusunInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return BongkarSusunInputs.fromJson(data);
  }

  /// GET /api/bongkar-susun/:noBongkarSusun/inputs
  Future<BongkarSusunInputs> fetchInputs(
      String noBongkarSusun, {
        bool force = false,
      }) async {
    final key = noBongkarSusun.trim();
    if (key.isEmpty) {
      throw ArgumentError('noBongkarSusun tidak boleh kosong');
    }

    if (!force && _inputsCache.containsKey(key)) {
      return _inputsCache[key]!;
    }

    try {
      final body = await _apiClient.getJson(
        '/api/bongkar-susun/$key/inputs',
      );

      // parsing di isolate biar UI tetap smooth
      final inputs = await compute(_parseInputs, body);

      _inputsCache[key] = inputs;
      return inputs;
    } on ApiException catch (e) {
      // opsional: kalau backend kadang 404 artinya belum ada input sama sekali
      if (e.statusCode == 404) {
        // kalau kamu mau: bisa return BongkarSusunInputs.empty() kalau ada factory nya
        // untuk saat ini, kita lempar error agar caller bisa tampilkan pesan.
      }
      rethrow;
    }
  }

  void invalidateInputs(String noBongkarSusun) =>
      _inputsCache.remove(noBongkarSusun.trim());

  void clearCache() => _inputsCache.clear();

  // -----------------------------
  // validateLabel / lookupLabel
  // -----------------------------
  /// GET /api/bongkar-susun/validate-label/:labelCode
  Future<ProductionLabelLookupResult> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) {
      throw ArgumentError('labelCode tidak boleh kosong');
    }

    try {
      final body = await _apiClient.getJson(
        '/api/bongkar-susun/validate-label/${Uri.encodeComponent(code)}',
      );
      // kalau 200 berarti sukses
      return ProductionLabelLookupResult.success(body);
    } on ApiException catch (e) {
      // kalau 404, tetap return notFound (sesuai behaviour lama)
      if (e.statusCode == 404) {
        Map<String, dynamic> parsed = {};
        // coba decode body jika tersedia
        if (e.responseBody != null && e.responseBody!.trim().isNotEmpty) {
          try {
            // ApiClient sudah decode JSON saat sukses, tapi untuk error statusCode
            // responseBody masih string mentah, jadi kita coba parse manual.
            parsed = await compute(_safeJsonDecodeToMap, e.responseBody!);
          } catch (_) {}
        }
        return ProductionLabelLookupResult.notFound(parsed);
      }

      // selain 404, lempar message yang lebih enak
      final msg = (e.responseBody?.isNotEmpty ?? false)
          ? 'Gagal lookup label ($code) (HTTP ${e.statusCode})'
          : (e.message.isNotEmpty ? e.message : 'Gagal lookup label ($code)');
      throw Exception(msg);
    }
  }

  // helper buat parse responseBody error (string) -> map
  static Map<String, dynamic> _safeJsonDecodeToMap(String raw) {
    try {
      final dynamic decoded = jsonDecodeLoose(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // json decode yang toleran (tetap sederhana)
  static dynamic jsonDecodeLoose(String raw) {
    // ignore: avoid_dynamic_calls
    return (raw.isEmpty) ? <String, dynamic>{} : jsonDecode(raw);
  }

  // -----------------------------
  // Submit Inputs
  // -----------------------------
  /// POST /api/bongkar-susun/:noBongkarSusun/inputs
  Future<Map<String, dynamic>> submitInputs(
      String noBongkarSusun,
      Map<String, dynamic> payload,
      ) async {
    final key = noBongkarSusun.trim();
    if (key.isEmpty) throw ArgumentError('noBongkarSusun tidak boleh kosong');

    try {
      final body = await _apiClient.postJson(
        '/api/bongkar-susun/$key/inputs',
        body: payload,
      );

      // kalau submit sukses, biasanya inputs berubah → invalid cache biar reload fresh
      invalidateInputs(key);

      return body;
    } on ApiException catch (e) {
      // samakan dengan logic lama: 422/400 -> lempar message dari server kalau ada
      final messageFromServer = _extractMessage(e.responseBody);

      if (e.statusCode == 422) {
        throw Exception(messageFromServer ?? 'Beberapa data tidak valid');
      }
      if (e.statusCode == 400) {
        throw Exception(messageFromServer ?? 'Request tidak valid');
      }

      throw Exception(messageFromServer ??
          'Gagal submit inputs (HTTP ${e.statusCode})');
    }
  }

  // -----------------------------
  // Delete Inputs
  // -----------------------------
  /// DELETE /api/bongkar-susun/:noBongkarSusun/inputs
  ///
  /// Backend:
  /// - 200 => success (bisa dengan warning)
  /// - 404 => tidak ada data yang terhapus, tapi tetap response JSON yang rapi
  /// - 400 => request tidak valid
  Future<Map<String, dynamic>> deleteInputs(
      String noBongkarSusun,
      Map<String, dynamic> payload,
      ) async {
    final key = noBongkarSusun.trim();
    if (key.isEmpty) throw ArgumentError('noBongkarSusun tidak boleh kosong');

    try {
      final body = await _apiClient.deleteJson(
        '/api/bongkar-susun/$key/inputs',
        body: payload,
      );

      // delete sukses / warning → cache invalid supaya refresh
      invalidateInputs(key);

      return body;
    } on ApiException catch (e) {
      final messageFromServer = _extractMessage(e.responseBody);

      // sesuai komentar lama: 404 juga bisa dianggap "valid response" (tidak ada yg terhapus)
      if (e.statusCode == 404) {
        // kalau backend memang mengembalikan JSON rapi di 404, lebih baik kita coba parse
        if (e.responseBody != null && e.responseBody!.trim().isNotEmpty) {
          try {
            return await compute(_safeJsonDecodeToMap, e.responseBody!);
          } catch (_) {}
        }
        return <String, dynamic>{
          'success': false,
          'message': messageFromServer ?? 'Tidak ada data yang terhapus',
        };
      }

      if (e.statusCode == 400) {
        throw Exception(messageFromServer ?? 'Request delete inputs tidak valid');
      }

      throw Exception(
          messageFromServer ?? 'Gagal delete inputs (HTTP ${e.statusCode})');
    }
  }

  static String? _extractMessage(String? responseBody) {
    if (responseBody == null || responseBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}
    return null;
  }
}
