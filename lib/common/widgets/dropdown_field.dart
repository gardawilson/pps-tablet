import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class DropdownPlainField<T> extends StatefulWidget {
  // data
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? itemAsString;

  // UX & form
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(T?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;

  // state
  final bool isLoading;
  final bool fetchError;
  final String? fetchErrorText;
  final VoidCallback? onRetry;
  final String? errorText; // override error

  // style
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  // compare (opsional)
  final bool Function(T, T)? compareFn;

  const DropdownPlainField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.itemAsString,
    this.label = '',
    this.hint = 'PILIH',
    this.prefixIcon,
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.isLoading = false,
    this.fetchError = false,
    this.fetchErrorText,
    this.onRetry,
    this.errorText,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    this.compareFn,
  });

  @override
  State<DropdownPlainField<T>> createState() => _DropdownPlainFieldState<T>();
}

class _DropdownPlainFieldState<T> extends State<DropdownPlainField<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _rot = CurvedAnimation(parent: _anim, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 0.5));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (widget.isLoading) {
      return _decorated(
        context,
        child: SizedBox(height: widget.fieldHeight, child: _loadingRow()),
      );
    }

    // Fetch error state
    if (widget.fetchError) {
      return _decorated(
        context,
        errorText: widget.fetchErrorText ?? 'Gagal mengambil data',
        child: SizedBox(height: widget.fieldHeight, child: _fetchErrorRow(context)),
      );
    }

    // Normal state
    return FormField<T>(
      key: ValueKey(widget.value), // ✅ sinkron bila value berubah dari parent
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      initialValue: widget.value,  // hanya utk validator, tampilan pakai widget.value
      builder: (field) {
        final mergedError = widget.errorText ?? field.errorText;

        return _decorated(
          context,
          errorText: mergedError,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: SizedBox(
              height: widget.fieldHeight, // kunci tinggi agar seragam
              child: DropdownSearch<T>(
                items: widget.items,
                selectedItem: widget.value, // ✅ kunci tampilan ke nilai dari parent
                enabled: widget.enabled,
                itemAsString: widget.itemAsString,
                compareFn: widget.compareFn,

                // Patuh ke InputDecorator luar: hilangkan dekorasi internal
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                // Tampilan teks pada field
                dropdownBuilder: (context, selectedItem) {
                  final String text = (selectedItem == null)
                      ? widget.hint
                      : (widget.itemAsString?.call(selectedItem) ?? '$selectedItem');
                  final Color color =
                  (selectedItem == null) ? Colors.grey.shade600 : Colors.black87;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                  );
                },

                // Ikon panah + animasi rotasi
                dropdownButtonProps: DropdownButtonProps(
                  icon: AnimatedBuilder(
                    animation: _rot,
                    builder: (_, __) => Transform.rotate(
                      angle: _rot.value * 3.14159,
                      child: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600, size: 24),
                    ),
                  ),
                  alignment: Alignment.center,
                ),

                // Popup list tanpa search — gaya identik dengan SearchDropdownField
                popupProps: PopupProps.menu(
                  showSearchBox: false,
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: widget.popupMaxHeight),
                  onDismissed: () {
                    if (mounted) _anim.reverse();
                  },
                  menuProps: MenuProps(
                    backgroundColor: Colors.white,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context, item, isSelected) =>
                      _buildPopupItem(context, item, isSelected),
                ),

                onBeforePopupOpening: (selected) async {
                  _anim.forward();
                  return true;
                },

                onChanged: (val) {
                  field.didChange(val);        // agar validator aware
                  widget.onChanged?.call(val); // lempar ke parent
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// ===== InputDecorator wrapper =====
  Widget _decorated(BuildContext context, {required Widget child, String? errorText}) {
    return InputDecorator(
      isFocused: false,
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        helperText: widget.helperText,
        errorText: errorText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 22) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabled: widget.enabled,
        isDense: true,
        contentPadding: widget.contentPadding, // horizontal 16, vertical 0
      ),
      child: child,
    );
  }

  Widget _loadingRow() => Row(
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Text('Memuat...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
    ],
  );

  Widget _fetchErrorRow(BuildContext context) => Row(
    children: [
      Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          widget.fetchErrorText ?? 'Gagal mengambil data',
          style: TextStyle(fontSize: 16, color: Colors.red.shade700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (widget.onRetry != null) ...[
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Coba lagi'),
        ),
      ],
    ],
  );

  Widget _buildPopupItem(BuildContext context, T item, bool isSelected) {
    final text = widget.itemAsString?.call(item) ?? '$item';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? Colors.blue.shade700 : Colors.black87,
        ),
      ),
    );
  }
}
