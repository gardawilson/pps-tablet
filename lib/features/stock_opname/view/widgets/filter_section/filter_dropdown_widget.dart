import 'package:flutter/material.dart';
import '../../../../../common/widgets/dropdown_field.dart'; // pastikan path ini benar

class FilterDropdownWidget extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onChanged;

  const FilterDropdownWidget({
    Key? key,
    required this.selectedFilter,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // definisikan daftar filter
    final List<_FilterOption> options = const [
      _FilterOption(value: 'all', label: 'Semua'),
      _FilterOption(value: 'bahanbaku', label: 'Bahan Baku'),
      _FilterOption(value: 'washing', label: 'Washing'),
      _FilterOption(value: 'broker', label: 'Broker'),
      _FilterOption(value: 'crusher', label: 'Crusher'),
      _FilterOption(value: 'bonggolan', label: 'Bonggolan'),
      _FilterOption(value: 'gilingan', label: 'Gilingan'),
      _FilterOption(value: 'mixer', label: 'Mixer'),
      _FilterOption(value: 'furniturewip', label: 'Furniture WIP'),
      _FilterOption(value: 'barangjadi', label: 'Barang Jadi'),
      _FilterOption(value: 'reject', label: 'Reject'),
    ];

    // cari nilai yang cocok (atau fallback ke 'all')
    final _FilterOption? selected = options
        .firstWhere((o) => o.value == selectedFilter,
        orElse: () => options.first);

    return DropdownPlainField<_FilterOption>(
      label: 'Kategori',
      hint: 'Pilih Kategori',
      prefixIcon: Icons.category_outlined,
      fieldHeight: 40,
      isExpanded: true,
      items: options,
      value: selected,
      itemAsString: (opt) => opt.label,
      compareFn: (a, b) => a.value == b.value,
      onChanged: (opt) => onChanged(opt?.value),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;
  const _FilterOption({required this.value, required this.label});

  @override
  String toString() => label;
}
