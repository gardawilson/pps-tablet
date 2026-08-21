// lib/features/production/penerimaan_bahan_baku/model/penerimaan_kategori.dart
//
// Dua kategori penerimaan bahan baku yang didukung, berdasarkan
// dbo.MstKategori (endpoint GET /api/master-kategori di backend):
//   KodeKategori "bahanbaku"      → NamaKategori "Bahan Baku"       → PrefixLabel "A."
//   KodeKategori "bahanbakupakai" → NamaKategori "Bahan Baku Pakai" → PrefixLabel "AB."
// "bahanbaku" (generik) adalah alur "Proses" — bahan baku yang akan melalui
// proses produksi lanjutan — sedangkan "bahanbakupakai" adalah alur "Pakai"
// — bahan baku yang langsung dipakai. Prefix label itu sendiri di-resolve
// dinamis oleh backend dari MstKategori, bukan di-hardcode di sini — nilai
// yang dikirim ke server hanyalah [kodeKategori].
class PenerimaanKategori {
  final String kodeKategori;
  final String title;

  /// PrefixLabel dari dbo.MstKategori untuk [kodeKategori] ini — dipakai
  /// untuk memfilter GET /api/labels/bahan-baku?prefix=. Nilai statis di
  /// sini hanya untuk keperluan filter tampilan; endpoint create
  /// (/api/penerimaan-bahan-baku) tetap resolve prefix secara dinamis dari
  /// MstKategori di backend, bukan dari nilai ini.
  final String prefixLabel;

  const PenerimaanKategori({
    required this.kodeKategori,
    required this.title,
    required this.prefixLabel,
  });

  static const proses = PenerimaanKategori(
    kodeKategori: 'bahanbaku',
    title: 'Penerimaan Bahan Baku Proses',
    prefixLabel: 'A.',
  );

  static const pakai = PenerimaanKategori(
    kodeKategori: 'bahanbakupakai',
    title: 'Penerimaan Bahan Baku Pakai',
    prefixLabel: 'AB.',
  );

  /// Tebak kategori dari prefix sebuah NoBahanBaku (mis. "AB.0000000001" →
  /// [pakai], "A.0000000001" → [proses]) — dipakai di layar detail untuk
  /// memberi label per-batch tanpa perlu backend mengirim KodeKategori
  /// sebagai kolom tersendiri (lihat komentar di
  /// `PenerimaanBahanBakuRepository`: kategori 1:1 dengan prefix NoBahanBaku).
  static PenerimaanKategori? fromNoBahanBaku(String? noBahanBaku) {
    final code = noBahanBaku?.trim() ?? '';
    if (code.isEmpty) return null;
    if (code.startsWith(pakai.prefixLabel)) return pakai;
    if (code.startsWith(proses.prefixLabel)) return proses;
    return null;
  }
}
