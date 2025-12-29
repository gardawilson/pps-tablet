import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../view_model/washing_production_view_model.dart';
import '../model/washing_production_model.dart';
// Pakai DropdownPlainField (non-search) agar list sama dengan SearchDropdownField
import '../../../../common/widgets/dropdown_field.dart';

class WashingProductionDropdown extends StatefulWidget {
  final String? preselectNoProduksi;
  final String? preselectNamaMesin;
  final ValueChanged<WashingProduction?>? onChanged;
  final String label;
  final IconData icon;
  final String? hintText;
  final DateTime? date;
  final int? shiftFilter;
  final bool enabled;

  const WashingProductionDropdown({
    super.key,
    this.preselectNoProduksi,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'No Produksi',
    this.icon = Icons.factory_outlined,
    this.hintText,
    this.date,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<WashingProductionDropdown> createState() => _WashingProductionDropdownState();
}

class _WashingProductionDropdownState extends State<WashingProductionDropdown> {
  WashingProduction? _value;

  /// Saat true, dropdown hanya menampilkan item dari `_localItems`
  /// (mode EDIT: tidak fetch API sama sekali).
  bool _usePreselectedOnly = false;

  /// Sumber data lokal ketika mode edit.
  List<WashingProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant WashingProductionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika sedang modelOnly (edit), abaikan perubahan tanggal
    if (_usePreselectedOnly) return;

    // Kalau bukan edit & tanggal berubah → refetch (tunda ke frame berikutnya)
    if (oldWidget.date != widget.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentDate();
      });
    }
  }

  Future<void> _primeOrFetch() async {
    final pre = (widget.preselectNoProduksi ?? '').trim();
    if (pre.isNotEmpty) {
      // === EDIT MODE: siapkan item lokal, JANGAN utak-atik VM ===
      final wp = WashingProduction(
        noProduksi: pre,
        idOperator: 0,
        namaOperator: '',
        idMesin: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        tglProduksi: DateTime.now().toUtc(),
        jamKerja: 0,
        shift: widget.shiftFilter ?? 0,
        createBy: '',
        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        jmlhAnggota: 0,
        hadir: 0,
        hourMeter: 0,
        hourStart: '',
        hourEnd: '',

        // ✅ NEW FIELDS (tutup transaksi)
        isLocked: false,
        lastClosedDate: null,
      );

      setState(() {
        _usePreselectedOnly = true;
        _localItems = [wp];
        _value = wp;
      });

      widget.onChanged?.call(wp);
      return;
    }

    // === FETCH MODE ===
    await _fetchForCurrentDate();
  }

  Future<void> _fetchForCurrentDate() async {
    final vm = context.read<WashingProductionViewModel>();

    // Jika tak ada tanggal, anggap kosong (tidak error)
    if (widget.date == null) {
      vm.items = [];
      vm.error = '';
      vm.isLoading = false;
      vm.notifyListeners();
      setState(() => _value = null);
      return;
    }

    vm.isLoading = true;
    vm.error = '';
    vm.notifyListeners();

    try {
      await vm.fetchByDate(widget.date!);
      if (!mounted) return;

      // Sesuaikan nilai terpilih jika tak match lagi
      final hasMatch = vm.items.any((e) => e.noProduksi == _value?.noProduksi);
      setState(() {
        _usePreselectedOnly = false; // pastikan di fetch mode
        if (!hasMatch) _value = null;
      });
    } catch (e) {
      vm.error = 'Gagal memuat data produksi';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WashingProductionViewModel>(
      builder: (context, vm, _) {
        // Pilih sumber data: lokal (edit) atau VM (fetch)
        List<WashingProduction> base = _usePreselectedOnly ? _localItems : vm.items;

        // Filter shift jika ada
        if (widget.shiftFilter != null) {
          base = base.where((e) => e.shift == widget.shiftFilter).toList();
        }

        // Pastikan value masih valid
        final hasMatch = base.any((e) => e.noProduksi == _value?.noProduksi);
        final safeValue = hasMatch ? _value : null;

        // Status UI (loading/error/hint) hanya relevan di fetch mode
        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<WashingProduction>(
          // === gaya identik dengan SearchDropdownField ===
          label: widget.label,
          prefixIcon: widget.icon,
          fieldHeight: 40,

          // === data ===
          value: safeValue,
          items: base,
          itemAsString: (e) => '${e.noProduksi} | ${e.namaMesin ?? ''} (SHIFT ${e.shift ?? ''})'.trim(),
          compareFn: (a, b) => a.noProduksi == b.noProduksi,

          // === interaksi ===
          onChanged: widget.enabled
              ? (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          }
              : null,
          enabled: widget.enabled,

          // === state & pesan (aktif hanya di fetch mode) ===
          isLoading: isLoading,
          fetchError: hasError,
          fetchErrorText: errorText,
          onRetry: _usePreselectedOnly ? null : _fetchForCurrentDate,

          hint: isLoading
              ? 'Memuat...'
              : (hasError
              ? 'Terjadi error'
              : (base.isEmpty ? (widget.hintText ?? 'Tidak ada data') : 'PILIH')),
        );
      },
    );
  }
}
