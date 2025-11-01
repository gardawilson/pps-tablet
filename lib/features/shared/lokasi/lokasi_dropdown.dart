import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ganti path sesuai lokasimu
import '../../../common/widgets/search_dropdown_field.dart';
import 'lokasi_view_model.dart';
import 'lokasi_model.dart';

class LokasiDropdown extends StatelessWidget {
  final Lokasi? value;                   // ✅ sekarang pakai Lokasi, bukan String
  final ValueChanged<Lokasi?>? onChanged;
  final String label;
  final String hint;
  final bool includeSemua;
  final Lokasi semuaOption;              // ✅ opsi "Semua" juga Lokasi

  const LokasiDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.label = 'Lokasi',
    this.hint = 'Pilih Lokasi',
    this.includeSemua = true,
    this.semuaOption = const Lokasi(idLokasi: '__SEMUA__', blok: '-', enable: true),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LokasiViewModel>(
      builder: (context, vm, _) {
        // siapkan daftar (dengan opsi "Semua" di paling atas kalau diminta)
        final lokasiItems = <Lokasi>[
          if (includeSemua) semuaOption,
          ...vm.lokasiList,
        ];

        // kalau belum ada value, default ke "Semua" (jika includeSemua)
        final effectiveValue = value ?? (includeSemua ? semuaOption : null);

        return SearchDropdownField<Lokasi>(
          // ====== DATA ======
          items: lokasiItems,
          value: effectiveValue,
          onChanged: (picked) {
            if (onChanged == null) return;
            // jika pilih "Semua" → lempar null (biar filter upstream mudah)
            if (picked?.idLokasi == '__SEMUA__') {
              onChanged!(null);
            } else {
              onChanged!(picked);
            }
          },
          itemAsString: (l) {
            if (l.idLokasi == '__SEMUA__') return 'Lokasi (Semua)';
            // contoh format: A10, B02, dst; fallback ke blok jika id kosong
            return (l.idLokasi.isEmpty) ? l.blok : '${l.blok}${l.idLokasi}';
          },

          // ====== UX ======
          label: label,
          hint: hint,
          prefixIcon: Icons.location_on_outlined,
          fieldHeight: 40,                // samakan tinggi antar dropdown
          isExpanded: true,
          showSearchBox: true,
          searchHint: 'Cari…',
          popupMaxHeight: 500,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

          // ====== STATE (loading / fetchError) ======
          isLoading: vm.isLoading,
          fetchError: vm.errorMessage.isNotEmpty,
          fetchErrorText: vm.errorMessage,
          // sesuaikan nama method retry di VM kamu:
          // kalau kamu punya vm.reload() atau vm.fetch(), panggil di sini
          onRetry: vm.fetchLokasiList,

          // ====== VALIDATOR (opsional) ======
          // validator: (val) => val == null ? 'Wajib pilih lokasi' : null,

          // ====== LOGIC compare & filter (sama seperti sebelumnya) ======
          // bandingkan by blok + idLokasi
          compareFn: (a, b) => a.blok == b.blok && a.idLokasi == b.idLokasi,

          // pencarian fleksibel: A10, a-10, a 10, dst.
          filterFn: (l, filter) {
            final q = filter.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
            final k1 = ('${l.blok}${l.idLokasi}').toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
            final k2 = (l.blok).toLowerCase(); // ketik "a" → match semua A..
            return k1.contains(q) || k2.contains(q);
          },
        );
      },
    );
  }
}
