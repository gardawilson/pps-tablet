import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pps_tablet/core/utils/date_formatter.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/broker_header_model.dart';
import '../model/broker_detail_model.dart';
import '../model/broker_partial_model.dart';

class BrokerRepository {

  /// Ambil daftar broker header dengan pagination & search
  Future<Map<String, dynamic>> fetchHeaders({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/broker?page=$page&limit=$limit&search=$search",
    );

    print("➡️ Fetching Broker Headers: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      // BE service you shared returns { data: [...], total: n }
      final List<dynamic> data = body['data'] ?? [];

      final List<BrokerHeader> items =
      data.map((e) => BrokerHeader.fromJson(e as Map<String, dynamic>)).toList();

      final int total = (body['total'] is num)
          ? (body['total'] as num).toInt()
          : (body['meta']?['total'] ?? items.length);

      final int pageOut = body['meta']?['page'] ?? page;
      final int limitOut = body['meta']?['limit'] ?? limit;
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
        'Gagal fetch data broker (status: ${response.statusCode})',
      );
    }
  }



  /// Ambil detail broker berdasarkan NoBroker
  Future<List<BrokerDetail>> fetchDetails(String noBroker) async {
    final token = await TokenStorage.getToken();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/broker/$noBroker",
    );

    print("➡️ Fetching Broker Details: $url");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ Response [${response.statusCode}]: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> details = body['data']?['details'] ?? [];
      return details.map((e) => BrokerDetail.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
        'Gagal fetch detail broker (status: ${response.statusCode})',
      );
    }
  }



  /// Create washing (header + details)
  Future<Map<String, dynamic>> createBroker({
    required BrokerHeader header,
    required List<BrokerDetail> details,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/broker");

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
        "IdWarehouse": 3,          // pastikan form kamu mengisi ini
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
        "IdLokasi": (d.idLokasi?.toString() ?? ""),  // kosongkan "" jika tidak ada
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
    print("➡️ POST Create Broker: $url");
    print("📦 Body: ${json.encode(body)}");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal create washing (status: ${resp.statusCode})');
  }


  /// Update washing (header + details) by NoBroker
  Future<Map<String, dynamic>> updateBroker({
    required String noBroker,            // contoh: "D.0000031886"
    required BrokerHeader header,
    required List<BrokerDetail> details,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/broker/$noBroker");

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
      "IdWarehouse": 3,      // atau isi defaultmu
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
    print("➡️ PUT Update Broker: $url");
    print("📦 Body: ${json.encode(body)}");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal update washing (status: ${resp.statusCode})');
  }


  /// Delete washing by NoBroker
  Future<void> deleteBroker(String noBroker) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/labels/broker/$noBroker");

    final resp = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("🗑️ DELETE Broker: $url");
    print("⬅️ Response [${resp.statusCode}]: ${resp.body}");

    // banyak API mengembalikan 200/202/204 untuk delete yang sukses
    if (resp.statusCode == 200 || resp.statusCode == 202 || resp.statusCode == 204) {
      return;
    }
    // kalau BE kirim pesan error, naikkan biar bisa ditampilkan
    final msg = (resp.body.isNotEmpty) ? resp.body : 'Gagal delete (status: ${resp.statusCode})';
    throw Exception(msg);
  }



  Future<BrokerPartialInfo> fetchPartialInfo({
    required String noBroker,
    required int noSak,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/labels/broker/partials/$noBroker/$noSak",
    );

    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode != 200) {
      throw Exception("Failed to fetch partial info (${resp.statusCode})");
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    return BrokerPartialInfo.fromEnvelope(body);
  }


}
