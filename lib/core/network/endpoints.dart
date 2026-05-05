import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get socketBaseUrl => dotenv.env['SOCKET_BASE_URL'] ?? '';
  static String get deviceApiUrl =>
      dotenv.env['DEVICE_API_URL'] ?? 'http://localhost:3000';

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/auth/login2';
  static String get checkLabel => '$baseUrl/api/label-list/check';
  static String get saveChanges => '$baseUrl/api/label-list/save-changes';
  static String get stockOpnameList => '$baseUrl/api/no-stock-opname';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get listNyangkut => '$baseUrl/api/nyangkut-list';
  static String get mstLokasi => '$baseUrl/api/mst-lokasi';
  static String get mstPrinter => '$baseUrl/api/mst-printer';
  static String get mstWashing => '$baseUrl/api/mst-washing';
  static String get mstBroker => '$baseUrl/api/mst-broker';

  static String scanLabel(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/scan';

  static String labelData(String noLabel) => '$baseUrl/api/label-data/$noLabel';

  static String labelSOList({
    required String selectedNoSO,
    required int page,
    required int pageSize,
    String? filterBy, // 'all' | 'bahanbaku' | dst
    String? blok, // ex: 'A' (nullable -> tidak dikirim jika null/'all'/'')
    int? idLokasi, // ex: 3  (nullable/0 -> tidak dikirim)
    String? search, // optional
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
    String? filterBy, // 'all' | 'bahanbaku' | dst
    String? blok, // ex: 'A' (nullable -> tidak dikirim jika null/'all'/'')
    int? idLokasi, // ex: 3  (nullable/0 -> tidak dikirim)
    String? search, // optional
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
  static String noStockOpnameAscendItems(
    String noSO,
    int familyID, {
    String keyword = '',
  }) =>
      '$baseUrl/api/no-stock-opname/$noSO/families/$familyID/ascend?keyword=$keyword';

  static Uri noStockOpnameUsage(int itemID, String tglSO, String wids) {
    // ✅ pastikan aman untuk URL (kalau ada spasi, dll)
    final safeTgl = Uri.encodeComponent(tglSO);
    final safeWids = Uri.encodeComponent(wids);

    final url = '$baseUrl/api/no-stock-opname/$itemID/usage/$safeTgl/$safeWids';
    return Uri.parse(url);
  }

  static String noStockOpnameSave(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/ascend/hasil';

  static String noStockOpnameDelete(String noSO, int itemID) =>
      '$baseUrl/api/no-stock-opname/$noSO/ascend/hasil/$itemID';

  // 🔹 No Stock Opname (Family)
  static String noStockOpnameFamilies(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/families';

  // 🔹 Label PDF endpoints (port 7500)
  static String washingLabelPdf(String noWashing) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noWashing);
    return 'http://$host:7500/api/labels/washing/$encoded/pdf/';
  }

  static String brokerLabelPdf(String noBroker) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noBroker);
    return 'http://$host:7500/api/labels/broker/$encoded/pdf/';
  }

  static String mixerLabelPdf(String noMixer) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noMixer);
    return 'http://$host:7500/api/labels/mixer/$encoded/pdf/';
  }

  static String bonggolanLabelPdf(String noBonggolan) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noBonggolan);
    return 'http://$host:7500/api/labels/bonggolan/$encoded/pdf/';
  }

  static String crusherLabelPdf(String noCrusher) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noCrusher);
    return 'http://$host:7500/api/labels/crusher/$encoded/pdf/';
  }

  static String gilinganLabelPdf(String noGilingan) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noGilingan);
    return 'http://$host:7500/api/labels/gilingan/$encoded/pdf/';
  }

  static String furnitureWipLabelPdf(String noFurnitureWip) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noFurnitureWip);
    return 'http://$host:7500/api/labels/furniture-wip/$encoded/pdf/';
  }

  static String rejectLabelPdf(String noReject) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noReject);
    return 'http://$host:7500/api/labels/reject/$encoded/pdf/';
  }

  static String packingLabelPdf(String noBJ) {
    final host = Uri.parse(baseUrl).host;
    final encoded = Uri.encodeComponent(noBJ);
    return 'http://$host:7500/api/labels/packing/$encoded/pdf/';
  }

  static String bahanBakuPalletLabelPdf(String noBahanBaku, String noPallet) {
    final host = Uri.parse(baseUrl).host;
    final encodedBB = Uri.encodeComponent(noBahanBaku);
    final encodedPallet = Uri.encodeComponent(noPallet);
    return 'http://$host:7500/api/labels/bahan-baku/$encodedBB/pallet/$encodedPallet/pdf/';
  }
}
