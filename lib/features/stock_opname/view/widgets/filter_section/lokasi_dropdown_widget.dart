import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../common/widgets/search_dropdown_field.dart';
import '../../../../shared/lokasi/lokasi_view_model.dart';
import '../../../../shared/lokasi/lokasi_model.dart';

class LokasiDropdownWidget extends StatefulWidget {
  final String? selectedBlok;
  final int? selectedIdLokasi;
  final void Function(String? blok, int? idLokasi) onChanged;
  final bool enabled;
  final String label;
  final IconData icon;
  final bool includeAllOption;

  const LokasiDropdownWidget({
    Key? key,
    required this.selectedBlok,
    required this.selectedIdLokasi,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Lokasi',
    this.icon = Icons.location_on_outlined,
    this.includeAllOption = true,
  }) : super(key: key);

  @override
  State<LokasiDropdownWidget> createState() => _LokasiDropdownWidgetState();
}

class _LokasiDropdownWidgetState extends State<LokasiDropdownWidget> {
  static const String _allLabel = 'Semua Lokasi';
  _LokasiOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    // Ambil daftar lokasi saat pertama kali tampil
    Future.microtask(() => context.read<LokasiViewModel>().fetchLokasiList());
  }

  @override
  void didUpdateWidget(covariant LokasiDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika selectedBlok atau selectedIdLokasi berubah dari luar (parent)
    if (oldWidget.selectedBlok != widget.selectedBlok ||
        oldWidget.selectedIdLokasi != widget.selectedIdLokasi) {
      _selectedOption = _LokasiOption(
        blok: widget.selectedBlok,
        idLokasi: widget.selectedIdLokasi,
        label: _composeLabel(widget.selectedBlok, widget.selectedIdLokasi),
      );
    }
  }

  /// Menyusun teks label seperti “A01”, “B”, atau “Semua Lokasi”
  String _composeLabel(String? blok, int? idLokasi) {
    if ((blok == null || blok.isEmpty) && (idLokasi == null)) return _allLabel;
    if (blok != null && idLokasi != null) return '$blok$idLokasi';
    if (blok != null) return blok;
    return idLokasi?.toString() ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LokasiViewModel>(
      builder: (context, vm, _) {
        final list = vm.lokasiList;

        // Konversi data Lokasi menjadi opsi dropdown
        final List<_LokasiOption> options = [
          if (widget.includeAllOption)
            const _LokasiOption(blok: null, idLokasi: null, label: _allLabel),
          ...list.map((Lokasi e) {
            final int? parsedId =
            e.idLokasi.isEmpty ? null : int.tryParse(e.idLokasi);

            return _LokasiOption(
              blok: e.blok.isEmpty ? null : e.blok,
              idLokasi: parsedId,
              label: _composeLabel(e.blok, parsedId),
            );
          }),
        ];

        // Tentukan selected berdasarkan state saat ini
        final selected = _selectedOption == null
            ? options.firstWhere(
              (o) =>
          o.blok == widget.selectedBlok &&
              o.idLokasi == widget.selectedIdLokasi,
          orElse: () => options.first,
        )
            : _selectedOption!;

        return SearchDropdownField<_LokasiOption>(
          items: options,
          value: selected,
          onChanged: widget.enabled
              ? (opt) {
            setState(() => _selectedOption = opt);
            widget.onChanged(opt?.blok, opt?.idLokasi);
          }
              : null,
          itemAsString: (opt) => opt.label,
          label: widget.label,
          hint: vm.isLoading
              ? 'Memuat...'
              : (vm.errorMessage.isNotEmpty
              ? 'Terjadi error'
              : (options.isEmpty ? 'Tidak ada data' : 'Pilih lokasi')),
          prefixIcon: widget.icon,
          enabled: widget.enabled,
          fieldHeight: 40,
          isExpanded: true,
          showSearchBox: true,
          searchHint: 'Cari lokasi…',
          popupMaxHeight: 480,
          isLoading: vm.isLoading,
          fetchError: vm.errorMessage.isNotEmpty,
          fetchErrorText: vm.errorMessage,
          onRetry: vm.fetchLokasiList,
          filterFn: (opt, filter) {
            final q =
            filter.toLowerCase().replaceAll(RegExp(r'[\s\-_\.]'), '');
            final k =
            opt.label.toLowerCase().replaceAll(RegExp(r'[\s\-_\.]'), '');
            return k.contains(q);
          },
          compareFn: (a, b) =>
          a.idLokasi == b.idLokasi && a.blok == b.blok,
        );
      },
    );
  }
}

class _LokasiOption {
  final String? blok;
  final int? idLokasi;
  final String label;

  const _LokasiOption({
    required this.blok,
    required this.idLokasi,
    required this.label,
  });

  @override
  String toString() => label;
}
