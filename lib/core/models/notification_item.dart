// lib/core/models/notification_item.dart
import 'package:flutter/material.dart';

/// Satu notifikasi generik yang tampil di bell notifikasi app shell.
/// Sumbernya bisa macam-macam (verifikasi produksi selesai, dan nanti bisa
/// ditambah jenis lain) — semua dinormalisasi ke bentuk ini supaya UI bell
/// tidak perlu tahu domain masing-masing sumber, cuma baca [NotificationCenter].
@immutable
class NotificationItem {
  /// Unique key untuk dedupe & remove, mis. 'verifikasi:broker:E.0000006052'.
  /// Konvensi: `type:detail-spesifik-sumber`.
  final String id;

  /// Kategori sumber notifikasi, mis. 'verifikasi'. Dipakai untuk filter /
  /// styling ringan, bukan untuk navigasi (navigasi lewat [route]).
  final String type;

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Waktu kejadian (bukan waktu dibuat notifikasi ini di client) — dipakai
  /// buat urutan terbaru dulu & label waktu relatif.
  final DateTime? time;

  /// Route yang dibuka saat notifikasi ini di-tap.
  final String route;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.time,
  });
}
