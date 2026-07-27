// lib/core/view_model/notification_center.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification_item.dart';

/// Titik agregasi tunggal untuk semua notifikasi yang tampil di bell app
/// shell. Sumber notifikasi (mis. `VerifikasiNotificationManager`) yang
/// tahu cara dapetin datanya sendiri (socket, bootstrap API, dll) — cukup
/// upsert/remove ke sini lewat [id] yang unik per notifikasi. UI bell cukup
/// dengar [NotificationCenter] ini tanpa perlu tahu dari domain mana
/// notifikasinya berasal, jadi menambah sumber notifikasi baru di masa
/// depan tidak perlu mengubah widget bell sama sekali.
class NotificationCenter extends ChangeNotifier {
  final Map<String, NotificationItem> _items = <String, NotificationItem>{};
  final StreamController<NotificationItem> _newItemController =
      StreamController<NotificationItem>.broadcast();

  /// Emit tiap kali ada [NotificationItem] yang benar-benar baru (id belum
  /// pernah ada sebelumnya) masuk lewat [upsert] non-silent — dipakai
  /// layer toast (`NotificationToastLayer`) untuk munculkan notif bar,
  /// terpisah dari [notifyListeners] biasa yang cuma buat rebuild badge/list.
  Stream<NotificationItem> get onNewItem => _newItemController.stream;

  /// Terurut terbaru dulu.
  List<NotificationItem> get items {
    final list = _items.values.toList();
    list.sort((a, b) {
      final ta = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return list;
  }

  int get count => _items.length;

  int countByType(String type) =>
      _items.values.where((n) => n.type == type).length;

  /// [silent] = true untuk upsert yang bukan "kejadian baru" secara UX
  /// (mis. bootstrap awal atau item yang sudah pernah dilihat sebelumnya)
  /// — badge/list tetap ke-update, tapi tidak memicu toast.
  void upsert(NotificationItem item, {bool silent = false}) {
    final isNew = !_items.containsKey(item.id);
    _items[item.id] = item;
    notifyListeners();
    if (isNew && !silent) _newItemController.add(item);
  }

  void remove(String id) {
    if (_items.remove(id) != null) notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _newItemController.close();
    super.dispose();
  }
}
