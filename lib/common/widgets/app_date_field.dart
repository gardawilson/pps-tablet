import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable date picker field styled like DropdownPlainField
/// (single-height row, InputDecorator, no trailing icons).
class AppDateField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData leadingIcon;
  final DateFormat format;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate; // kalau controller kosong, pakai ini
  final Locale? locale;        // contoh: const Locale('id','ID')
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DateTime?>? onChanged; // callback setelah pilih

  // constructor & defaults unchanged
  AppDateField({
    super.key,
    required this.controller,
    this.label = 'Date',
    this.hintText,
    this.leadingIcon = Icons.date_range,
    DateFormat? format,
    DateTime? firstDate,
    DateTime? lastDate,
    this.initialDate,
    this.locale,
    this.enabled = true,
    this.validator,
    this.onChanged,
  })  : format = format ?? DateFormat('yyyy-MM-dd'),
        firstDate = firstDate ?? DateTime(2000, 1, 1),
        lastDate  = lastDate  ?? DateTime(2100, 12, 31);

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  static const double _fieldHeight = 40;
  static const EdgeInsets _contentPadding =
  EdgeInsets.symmetric(horizontal: 16, vertical: 0);

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtlChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtlChanged);
    super.dispose();
  }

  void _onCtlChanged() {
    if (mounted) setState(() {}); // refresh text style when content changes
  }

  DateTime _parseCurrentOr(DateTime fallback) {
    final txt = widget.controller.text.trim();
    if (txt.isEmpty) return fallback;
    try {
      return widget.format.parseStrict(txt);
    } catch (_) {
      try {
        return DateTime.parse(txt);
      } catch (_) {
        return fallback;
      }
    }
  }

  Future<DateTime?> _showDatePicker(BuildContext context, DateTime initial) {
    if (widget.locale == null) {
      return showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        helpText: 'Pilih tanggal',
      );
    }

    // Override locale hanya untuk picker ini
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      helpText: 'Pilih tanggal',
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: widget.locale,
        child: child,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.enabled) return;

    final init0 = widget.initialDate ?? _parseCurrentOr(DateTime.now());
    final init = (init0.isBefore(widget.firstDate) || init0.isAfter(widget.lastDate))
        ? widget.firstDate
        : init0;

    final picked = await _showDatePicker(context, init);
    if (picked != null) {
      widget.controller.text = widget.format.format(picked);
      widget.onChanged?.call(picked);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey(widget.controller.text),
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: widget.controller.text,
      builder: (field) {
        final mergedError = field.errorText;

        return InputDecorator(
          isFocused: false,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText ?? widget.format.pattern,
            prefixIcon: Icon(widget.leadingIcon, size: 22),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabled: widget.enabled,
            isDense: true,
            contentPadding: _contentPadding,
            errorText: mergedError,
          ),
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: SizedBox(
              height: _fieldHeight,
              child: InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _hasText ? widget.controller.text : (widget.hintText ?? 'PILIH TANGGAL'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: _hasText ? Colors.black87 : Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
