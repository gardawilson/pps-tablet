import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

/// Searchable dropdown berbasis `dropdown_search`
/// - Tinggi field DIKUNCI via `fieldHeight`
/// - Semua label/helper/error/border via InputDecorator (rapi & konsisten)
/// - Validator via FormField<T>
/// - State: loading, fetchError (+onRetry)
/// - Panah dropdown beranimasi saat popup buka/tutup
class SearchDropdownField<T> extends StatefulWidget {
  // data
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? itemAsString;

  // UX
  final String label; // label di InputDecorator
  final String hint; // placeholder saat belum ada pilihan
  final IconData? prefixIcon; // ikon kecil di kiri (opsional)
  final bool enabled;
  final bool isExpanded;

  /// Tinggi field agar seragam (samakan dg DropdownField-mu)
  final double fieldHeight;

  // search popup
  final bool showSearchBox;
  final String searchHint;
  final double popupMaxHeight;
  final bool useDialogPopup;
  final String? dialogTitle;

  // validasi form
  final String? Function(T?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;

  // error eksternal & fetch error
  final String? errorText; // error dari luar (mis. dari VM)
  final bool fetchError;
  final String? fetchErrorText;
  final VoidCallback? onRetry;

  // loading state
  final bool isLoading;

  // compare / filter custom
  final bool Function(T, T)? compareFn;
  final bool Function(T, String)? filterFn;

  /// Samakan padding horizontal dengan DropdownField bawaanmu.
  /// Vertical dibuat 0 karena tinggi dikontrol oleh `fieldHeight`.
  final EdgeInsetsGeometry contentPadding;

  const SearchDropdownField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.itemAsString,
    this.label = '',
    this.hint = 'Pilih item',
    this.prefixIcon,
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40, // tinggi standar
    this.showSearchBox = true,
    this.searchHint = 'Cari...',
    this.popupMaxHeight = 500,
    this.useDialogPopup = false,
    this.dialogTitle,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.fetchError = false,
    this.fetchErrorText,
    this.onRetry,
    this.isLoading = false,
    this.compareFn,
    this.filterFn,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 0,
    ),
  });

  @override
  State<SearchDropdownField<T>> createState() => _SearchDropdownFieldState<T>();
}

class _SearchDropdownFieldState<T> extends State<SearchDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _rotationAnim;
  final ScrollController _listScrollCtrl = ScrollController();

  static const double _itemExtent = 49.0; // tinggi tiap item (padding 14*2 + text ~21)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _listScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (widget.value == null || widget.items.isEmpty) return;
    final idx = widget.items.indexWhere((e) {
      if (widget.compareFn != null) return widget.compareFn!(e, widget.value as T);
      return e == widget.value;
    });
    if (idx < 0) return;
    final offset = idx * _itemExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollCtrl.hasClients) {
        _listScrollCtrl.jumpTo(
          offset.clamp(0.0, _listScrollCtrl.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (widget.isLoading) {
      return _decorated(
        context,
        child: SizedBox(height: widget.fieldHeight, child: _loadingRow()),
      );
    }

    // Fetch error
    if (widget.fetchError) {
      return _decorated(
        context,
        errorText: widget.fetchErrorText ?? 'Gagal mengambil data',
        child: SizedBox(
          height: widget.fieldHeight,
          child: _fetchErrorRow(context),
        ),
      );
    }

    // Normal
    return FormField<T>(
      key: ValueKey(widget.value), // ✅ sinkron saat value berubah dari parent
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      initialValue: widget.value, // hanya utk validator; UI pakai widgets.value
      builder: (field) {
        final mergedError = widget.errorText ?? field.errorText;

        return _decorated(
          context,
          errorText: mergedError,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: SizedBox(
              height: widget.fieldHeight, // kunci tinggi
              child: DropdownSearch<T>(
                items: widget.items,
                selectedItem: widget.value, // ✅ pakai nilai dari parent
                enabled: widget.enabled,
                itemAsString: widget.itemAsString,
                compareFn: widget.compareFn,
                filterFn: widget.filterFn,

                // Hapus padding/border internal agar patuh ke InputDecorator
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                dropdownBuilder: (context, selectedItem) {
                  final text = (selectedItem == null)
                      ? widget.hint
                      : (widget.itemAsString?.call(selectedItem) ??
                            '$selectedItem');
                  final color = (selectedItem == null)
                      ? Colors.grey.shade600
                      : Colors.black87;
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

                dropdownButtonProps: DropdownButtonProps(
                  icon: AnimatedBuilder(
                    animation: _rotationAnim,
                    builder: (_, __) => Transform.rotate(
                      angle: _rotationAnim.value * 3.14159,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                ),

                popupProps: widget.useDialogPopup
                    ? PopupProps.dialog(
                        showSearchBox: widget.showSearchBox,
                        searchDelay: Duration.zero,
                        title: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                widget.dialogTitle ?? widget.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.items.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        constraints: BoxConstraints.tightFor(width: 400)
                            .copyWith(maxHeight: widget.popupMaxHeight),
                        onDismissed: () {
                          if (mounted) _animController.reverse();
                        },
                        dialogProps: DialogProps(
                          backgroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        listViewProps: ListViewProps(
                          controller: _listScrollCtrl,
                          itemExtent: _itemExtent,
                        ),
                        itemBuilder: (context, item, isSelected) =>
                            _buildPopupItem(context, item, isSelected),
                        searchFieldProps: _buildSearchFieldProps(),
                      )
                    : PopupProps.menu(
                        fit: FlexFit.loose,
                        showSearchBox: widget.showSearchBox,
                        searchDelay: Duration.zero,
                        constraints: BoxConstraints(maxHeight: widget.popupMaxHeight),
                        onDismissed: () {
                          if (mounted) _animController.reverse();
                        },
                        menuProps: MenuProps(
                          backgroundColor: Colors.white,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context, item, isSelected) =>
                            _buildPopupItem(context, item, isSelected),
                        searchFieldProps: _buildSearchFieldProps(),
                      ),

                onBeforePopupOpening: (selected) async {
                  _animController.forward();
                  if (widget.useDialogPopup) {
                    Future.delayed(
                      const Duration(milliseconds: 150),
                      _scrollToSelected,
                    );
                  }
                  return true;
                },

                onChanged: (val) {
                  field.didChange(val); // agar validator aware
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
  /// label/helper/error/border dipusatkan di sini.
  Widget _decorated(
    BuildContext context, {
    required Widget child,
    String? errorText,
  }) {
    return InputDecorator(
      isFocused: false,
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        helperText: widget.helperText,
        errorText: errorText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 22)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabled: widget.enabled,
        isDense: true, // bikin lebih “padat”
        contentPadding: widget.contentPadding, // horizontal 16, vertical 0
      ),
      child: child,
    );
  }

  Widget _loadingRow() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Memuat...',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _fetchErrorRow(BuildContext context) {
    return Row(
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
  }

  TextFieldProps _buildSearchFieldProps() {
    return TextFieldProps(
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildPopupItem(BuildContext context, T item, bool isSelected) {
    final text = widget.itemAsString?.call(item) ?? '$item';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}
