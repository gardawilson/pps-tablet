// lib/features/verifikasi/view/verifikasi_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_sc_dialog.dart';
import 'verifikasi_kd_dialog.dart';
import 'verifikasi_pc_dialog.dart';
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
          hasOperatorStep: vm.hasOperatorStep(list[i].jenisKey),
          hasDepartmentStep: vm.hasDepartmentStep(list[i].jenisKey),
          onTapKepalaStok: () =>
              showVerifikasiScDialog(context, vm: vm, item: list[i]),
          onTapOperator: () =>
              showVerifikasiPcDialog(context, vm: vm, item: list[i]),
          onTapFinal: () =>
              showVerifikasiKdDialog(context, vm: vm, item: list[i]),
        ),
      ),
    );
  }
}

class _VerifikasiListRow extends StatelessWidget {
  final VerifikasiItem item;
  final Color jenisBadgeColor;

  /// Tiga modul verifikasi yang berdiri sendiri-sendiri — Stock Controller
  /// & Production Controller bisa diisi kapan pun tanpa saling menunggu,
  /// sementara Kadept baru bisa dilakukan setelah keduanya tuntas (lihat
  /// [_ActionBadges]).
  final VoidCallback onTapKepalaStok;
  final VoidCallback onTapOperator;
  final VoidCallback onTapFinal;

  /// True hanya untuk jenis produksi yang punya tahap verifikasi Production
  /// Controller terpisah dari verifikasi Stock Controller (saat ini: washing).
  final bool hasOperatorStep;

  /// True hanya untuk jenis produksi yang punya tahap verifikasi Kadept
  /// (department) — saat ini juga hanya washing.
  final bool hasDepartmentStep;

  const _VerifikasiListRow({
    required this.item,
    required this.jenisBadgeColor,
    required this.onTapKepalaStok,
    required this.onTapOperator,
    required this.onTapFinal,
    required this.hasOperatorStep,
    required this.hasDepartmentStep,
  });

  @override
  Widget build(BuildContext context) {
    final tgl = item.tglProduksi != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(item.tglProduksi!.toLocal())
        : '-';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori (jenis produksi) di atas, NoProduksi di bawahnya.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: jenisBadgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.jenisLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: jenisBadgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.noProduksi,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.normal,
                    color: kVerifikasiInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _colField('MESIN', item.namaMesin ?? '-')),
          Expanded(flex: 2, child: _colField('TANGGAL', tgl)),
          SizedBox(
            width: 56,
            child: _colField('SHIFT', '${item.shift ?? '-'}'),
          ),
          Expanded(
            flex: 3,
            child: _colField('OUTPUT', item.outputJenisNama ?? '-'),
          ),
          SizedBox(width: 64, child: _rendemenField(item.rendemen)),
          const SizedBox(width: 10),
          _ActionBadges(
            item: item,
            hasOperatorStep: hasOperatorStep,
            hasDepartmentStep: hasDepartmentStep,
            onTapKepalaStok: onTapKepalaStok,
            onTapOperator: onTapOperator,
            onTapFinal: onTapFinal,
          ),
        ],
      ),
    );
  }

  Widget _colField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: kVerifikasiMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: kVerifikasiInk),
        ),
      ],
    );
  }

  /// Kolom rendemen (output/input) — null kalau jenis produksinya tidak
  /// men-support `?includeRendemen=true` atau belum ada data input-output.
  /// Diwarnai merah kalau di bawah 80% (susut proses tinggi), hijau kalau
  /// di atas, abu-abu kalau tidak ada data.
  Widget _rendemenField(double? rendemen) {
    final color = rendemen == null
        ? kVerifikasiMuted
        : (rendemen < 80 ? kVerifikasiWarning : kVerifikasiSuccess);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'RENDEMEN',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: kVerifikasiMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rendemen == null ? '-' : '${rendemen.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Tiga badge-tombol verifikasi — Stock Controller, Production Controller
/// (kalau [hasOperatorStep]), Kadept (kalau [hasDepartmentStep]). SC & PC
/// selalu bisa ditekan (dua modul yang independen, tidak perlu menunggu
/// mana yang diisi duluan); Kadept baru aktif setelah SC & PC sama-sama
/// tuntas.
class _ActionBadges extends StatelessWidget {
  final VerifikasiItem item;
  final bool hasOperatorStep;
  final bool hasDepartmentStep;
  final VoidCallback onTapKepalaStok;
  final VoidCallback onTapOperator;
  final VoidCallback onTapFinal;

  const _ActionBadges({
    required this.item,
    required this.hasOperatorStep,
    required this.hasDepartmentStep,
    required this.onTapKepalaStok,
    required this.onTapOperator,
    required this.onTapFinal,
  });

  @override
  Widget build(BuildContext context) {
    final finalReady = item.verified && item.verifiedOperator;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // SC & PC ditumpuk vertikal satu kolom supaya baris tidak melebar.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _badge(
              label: 'SC',
              verified: item.verified,
              byUsername: item.verifiedByUsername,
              at: item.verifiedAt,
              fullLabel: 'Stock Controller',
              onTap: onTapKepalaStok,
            ),
            if (hasOperatorStep) ...[
              const SizedBox(height: 4),
              _badge(
                label: 'PC',
                verified: item.verifiedOperator,
                byUsername: item.operatorVerifiedByUsername,
                at: item.operatorVerifiedAt,
                fullLabel: 'Production Controller',
                onTap: onTapOperator,
              ),
            ],
          ],
        ),
        if (hasDepartmentStep) ...[
          const SizedBox(width: 6),
          _badge(
            label: 'KD',
            verified: item.verifiedDepartment,
            byUsername: item.departmentVerifiedByUsername,
            at: item.departmentVerifiedAt,
            fullLabel: 'Kadept',
            onTap: finalReady ? onTapFinal : null,
            disabledMessage:
                'Kadept: menunggu Stock Controller & Production Controller tuntas',
          ),
        ],
      ],
    );
  }

  Widget _badge({
    required String label,
    required bool verified,
    required String fullLabel,
    String? byUsername,
    DateTime? at,
    required VoidCallback? onTap,
    String? disabledMessage,
  }) {
    final disabled = onTap == null;
    final color = disabled
        ? kVerifikasiBorder
        : (verified ? kVerifikasiSuccess : kVerifikasiMuted);
    final bg = disabled
        ? kVerifikasiSurface
        : (verified ? kVerifikasiSuccessBg : kVerifikasiSurface);
    final tooltip = disabled
        ? (disabledMessage ?? '$fullLabel: belum bisa diverifikasi')
        : (verified
              ? '$fullLabel: sudah diverifikasi'
                    '${byUsername != null && byUsername.isNotEmpty ? ' oleh $byUsername' : ''}'
                    '${at != null ? ' pada ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(at.toLocal())}' : ''}'
              : '$fullLabel: ketuk untuk verifikasi');

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: verified && !disabled ? color : kVerifikasiBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 11,
                color: color,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
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
