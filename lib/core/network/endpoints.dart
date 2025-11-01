import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get socketBaseUrl => dotenv.env['SOCKET_BASE_URL'] ?? '';


  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/auth/login';
  static String get checkLabel => '$baseUrl/api/label-list/check';
  static String get saveChanges => '$baseUrl/api/label-list/save-changes';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get listNyangkut => '$baseUrl/api/nyangkut-list';
  static String get mstLokasi => '$baseUrl/api/mst-lokasi';

  static String scanLabel(String noSO) => '$baseUrl/api/no-stock-opname/$noSO/scan';

  static String labelData(String noLabel) => '$baseUrl/api/label-data/$noLabel';


  static String labelSOList({
    required String selectedNoSO,
    required int page,
    required int pageSize,
    String? filterBy,     // 'all' | 'bahanbaku' | dst
    String? blok,         // ex: 'A' (nullable -> tidak dikirim jika null/'all'/'')
    int? idLokasi,        // ex: 3  (nullable/0 -> tidak dikirim)
    String? search,       // optional
  }) {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'filterBy': filterBy ?? 'all',
      // kalau kamu butuh: 'filterbyuser': 'false',
    };

    // kirim blok hanya jika bermakna
    if (blok != null && blok.isNotEmpty && blok.toLowerCase() != 'all') {
      qp['blok'] = blok;
    }

    // kirim idLokasi hanya jika ada dan bukan 0
    if (idLokasi != null && idLokasi != 0) {
      qp['idLokasi'] = idLokasi.toString(); // <-- penting: toString()
    }

    if (search != null && search.isNotEmpty) {
      qp['search'] = search; // Uri(queryParameters: ...) akan auto-encode
    }

    final query = Uri(queryParameters: qp).query;
    return '$baseUrl/api/no-stock-opname/$selectedNoSO/hasil?$query';
  }


  static String stockOpnameAcuanList({
    required String noSO,
    required int page,
    required int pageSize,
    String? filterBy,          // 'all' | 'bahanbaku' | dst
    String? blok,              // ex: 'A' (nullable -> tidak dikirim jika null/'all'/'')
    int? idLokasi,             // ex: 3  (nullable/0 -> tidak dikirim)
    String? search,            // optional
  }) {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'filterBy': filterBy ?? 'all',
      // kalau kamu ingin dukungan filter by user, tetap bisa tambahkan di sini:
      // 'filterbyuser': 'false',
    };

    // sertakan blok hanya jika ada nilai yang bermakna
    if (blok != null && blok.isNotEmpty && blok.toLowerCase() != 'all') {
      qp['blok'] = blok;
    }

    // sertakan idLokasi hanya jika ada dan bukan 0
    if (idLokasi != null && idLokasi != 0) {
      qp['idLokasi'] = idLokasi.toString();
    }

    // search opsional
    if (search != null && search.isNotEmpty) {
      qp['search'] = search; // Uri(queryParameters) akan meng-encode
    }

    final query = Uri(queryParameters: qp).query;
    return '$baseUrl/api/no-stock-opname/$noSO/acuan?$query';
  }

  static String labelList({
    required int page,
    required int pageSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$pageSize&filterBy=$filter&idlokasi=$lokasi';
  }

  static String labelListLoadMore({
    required int page,
    required int loadMoreSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final currentFilter = filterBy ?? 'all';
    final currentLocation = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$loadMoreSize&filterBy=$currentFilter&idlokasi=$currentLocation';
  }


  // 🔹 No Stock Opname (Ascend)
  static String noStockOpnameAscendItems(String noSO, int familyID, {String keyword = ''}) =>
      '$baseUrl/api/no-stock-opname/$noSO/families/$familyID/ascend?keyword=$keyword';

  static String noStockOpnameUsage(int itemID, String tglSO) =>
      '$baseUrl/api/no-stock-opname/$itemID/usage?tglSO=$tglSO';

  static String noStockOpnameSave(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/ascend/hasil';

  static String noStockOpnameDelete(String noSO, int itemID) =>
      '$baseUrl/api/no-stock-opname/$noSO/ascend/hasil/$itemID';

  // 🔹 No Stock Opname (Family)
  static String noStockOpnameFamilies(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/families';

}
