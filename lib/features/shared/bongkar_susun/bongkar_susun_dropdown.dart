import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import './bongkar_susun_view_model.dart';
import './bongkar_susun_model.dart';
import '../../../common/widgets/dropdown_field.dart';

class BongkarSusunDropdown extends StatefulWidget {
  final String? preselectNoBongkarSusun;
  final ValueChanged<BongkarSusun?>? onChanged;
  final String label;
  final IconData? icon;
  final String? hintText;
  final DateTime? date;
  final bool enabled;

  const BongkarSusunDropdown({
    super.key,
    this.preselectNoBongkarSusun,
    this.onChanged,
    this.label = 'Bongkar Susun',
    this.icon,
    this.hintText,
    this.date,
    this.enabled = true,
  });

  @override
  State<BongkarSusunDropdown> createState() => _BongkarSusunDropdownState();
}

class _BongkarSusunDropdownState extends State<BongkarSusunDropdown> {
  BongkarSusun? _value;

  @override
  void initState() {
    super.initState();
    // ☑️ Sama seperti production: semua aksi dipindah ke post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant BongkarSusunDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ☑️ Refetch saat tanggal dari parent berubah — tapi tunda ke frame berikutnya
    if (oldWidget.date != widget.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentDate();
      });
    }
  }

  Future<void> _primeOrFetch() async {
    final vm = context.read<BongkarSusunViewModel>();

    // ☑️ Mode edit: inject 1 item agar dropdown bisa tampil tanpa fetch
    final pre = widget.preselectNoBongkarSusun?.trim();
    if (pre != null && pre.isNotEmpty) {
      final bs = BongkarSusun(
        noBongkarSusun: pre,
        tanggal: DateTime.now().toUtc(),
        idUsername: 0,
        note: null,
      );
      vm.items = [bs];
      vm.isLoading = false;
      vm.error = '';
      vm.notifyListeners();

      setState(() => _value = bs);
      widget.onChanged?.call(bs);
      return;
    }

    await _fetchForCurrentDate();
  }

  Future<void> _fetchForCurrentDate() async {
    if (widget.date == null) {
      // Tidak ada tanggal → anggap kosong (atau tambahkan fetchToday() kalau tersedia)
      final vm = context.read<BongkarSusunViewModel>();
      vm.items = [];
      vm.error = '';
      vm.isLoading = false;
      vm.notifyListeners();
      setState(() => _value = null);
      return;
    }

    final vm = context.read<BongkarSusunViewModel>();

    // ☑️ Aman karena dipanggil post-frame
    vm.isLoading = true;
    vm.error = '';
    vm.notifyListeners();

    try {
      await vm.fetchByDate(widget.date!);

      if (!mounted) return;

      final hasMatch = vm.items.any((e) => e.noBongkarSusun == _value?.noBongkarSusun);
      setState(() => _value = hasMatch ? _value : null);
    } catch (_) {
      vm.error = 'Gagal memuat data Bongkar/Susun';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BongkarSusunViewModel>(
      builder: (context, vm, _) {
        final items = vm.items
            .map((bs) => DropdownMenuItem<BongkarSusun>(
          value: bs,
          child: Text(bs.noBongkarSusun, overflow: TextOverflow.ellipsis),
        ))
            .toList();

        final hasMatch = items.any((i) => i.value?.noBongkarSusun == _value?.noBongkarSusun);
        final safeValue = hasMatch ? _value : null;

        return DropdownPlainField<BongkarSusun>(
          label: widget.label,
          prefixIcon: widget.icon ?? Ionicons.layers_outline,
          fieldHeight: 40,
          value: safeValue,
          items: vm.items,                          // <— langsung list of T
          itemAsString: (e) => e.noBongkarSusun,    // <— tampilkan teks
          enabled: widget.enabled,

          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error,
          onRetry: _fetchForCurrentDate,

          hint: vm.isLoading
              ? 'Memuat...'
              : (vm.error.isNotEmpty
              ? 'Terjadi error'
              : (vm.items.isEmpty ? (widget.hintText ?? 'Tidak ada data') : 'PILIH')),

          onChanged: widget.enabled
              ? (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          }
              : null,
        );

      },
    );
  }
}
