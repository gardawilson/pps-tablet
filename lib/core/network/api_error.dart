import 'dart:convert';
import 'api_client.dart';

String apiErrorMessage(Object error) {
  if (error is ApiException) {
    // 1) coba ambil message dari responseBody JSON: {"success":false,"message":"..."}
    final raw = error.responseBody;

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map) {
          final msg = decoded['message'];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();

          // fallback kalau backend pakai "error"
          final err = decoded['error'];
          if (err is String && err.trim().isNotEmpty) return err.trim();
        }
      } catch (_) {
        // responseBody bukan JSON -> abaikan
      }
    }

    // 2) fallback: kalau timeout / no-body
    if (error.statusCode == 408) return 'Request timeout';
    if (error.statusCode == 401) return 'Unauthorized. Silakan login ulang.';
    if (error.statusCode == 403) return 'Tidak punya akses.';
    if (error.statusCode == 404) return 'Data tidak ditemukan.';
    if (error.statusCode >= 500) return 'Server error. Coba lagi.';

    // 3) fallback terakhir (jangan pakai error.toString())
    return 'Request gagal (${error.statusCode})';
  }

  return 'Terjadi kesalahan';
}
