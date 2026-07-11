/// Baris label pada 1 jenis stock opname.
///
/// Nama field mentah berbeda-beda per kategori (NoBroker, NoWashing,
/// NoBahanBaku+NoPallet, dst). Field pertama tiap object JSON selalu
/// "NoSO" (nomor stock opname, sama untuk semua baris, redundant untuk
/// ditampilkan) — field nomor label utama adalah field pertama SETELAH
/// NoSO, jadi ditangani generik lewat [raw] tanpa model bertipe per
/// kategori.
class SoV2LabelRow {
  final String primaryKey;
  final String primaryValue;
  final bool isScanned;
  final Map<String, dynamic> raw;

  static const _excludedKeys = {
    'NoSO',
    'isScanned',
    'IdJenisPlastik',
    'IdLokasi',
    'Blok',
    'IdBonggolan',
  };

  SoV2LabelRow({
    required this.primaryKey,
    required this.primaryValue,
    required this.isScanned,
    required this.raw,
  });

  factory SoV2LabelRow.fromJson(Map<String, dynamic> json) {
    final entry = json.entries.firstWhere(
      (e) => !_excludedKeys.contains(e.key),
      orElse: () => json.entries.first,
    );
    final scannedValue = json['isScanned'];
    return SoV2LabelRow(
      primaryKey: entry.key,
      primaryValue: entry.value?.toString() ?? '',
      isScanned: scannedValue == 1 || scannedValue == true,
      raw: json,
    );
  }

  /// Entries selain field judul (primaryKey) dan field yang dikecualikan
  /// (NoSO, isScanned), untuk ditampilkan sebagai info tambahan.
  Iterable<MapEntry<String, dynamic>> get secondaryEntries => raw.entries
      .where((e) => e.key != primaryKey && !_excludedKeys.contains(e.key));

  static const _weightKeyHints = ['berat'];
  static const _countKeyHints = ['jmlh', 'pcs', 'qty'];

  /// Nilai berat atau jumlah pcs/sak untuk ditampilkan di sisi kanan baris,
  /// mis. "225 kg" atau "14 pcs". Mencari field yang namanya mengandung
  /// "Berat" (prioritas, satuan kg) lalu field "Jmlh"/"Pcs"/"Qty" (satuan
  /// pcs). Null kalau tidak ada field yang cocok.
  String? get weightOrCountDisplay {
    for (final e in secondaryEntries) {
      if (e.value == null) continue;
      final key = e.key.toLowerCase();
      if (_weightKeyHints.any(key.contains)) return '${e.value} kg';
    }
    for (final e in secondaryEntries) {
      if (e.value == null) continue;
      final key = e.key.toLowerCase();
      if (_countKeyHints.any(key.contains)) return '${e.value} pcs';
    }
    return null;
  }
}
