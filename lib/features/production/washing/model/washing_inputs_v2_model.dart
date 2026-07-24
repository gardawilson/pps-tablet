// lib/features/production/washing/model/washing_inputs_v2_model.dart
//
// GET /api/production/washing/:noProduksi/inputs/v2
// GET /api/production/washing/:noProduksi/outputs/v2
//
// Kedua endpoint ini format-nya selaras — dikelompokkan per kategori sumber
// (washing/bb/gilingan) dengan header per label (NoWashing/NoBahanBaku/
// NoGilingan) dan DetailSak bersarang — dipakai untuk cross-check
// verifikasi supaya format input & output konsisten (per label, per
// jenis material).

class WashingInputV2Label {
  final String labelNo;
  final String namaJenis;
  final int totalSak;
  final double totalBerat;

  const WashingInputV2Label({
    required this.labelNo,
    required this.namaJenis,
    required this.totalSak,
    required this.totalBerat,
  });
}

double _sumBeratV2(List<dynamic> detailSak) {
  return detailSak.fold(0.0, (sum, d) {
    final m = Map<String, dynamic>.from(d as Map);
    final berat = m['Berat'];
    final v = berat is num ? berat.toDouble() : double.tryParse('$berat') ?? 0.0;
    return sum + v;
  });
}

String? _strV2(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

List<WashingInputV2Label> _parseCategoryV2(
  dynamic raw, {
  required String Function(Map<String, dynamic> header) labelNoOf,
}) {
  final list = (raw as List?) ?? const [];
  return list.map((e) {
    final m = Map<String, dynamic>.from(e as Map);
    final namaJenis = _strV2(m['NamaJenis']) ?? '-';
    final detailSak = (m['DetailSak'] as List?) ?? const [];
    return WashingInputV2Label(
      labelNo: labelNoOf(m),
      namaJenis: namaJenis,
      totalSak: detailSak.length,
      totalBerat: _sumBeratV2(detailSak),
    );
  }).toList();
}

/// Resolusi nomor label per kategori — konsisten dipakai untuk input & output.
String _labelNoForCategory(String category, Map<String, dynamic> h) {
  switch (category) {
    case 'bb':
      final pallet = _strV2(h['NoPallet']);
      final base = _strV2(h['NoBahanBaku']) ?? '-';
      return pallet == null ? base : '$base-$pallet';
    case 'gilingan':
      return _strV2(h['NoGilingan']) ?? '-';
    case 'washing':
    default:
      return _strV2(h['NoWashing']) ??
          _strV2(h['NoBahanBaku']) ??
          _strV2(h['NoGilingan']) ??
          '-';
  }
}

class WashingInputsV2 {
  final List<WashingInputV2Label> washing;
  final List<WashingInputV2Label> bb;
  final List<WashingInputV2Label> gilingan;

  const WashingInputsV2({
    required this.washing,
    required this.bb,
    required this.gilingan,
  });

  factory WashingInputsV2.fromJson(Map<String, dynamic> j) {
    return WashingInputsV2(
      washing: _parseCategoryV2(
        j['washing'],
        labelNoOf: (h) => _labelNoForCategory('washing', h),
      ),
      bb: _parseCategoryV2(
        j['bb'],
        labelNoOf: (h) => _labelNoForCategory('bb', h),
      ),
      gilingan: _parseCategoryV2(
        j['gilingan'],
        labelNoOf: (h) => _labelNoForCategory('gilingan', h),
      ),
    );
  }

  double get totalBerat =>
      [...washing, ...bb, ...gilingan].fold(0.0, (s, g) => s + g.totalBerat);
}

/// GET /api/production/washing/:noProduksi/outputs/v2 — dibungkus per
/// kategori sumber sama seperti inputs/v2. Untuk washing biasanya cuma ada
/// key "washing", tapi diparsing generik per kategori yang ada di response
/// supaya tetap benar kalau backend menambah kategori lain di kemudian hari.
class WashingOutputsV2 {
  final Map<String, List<WashingInputV2Label>> categories;

  const WashingOutputsV2({required this.categories});

  factory WashingOutputsV2.fromJson(Map<String, dynamic> j) {
    final categories = <String, List<WashingInputV2Label>>{};
    for (final entry in j.entries) {
      categories[entry.key] = _parseCategoryV2(
        entry.value,
        labelNoOf: (h) => _labelNoForCategory(entry.key, h),
      );
    }
    return WashingOutputsV2(categories: categories);
  }

  List<WashingInputV2Label> get washing => categories['washing'] ?? const [];

  double get totalBerat => categories.values
      .expand((list) => list)
      .fold(0.0, (s, g) => s + g.totalBerat);
}
