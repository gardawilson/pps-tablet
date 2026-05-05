import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/endpoints.dart';
import '../services/token_storage.dart';
import '../services/user_session_storage.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class DevicePrinter {
  final String id;
  final String identifier; // MAC address
  final String name;
  final String printUsage;
  final String? lastUsedAt;
  final String status;

  const DevicePrinter({
    required this.id,
    required this.identifier,
    required this.name,
    required this.printUsage,
    this.lastUsedAt,
    required this.status,
  });

  factory DevicePrinter.fromJson(Map<String, dynamic> json) {
    return DevicePrinter(
      id: json['id']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      printUsage: json['printUsage']?.toString() ?? '0/0',
      lastUsedAt: json['lastUsedAt']?.toString(),
      status: json['status']?.toString() ?? 'NORMAL',
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Service untuk berinteraksi dengan microservice printer
/// di endpoint [ApiConstants.deviceApiUrl].
class DevicePrinterService {
  DevicePrinterService._();

  static String get _base =>
      ApiConstants.deviceApiUrl.replaceFirst(RegExp(r'/*$'), '');

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ── List printers ──────────────────────────────────────────────────────────

  /// GET /api/devices/printers
  /// Returns list printer yang terdaftar di microservice.
  static Future<List<DevicePrinter>> fetchPrinters() async {
    final uri = Uri.parse('$_base/api/devices/printers');
    final resp = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Gagal mengambil daftar printer (${resp.statusCode})');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (body['printers'] as List<dynamic>? ?? []);
    return list
        .map((e) => DevicePrinter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Get single printer ─────────────────────────────────────────────────────

  /// GET /api/devices/printers/{id}
  /// Ambil detail printer + status + printUsage terkini.
  static Future<DevicePrinter> getPrinter(String id) async {
    final uri = Uri.parse('$_base/api/devices/printers/$id');
    final resp = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw Exception('Gagal mengambil info printer (${resp.statusCode})');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return DevicePrinter.fromJson(body);
  }

  // ── Register printer ───────────────────────────────────────────────────────

  /// POST /api/devices/printers
  /// Daftarkan printer baru berdasarkan MAC address.
  static Future<DevicePrinter> registerPrinter({
    required String mac,
    required String name,
  }) async {
    final uri = Uri.parse('$_base/api/devices/printers');
    final resp = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'mac': mac, 'name': name}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      String detail = '';
      try {
        final b = jsonDecode(resp.body) as Map<String, dynamic>;
        detail = b['message']?.toString() ?? '';
      } catch (_) {}
      throw Exception(
          'Gagal mendaftarkan printer (${resp.statusCode})${detail.isNotEmpty ? ': $detail' : ''}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    // response bisa wrap dalam key 'data' atau langsung objek printer
    final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
    return DevicePrinter.fromJson(data);
  }

  // ── Log print ──────────────────────────────────────────────────────────────

  /// POST /api/devices/printers/log
  /// Catat aktivitas print. [printerId] = MAC address printer.
  static Future<void> logPrint({
    required String printerId,
    required String printBy,
  }) async {
    final uri = Uri.parse('$_base/api/devices/printers/log');
    try {
      final resp = await http
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'printerId': printerId,
              'sourceApp': 'PPS',
              'printBy': printBy,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('🖨️ Print log: ${resp.statusCode}');
    } catch (e) {
      // log gagal tidak boleh mengganggu flow utama
      debugPrint('⚠️ Gagal kirim print log: $e');
    }
  }

  // ── Save / load default printer ────────────────────────────────────────────

  static const _kDevicePrinterId = 'device_printer_id';
  static const _kDevicePrinterMac = 'device_printer_mac';
  static const _kDevicePrinterName = 'device_printer_name';

  static Future<void> saveDefaultPrinter(DevicePrinter printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDevicePrinterId, printer.id);
    await prefs.setString(_kDevicePrinterMac, printer.identifier);
    await prefs.setString(_kDevicePrinterName, printer.name);
    debugPrint('💾 Default printer disimpan: ${printer.name} (${printer.identifier})');
  }

  static Future<({String id, String mac, String name})?> loadDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kDevicePrinterId);
    final mac = prefs.getString(_kDevicePrinterMac);
    final name = prefs.getString(_kDevicePrinterName);
    if (id == null || id.isEmpty || mac == null || mac.isEmpty) return null;
    return (id: id, mac: mac, name: name ?? mac);
  }

  // ── Get logged-in username ─────────────────────────────────────────────────

  static Future<String> getLoggedUsername() async {
    return UserSessionStorage.getUsername();
  }
}
