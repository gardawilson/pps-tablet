// lib/features/verifikasi/view/verifikasi_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_detail_dialog.dart';
import 'verifikasi_theme.dart';

/// Satu panel: semua jenis produksi digabung jadi satu list (tidak lagi
/// dipecah per tab) karena volume harian tiap jenis produksi kecil (< 10).
/// Chip filter jenis di header bersifat opsional, bukan navigasi wajib.
/// Meniru gaya [SoV2DetailScreen] (stock_opname_v2): tanpa AppBar, header
/// panel putih + border bawah. Detail cross-check input/output tetap
/// dialog popup.
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
          : _buildListPanel(context, vm),
    );
  }

  // ── Panel: daftar NoProduksi menunggu verifikasi (semua jenis) ──────────
  Widget _buildListPanel(BuildContext context, VerifikasiViewModel vm) {
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
              const Text(
                'Verifikasi Produksi',
                style: TextStyle(
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
              const SizedBox(height: 12),
              _buildJenisChips(vm),
            ],
          ),
        ),
        Expanded(child: _buildBody(context, vm, list)),
      ],
    );
  }

  // ── Chip filter jenis (opsional) ─────────────────────────────────────────
  Widget _buildJenisChips(VerifikasiViewModel vm) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _JenisChip(
          label: 'Semua (${vm.items.length})',
          selected: vm.selectedJenis == null,
          color: kVerifikasiAccent,
          onTap: () => vm.setJenisFilter(null),
        ),
        for (final key in vm.availableJenis)
          _JenisChip(
            label: '${vm.jenisLabel(key)} (${vm.countFor(key)})',
            selected: vm.selectedJenis == key,
            color: jenisColor(key, vm.availableJenis),
            onTap: () => vm.setJenisFilter(key),
          ),
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
          jenisBadgeColor: jenisColor(list[i].jenisKey, vm.availableJenis),
          onTap: () =>
              showVerifikasiDetailDialog(context, vm: vm, item: list[i]),
        ),
      ),
    );
  }
}

class _VerifikasiListRow extends StatelessWidget {
  final VerifikasiItem item;
  final Color jenisBadgeColor;
  final VoidCallback onTap;

  const _VerifikasiListRow({
    required this.item,
    required this.jenisBadgeColor,
    required this.onTap,
  });

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
            SizedBox(
              width: 76,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: jenisBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.jenisLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: jenisBadgeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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

/// Chip filter jenis produksi — opsional, bukan navigasi wajib. Tap ulang
/// pada chip yang sedang terpilih untuk kembali ke "Semua".
class _JenisChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _JenisChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : kVerifikasiBorder,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? color : kVerifikasiMuted,
              ),
            ),
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
