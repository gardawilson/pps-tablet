// lib/features/verifikasi/view/verifikasi_theme.dart
//
// Palet & token warna disamakan persis dengan SoV2DetailScreen
// (lib/features/stock_opname_v2/view/so_v2_detail_screen.dart) supaya
// modul Verifikasi terasa satu keluarga dengan layar enterprise lain.

import 'package:flutter/material.dart';

const kVerifikasiSurface = Color(0xFFF8F9FB);
const kVerifikasiInk = Color(0xFF1A1D23); // teks emphasis
const kVerifikasiAccent = Color(0xFF1E6FD9); // aksen/selected state
const kVerifikasiBorder = Color(0xFFE2E6EA);
const kVerifikasiMuted = Color(0xFF6B7280);
const kVerifikasiWarning = Color(0xFFB45309);
const kVerifikasiWarningBg = Color(0xFFFFF7ED);
const kVerifikasiSuccess = Color(0xFF0A7349);
const kVerifikasiSuccessBg = Color(0xFFE8F5EE);

/// Warna badge per jenis produksi, dipakai supaya baris list yang sudah
/// digabung (semua jenis dalam satu list) tetap bisa dibedakan sekilas.
const Map<String, Color> _kJenisColors = {
  'washing': Color(0xFF1E6FD9),
  'broker': Color(0xFF7C3AED),
  'gilingan': Color(0xFF0A7349),
  'inject': Color(0xFFB45309),
};

/// Palet cadangan untuk jenis produksi baru yang belum masuk [_kJenisColors]
/// — dipilih berdasar urutan pada [knownKeys] supaya tetap stabil.
const List<Color> _kJenisColorFallback = [
  Color(0xFF1E6FD9),
  Color(0xFF7C3AED),
  Color(0xFF0A7349),
  Color(0xFFB45309),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
];

Color jenisColor(String jenisKey, List<String> knownKeys) {
  final mapped = _kJenisColors[jenisKey];
  if (mapped != null) return mapped;
  final index = knownKeys.indexOf(jenisKey);
  if (index < 0) return kVerifikasiAccent;
  return _kJenisColorFallback[index % _kJenisColorFallback.length];
}
