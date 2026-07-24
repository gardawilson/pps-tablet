// lib/features/verifikasi/view/verifikasi_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_detail_dialog.dart';
import 'verifikasi_theme.dart';

/// Dua panel bersisian (jenis produksi di kiri, NoProduksi di kanan) —
/// meniru gaya [SoV2DetailScreen] (stock_opname_v2): tanpa AppBar, tanpa
/// frame/border-radius luar, panel flush dipisah VerticalDivider, header
/// panel putih + border bawah, baris list ditandai left-border saat
/// terpilih. Detail cross-check input/output tetap dialog popup.
class VerifikasiListScreen extends StatelessWidget {
  const VerifikasiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerifikasiViewModel>(
      create: (_) => VerifikasiViewModel()..load(),
      child: const _VerifikasiListBody(),
    );
  }
}

class _VerifikasiListBody extends StatelessWidget {
  const _VerifikasiListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VerifikasiViewModel>();
    final perm = context.watch<PermissionViewModel>();
    final canRead = perm.can('produksi_washing:read');

    return Scaffold(
      backgroundColor: kVerifikasiSurface,
      body: !canRead
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Anda tidak memiliki akses untuk halaman ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 220, child: _buildJenisPanel(vm)),
                const VerticalDivider(width: 1, color: kVerifikasiBorder),
                Expanded(child: _buildNoProduksiPanel(context, vm)),
              ],
            ),
    );
  }

  // ── Panel 1: jenis produksi ─────────────────────────────────────────────
  Widget _buildJenisPanel(VerifikasiViewModel vm) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kVerifikasiBorder)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Verifikasi Produksi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kVerifikasiInk,
                ),
              ),
            ),
          ),
          Expanded(
            child: vm.isLoading && vm.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: vm.availableJenis.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: kVerifikasiBorder),
                    itemBuilder: (context, index) {
                      final key = vm.availableJenis[index];
                      final selected = vm.selectedJenis == key;
                      return InkWell(
                        onTap: () => vm.setJenisFilter(key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? kVerifikasiAccent.withValues(alpha: 0.05)
                                : null,
                            border: Border(
                              left: BorderSide(
                                color: selected
                                    ? kVerifikasiAccent
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(9, 12, 12, 12),
                          child: Text(
                            '${vm.jenisLabel(key)} (${vm.countFor(key)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? kVerifikasiAccent
                                  : kVerifikasiInk,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Panel 2: daftar NoProduksi menunggu verifikasi ───────────────────────
  Widget _buildNoProduksiPanel(BuildContext context, VerifikasiViewModel vm) {
    final list = vm.filteredItems;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: kVerifikasiBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vm.selectedJenis != null
                    ? vm.jenisLabel(vm.selectedJenis!)
                    : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kVerifikasiInk,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      label: 'MENUNGGU VERIFIKASI',
                      value: '${list.length}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context, vm, list)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    VerifikasiViewModel vm,
    List<VerifikasiItem> list,
  ) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat data:\n${vm.error}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada produksi yang menunggu verifikasi.',
          style: TextStyle(color: kVerifikasiMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: kVerifikasiBorder),
        itemBuilder: (_, i) => _VerifikasiListRow(
          item: list[i],
          onTap: () =>
              showVerifikasiDetailDialog(context, vm: vm, item: list[i]),
        ),
      ),
    );
  }
}

class _VerifikasiListRow extends StatelessWidget {
  final VerifikasiItem item;
  final VoidCallback onTap;

  const _VerifikasiListRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tgl = item.tglProduksi != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(item.tglProduksi!.toLocal())
        : '-';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                item.noProduksi,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: kVerifikasiInk,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                item.namaMesin ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: kVerifikasiMuted),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                'Shift ${item.shift ?? '-'}',
                style: const TextStyle(fontSize: 11.5, color: kVerifikasiMuted),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                tgl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: kVerifikasiMuted),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: kVerifikasiMuted),
          ],
        ),
      ),
    );
  }
}

/// Statistik header panel: caption kecil di atas, nilai tebal di bawah.
/// Sama seperti `_HeaderStat` di SoV2DetailScreen.
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kVerifikasiInk,
          ),
        ),
      ],
    );
  }
}
