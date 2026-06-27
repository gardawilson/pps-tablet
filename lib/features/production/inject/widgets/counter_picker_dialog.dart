import 'package:flutter/material.dart';

const _kCounterAccent = Color(0xFF0277BD);

class CounterPickerDialog extends StatefulWidget {
  const CounterPickerDialog({
    super.key,
    required this.initialValue,
    this.accentColor = _kCounterAccent,
    this.minValue,
  });
  final int initialValue;
  final Color accentColor;
  final int? minValue;

  @override
  State<CounterPickerDialog> createState() => _CounterPickerDialogState();
}

class _CounterPickerDialogState extends State<CounterPickerDialog> {
  static const int _max = 999999;
  late final FixedExtentScrollController _scrollCtrl;
  late int _selected;

  int get _min => widget.minValue ?? 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue.clamp(_min, _max);
    _scrollCtrl = FixedExtentScrollController(initialItem: _selected - _min);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (_selected + delta).clamp(_min, _max);
    if (next == _selected) return;
    setState(() => _selected = next);
    _scrollCtrl.animateToItem(
      next - _min,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.speed_outlined, size: 16, color: accent),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Counter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (widget.minValue != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Odometer saat ini: ${widget.minValue} · Tidak bisa kurang',
                    style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.30)),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _scrollCtrl,
                      itemExtent: 44,
                      perspective: 0.003,
                      diameterRatio: 2.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setState(() => _selected = _min + i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _max - _min + 1,
                        builder: (context, index) {
                          final value = _min + index;
                          final isSelected = value == _selected;
                          return Center(
                            child: Text(
                              '$value',
                              style: TextStyle(
                                fontSize: isSelected ? 26 : 18,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                                color: isSelected ? accent : const Color(0xFF9CA3AF),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CounterStepBtn(
                    icon: Icons.remove,
                    accentColor: accent,
                    onTap: () => _step(-1),
                    onLongPress: () => _step(-10),
                    disabled: _selected <= _min,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$_selected',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1),
                    ),
                  ),
                  CounterStepBtn(icon: Icons.add, accentColor: accent, onTap: () => _step(1), onLongPress: () => _step(10)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Konfirmasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CounterStepBtn extends StatelessWidget {
  const CounterStepBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.accentColor = _kCounterAccent,
    this.onLongPress,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color accentColor;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      onLongPress: disabled ? null : onLongPress,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF3F4F6)
              : accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? const Color(0xFFE5E7EB)
                : accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled ? const Color(0xFFD1D5DB) : accentColor,
        ),
      ),
    );
  }
}
