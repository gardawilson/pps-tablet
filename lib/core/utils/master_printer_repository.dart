import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

const _kPrinterAliasCache = 'bt_printer_aliases';

/// Repository untuk master data printer (tabel MstPrinter di SQL Server).
/// Alias disimpan di backend agar sinkron di semua tablet.
/// SharedPreferences digunakan sebagai cache offline fallback.
class MasterPrinterRepository {
  final ApiClient api;

  MasterPrinterRepository({required this.api});

  String _friendlyError(ApiException e, String defaultMsg) {
    try {
      if (e.responseBody == null || e.responseBody!.isEmpty) {
        return '$defaultMsg (status: ${e.statusCode})';
      }
      final decoded = jsonDecode(e.responseBody!) as Map<String, dynamic>;
      final msg = (decoded['message'] ?? decoded['error'])?.toString();
      if (msg == null || msg.isEmpty) return '$defaultMsg (status: ${e.statusCode})';
      return '$msg (status: ${e.statusCode})';
    } catch (_) {
      return '$defaultMsg (status: ${e.statusCode})';
    }
  }

  // =============== CACHE HELPERS =================

  static Future<Map<String, String>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrinterAliasCache) ?? '{}';
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  static Future<void> _writeCache(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterAliasCache, jsonEncode(map));
  }

  // =============== PUBLIC API =================

  /// Ambil semua alias dari backend.
  /// Jika berhasil → update cache lokal.
  /// Jika gagal (offline, dll) → fallback ke cache SharedPreferences.
  /// Return: `Map<MacAddress, Alias>`
  Future<Map<String, String>> fetchAliases() async {
    try {
      final body = await api.getJson('/api/mst-printer');
      final List<dynamic> data = body['data'] ?? [];

      final map = <String, String>{};
      for (final item in data) {
        final mac = (item['MacAddress'] ?? '').toString().trim();
        final alias = (item['Alias'] ?? '').toString().trim();
        if (mac.isNotEmpty && alias.isNotEmpty) {
          map[mac] = alias;
        }
      }

      await _writeCache(map);
      debugPrint('✅ MasterPrinter: ${map.length} alias dimuat dari API');
      return map;
    } on ApiException catch (e) {
      debugPrint('⚠️ MasterPrinter fetchAliases gagal: ${_friendlyError(e, 'Gagal fetch alias printer')}');
      return _readCache();
    } catch (e) {
      debugPrint('⚠️ MasterPrinter fetchAliases error: $e');
      return _readCache();
    }
  }

  /// Simpan atau update alias printer (UPSERT by MacAddress).
  /// Juga update cache lokal.
  Future<void> upsert(String mac, String alias, {String? description}) async {
    try {
      await api.postJson('/api/mst-printer', body: {
        'MacAddress': mac,
        'Alias': alias,
        if (description != null && description.isNotEmpty)
          'Description': description,
      });

      final cache = await _readCache();
      cache[mac] = alias;
      await _writeCache(cache);
      debugPrint('💾 MasterPrinter upsert: "$alias" → $mac');
    } on ApiException catch (e) {
      throw Exception(_friendlyError(e, 'Gagal menyimpan nama printer'));
    }
  }

  /// Hapus alias printer berdasarkan MAC address.
  /// Juga hapus dari cache lokal.
  Future<void> remove(String mac) async {
    try {
      await api.deleteJson('/api/mst-printer/${Uri.encodeComponent(mac)}');

      final cache = await _readCache();
      cache.remove(mac);
      await _writeCache(cache);
      debugPrint('🗑️ MasterPrinter remove: $mac');
    } on ApiException catch (e) {
      throw Exception(_friendlyError(e, 'Gagal menghapus alias printer'));
    }
  }
}
