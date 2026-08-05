import '../utils/so_v2_number_format.dart';

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

  /// True kalau label ini discan di lokasi yang berbeda dari lokasi acuan
  /// sistem (Blok/IdLokasi) — lihat [scannedBlok]/[scannedLocationId] untuk
  /// lokasi aktual hasil scan.
  final bool isLocationMismatch;
  final String? scannedBlok;
  final int? scannedLocationId;
  final Map<String, dynamic> raw;

  static const _excludedKeys = {
    'NoSO',
    'isScanned',
    'IdJenisPlastik',
    'IdLokasi',
    'Blok',
    'IdBonggolan',
    'ScannedBlok',
    'ScannedIdLokasi',
    'isLocationMismatch',
  };

  SoV2LabelRow({
    required this.primaryKey,
    required this.primaryValue,
    required this.isScanned,
    this.isLocationMismatch = false,
    this.scannedBlok,
    this.scannedLocationId,
    required this.raw,
  });

  factory SoV2LabelRow.fromJson(Map<String, dynamic> json) {
    final scannedValue = json['isScanned'];
    final isScanned = scannedValue == 1 || scannedValue == true;
    final mismatchValue = json['isLocationMismatch'];
    final isLocationMismatch = mismatchValue == 1 || mismatchValue == true;
    final scannedBlok = json['ScannedBlok']?.toString();
    final scannedLocationIdRaw = json['ScannedIdLokasi'];
    final scannedLocationId = scannedLocationIdRaw is num
        ? scannedLocationIdRaw.toInt()
        : int.tryParse('$scannedLocationIdRaw');

    // Kategori bahan baku punya NoBahanBaku dan NoPallet sebagai field
    // terpisah, tapi label fisiknya adalah gabungan keduanya.
    if (json.containsKey('NoBahanBaku') && json.containsKey('NoPallet')) {
      final noBahanBaku = json['NoBahanBaku']?.toString() ?? '';
      final noPallet = json['NoPallet']?.toString() ?? '';
      return SoV2LabelRow(
        primaryKey: 'NoBahanBaku',
        primaryValue: '$noBahanBaku-$noPallet',
        isScanned: isScanned,
        isLocationMismatch: isLocationMismatch,
        scannedBlok: scannedBlok,
        scannedLocationId: scannedLocationId,
        raw: json,
      );
    }

    final entry = json.entries.firstWhere(
      (e) => !_excludedKeys.contains(e.key),
      orElse: () => json.entries.first,
    );
    return SoV2LabelRow(
      primaryKey: entry.key,
      primaryValue: entry.value?.toString() ?? '',
      isScanned: isScanned,
      isLocationMismatch: isLocationMismatch,
      scannedBlok: scannedBlok,
      scannedLocationId: scannedLocationId,
      raw: json,
    );
  }

  /// Entries selain field judul (primaryKey) dan field yang dikecualikan
  /// (NoSO, isScanned), untuk ditampilkan sebagai info tambahan.
  Iterable<MapEntry<String, dynamic>> get secondaryEntries => raw.entries.where(
    (e) =>
        e.key != primaryKey &&
        !_excludedKeys.contains(e.key) &&
        !(primaryKey == 'NoBahanBaku' && e.key == 'NoPallet'),
  );

  static const _weightKeyHints = ['berat'];
  static const _countKeyHints = ['jmlh', 'pcs', 'qty'];

  /// Nilai berat atau jumlah pcs/sak untuk ditampilkan di sisi kanan baris,
  /// mis. "225 kg" atau "14 pcs". Mencari field yang namanya mengandung
  /// "Berat" (prioritas, satuan [weightUnit], default kg — beberapa
  /// kategori seperti furniturewip memakai UOM pcs meski nama field-nya
  /// tetap "Berat") lalu field "Jmlh"/"Pcs"/"Qty" (satuan pcs). Null kalau
  /// tidak ada field yang cocok.
  String? weightOrCountDisplay({String weightUnit = 'kg'}) {
    for (final e in secondaryEntries) {
      if (e.value == null) continue;
      final key = e.key.toLowerCase();
      if (_weightKeyHints.any(key.contains)) {
        return '${_formatValue(e.value)} $weightUnit';
      }
    }
    for (final e in secondaryEntries) {
      if (e.value == null) continue;
      final key = e.key.toLowerCase();
      if (_countKeyHints.any(key.contains)) {
        return '${_formatValue(e.value)} pcs';
      }
    }
    return null;
  }

  static String _formatValue(dynamic value) =>
      value is num ? soV2FormatQty(value) : value.toString();

  SoV2LabelRow markScanned({
    bool isLocationMismatch = false,
    String? scannedBlok,
    int? scannedLocationId,
  }) {
    if (isScanned) return this;
    return SoV2LabelRow(
      primaryKey: primaryKey,
      primaryValue: primaryValue,
      isScanned: true,
      isLocationMismatch: isLocationMismatch,
      scannedBlok: scannedBlok,
      scannedLocationId: scannedLocationId,
      raw: raw,
    );
  }

  /// Kebalikan dari [markScanned] — dipakai setelah hasil scan dihapus
  /// (mis. untuk perbaiki label yang salah lokasi lalu discan ulang).
  SoV2LabelRow unmarkScanned() {
    if (!isScanned) return this;
    return SoV2LabelRow(
      primaryKey: primaryKey,
      primaryValue: primaryValue,
      isScanned: false,
      raw: raw,
    );
  }
}
