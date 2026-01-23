// lib/features/production/bahan_baku/widgets/bahan_baku_action_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';

class BahanBakuActionBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const BahanBakuActionBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  State<BahanBakuActionBar> createState() => _BahanBakuActionBarState();
}

class _BahanBakuActionBarState extends State<BahanBakuActionBar> {
  final FocusNode _searchFocus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() => _focused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
            _searchFocus.requestFocus();
          },
        },
        child: Focus(
          autofocus: false,
          child: LayoutBuilder(
            builder: (context, c) {
              final isTight = c.maxWidth < 660;
              return Row(
                children: [
                  // 🔍 Search box (full width karena tidak ada tombol Buat Label)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focused
                              ? cs.primary.withOpacity(.5)
                              : Colors.grey.shade300,
                          width: _focused ? 1.6 : 1,
                        ),
                        boxShadow: _focused
                            ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Icon(Icons.search, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              focusNode: _searchFocus,
                              controller: widget.controller,
                              onChanged: (v) {
                                setState(() {}); // trigger ikon clear
                                widget.onSearchChanged(v);
                              },
                              onSubmitted: widget.onSearchChanged,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText:
                                'Cari No Bahan Baku / Supplier / No Plat…',
                                hintStyle:
                                TextStyle(color: Colors.grey.shade500),
                                isCollapsed: true,
                                border: InputBorder.none,
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          // Tombol clear di dalam field
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: _hasText
                                ? IconButton(
                              key: const ValueKey('clear_on'),
                              tooltip: 'Bersihkan',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                widget.controller.clear();
                                setState(() {});
                                widget.onClear();
                                _searchFocus.requestFocus();
                              },
                            )
                                : const SizedBox.shrink(
                                key: ValueKey('clear_off')),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!isTight) const SizedBox(width: 8),

                  // 🔁 Tombol reset eksternal (layout sempit)
                  if (isTight)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Reset pencarian',
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {});
                        widget.onClear();
                      },
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}