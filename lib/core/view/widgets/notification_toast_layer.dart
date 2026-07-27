// lib/core/view/widgets/notification_toast_layer.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_item.dart';
import '../../view_model/notification_center.dart';

/// Layer notif-bar (push-style) yang muncul di pojok kanan-atas tiap ada
/// [NotificationItem] baru masuk ke [NotificationCenter] (lewat
/// `NotificationCenter.onNewItem`). Murni UI reaktif terhadap stream —
/// tidak tahu dari domain mana notifikasi berasal, jadi sumber notifikasi
/// baru di masa depan otomatis ikut nongol di sini tanpa widget ini
/// disentuh.
///
/// Taruh sebagai child terakhir di dalam `Stack` yang membungkus konten app
/// shell, supaya tergambar paling atas (lihat pemakaiannya di `AppShell`).
class NotificationToastLayer extends StatefulWidget {
  /// Dipanggil saat toast di-tap — biasanya untuk navigasi ke [item.route].
  final void Function(NotificationItem item) onTapItem;

  const NotificationToastLayer({super.key, required this.onTapItem});

  @override
  State<NotificationToastLayer> createState() =>
      _NotificationToastLayerState();
}

class _NotificationToastLayerState extends State<NotificationToastLayer> {
  static const _maxStacked = 4;

  final List<_ToastEntry> _visible = [];
  StreamSubscription<NotificationItem>? _sub;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    final center = context.read<NotificationCenter>();
    _sub = center.onNewItem.listen(_push);
  }

  void _push(NotificationItem item) {
    if (!mounted) return;
    setState(() {
      _visible.insert(0, _ToastEntry(_seq++, item));
      while (_visible.length > _maxStacked) {
        _visible.removeLast();
      }
    });
  }

  void _dismiss(_ToastEntry entry) {
    if (!mounted) return;
    setState(() => _visible.removeWhere((e) => e.id == entry.id));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_visible.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in _visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ToastCard(
                key: ValueKey(entry.id),
                item: entry.item,
                onDismiss: () => _dismiss(entry),
                onTap: () {
                  _dismiss(entry);
                  widget.onTapItem(entry.item);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ToastEntry {
  final int id;
  final NotificationItem item;
  const _ToastEntry(this.id, this.item);
}

class _ToastCard extends StatefulWidget {
  final NotificationItem item;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _ToastCard({
    required super.key,
    required this.item,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0.25, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(seconds: 6), _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _controller,
        child: Material(
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _dismiss,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
