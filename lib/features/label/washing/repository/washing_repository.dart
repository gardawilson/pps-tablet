import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pps_tablet/core/utils/date_formatter.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';

class WashingRepository {
  /// Ambil daftar washing dengan pagination & search
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/washing?page=$page&limit=$limit&search=$search",
    );

    print("➡️ Fetching Washing Headers: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      final List<dynamic> data = body['data'] ?? [];
      final List<WashingHeader> items =
      data.map((e) => WashingHeader.fromJson(e)).toList();

      // meta bisa beda tergantung API kamu, cek apakah body sudah ada
      final meta = body['meta'] ?? {};

      return {
        "items": items,
        "page": meta['page'] ?? page,
        "limit": meta['limit'] ?? limit,
        "total": meta['total'] ?? items.length,
        "totalPages": meta['totalPages'] ?? 1,
      };
    } else {
      throw Exception(
        'Gagal fetch data washing (status: ${response.statusCode})',
      );
    }
  }


  /// Ambil detail washing berdasarkan NoWashing
  Future<List<WashingDetail>> fetchDetails(String noWashing) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/washing/$noWashing",
    );

    print("➡️ Fetching Washing Details: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> details = body['data']?['details'] ?? [];
      return details.map((e) => WashingDetail.fromJson(e)).toList();
    } else {
      throw Exception(
        'Gagal fetch detail washing (status: ${response.statusCode})',
      );
    }
  }


  /// Create washing (header + details)
  Future<Map<String, dynamic>> createWashing({
    required WashingHeader header,
    required List<WashingDetail> details,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/washing");

    // 🔎 Validasi NoProduksi / NoBongkarSusun: salah satu wajib ada
    final hasNoProduksi = (header.noProduksi != null && header.noProduksi!.trim().isNotEmpty);
    final hasNoBongkar = (header.noBongkarSusun != null && header.noBongkarSusun!.trim().isNotEmpty);

    if (!hasNoProduksi && !hasNoBongkar) {
      throw ArgumentError("NoProduksi atau NoBongkarSusun harus diisi minimal salah satu.");
    }

    // 🔁 Tentukan field referensi yang dikirim
    final refKey = hasNoProduksi ? 'NoProduksi' : 'NoBongkarSusun';
    final refVal = hasNoProduksi ? header.noProduksi : header.noBongkarSusun;

    // ⚙️ Susun body sesuai spesifikasi API kamu
    final body = <String, dynamic>{
      "header": {
        "IdJenisPlastik": header.idJenisPlastik,
        "DateCreate": toDbDateString(header.dateCreate),
        "IdWarehouse": 2,          // pastikan form kamu mengisi ini
        // "CreateBy": header.createBy ?? "mobile",     // fallback
        // "IdStatus": header.idStatus ?? 1,            // fallback
        // "Blok": header.blok ?? "A",                  // jika model punya; jika tidak, sesuaikan
        // "IdLokasi": (header.idLokasi?.toString() ?? ""), // string sesuai contoh
        // "Density": header.density,                   // jika null akan jadi null
        // "Moisture": header.moisture,
      },
      "details": details.map((d) => {
        "NoSak": d.noSak,
        "Berat": d.berat,
      }).toList(),
      refKey: refVal, // hanya satu dari keduanya yg dikirim
    };

    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    // Log biar enak debug
    print("➡️ POST Create Washing: $url");
    print("📦 Body: ${json.encode(body)}");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal create washing (status: ${resp.statusCode})');
  }


  /// Update washing (header + details) by NoWashing
  Future<Map<String, dynamic>> updateWashing({
    required String noWashing,            // contoh: "B.0000031886"
    required WashingHeader header,
    required List<WashingDetail> details,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/washing/$noWashing");

    // ➕ Validasi referensi (opsional, sesuai BE kamu)
    final hasNoProduksi = (header.noProduksi != null && header.noProduksi!.trim().isNotEmpty);
    final hasNoBongkar  = (header.noBongkarSusun != null && header.noBongkarSusun!.trim().isNotEmpty);

    if (!hasNoProduksi && !hasNoBongkar) {
      throw ArgumentError("NoProduksi atau NoBongkarSusun harus diisi minimal salah satu (EDIT).");
    }

    final refKey = hasNoProduksi ? 'NoProduksi' : 'NoBongkarSusun';
    final refVal = hasNoProduksi ? header.noProduksi : header.noBongkarSusun;

    // ⚙️ Susun header sesuai spesifikasi EDIT (tanpa DateCreate).
    // Hanya kirim field yang tidak null (biar aman).
    final headerMap = <String, dynamic>{
      "IdJenisPlastik": header.idJenisPlastik,
      "IdWarehouse": 2,      // atau isi defaultmu
      // "CreateBy": (header.createBy?.isNotEmpty ?? false) ? header.createBy : "mobile",
      // "IdStatus": header.idStatus,                 // boleh null -> akan dihapus di bawah
      // Optional:
      // "Blok": header.blok,
      // "IdLokasi": header.idLokasi?.toString(),
      // "Density": header.density,
      // "Moisture": header.moisture,
    }..removeWhere((k, v) => v == null);

    final body = <String, dynamic>{
      "header": headerMap,
      "details": details.map((d) => {
        "NoSak": d.noSak,
        "Berat": d.berat,
        "IdLokasi": d.idLokasi, // kirim null jika memang null
      }).toList(),
      refKey: refVal,
    };

    final resp = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    // Log buat debug
    print("➡️ PUT Update Washing: $url");
    print("📦 Body: ${json.encode(body)}");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal update washing (status: ${resp.statusCode})');
  }


  /// Delete washing by NoWashing
  Future<void> deleteWashing(String noWashing) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/washing/$noWashing");

    final resp = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("🗑️ DELETE Washing: $url");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    // banyak API mengembalikan 200/202/204 untuk delete yang sukses
    if (resp.statusCode == 200 || resp.statusCode == 202 || resp.statusCode == 204) {
      return;
    }
    // kalau BE kirim pesan error, naikkan biar bisa ditampilkan
    final msg = (resp.body.isNotEmpty) ? resp.body : 'Gagal delete (status: ${resp.statusCode})';
    throw Exception(msg);
  }


}
