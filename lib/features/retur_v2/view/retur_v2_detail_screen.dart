import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/label_print_lock_api.dart';
import '../../../core/services/label_print_sync_queue.dart';
import '../../../core/utils/pdf_print_service.dart';
import '../../../core/view/app_shell.dart';
import '../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../label/furniture_wip/repository/furniture_wip_repository.dart';
import '../../label/packing/repository/packing_repository.dart';
import '../model/retur_v2_output.dart';
import '../view_model/retur_v2_detail_view_model.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);
const _kSuccess = Color(0xFF0A7349);
const _kSuccessBg = Color(0xFFE9F6EF);

const _kKodeKategoriFurnitureWip = 'furniturewip';

String _featureOf(ReturV2Output o) =>
    o.kodeKategori == _kKodeKategoriFurnitureWip ? 'furniture_wip' : 'packing';

String _pdfUrlOf(ReturV2Output o) =>
    o.kodeKategori == _kKodeKategoriFurnitureWip
    ? ApiConstants.furnitureWipLabelPdf(o.labelCode)
    : ApiConstants.packingLabelPdf(o.labelCode);

Future<int?> _markAsPrinted(ReturV2Output o) =>
    o.kodeKategori == _kKodeKategoriFurnitureWip
    ? FurnitureWipRepository().markAsPrinted(o.labelCode)
    : PackingRepository(api: ApiClient()).markAsPrinted(o.labelCode);

/// Detail 1 nomor retur: daftar output Furniture WIP & Barang Jadi hasil
/// retur tsb, bisa dipilih & dicetak sekaligus (multi-print) — pola yang
/// sama dengan bucket print dialog di InjectProductionInputScreenV3. Tidak
/// memakai AppBar sendiri karena sudah ada compact app bar global dari
/// AppShell (lihat pola yang sama di SoV2DetailScreen).
class ReturV2DetailScreen extends StatefulWidget {
  final String noRetur;

  const ReturV2DetailScreen({super.key, required this.noRetur});

  @override
  State<ReturV2DetailScreen> createState() => _ReturV2DetailScreenState();
}

class _ReturV2DetailScreenState extends State<ReturV2DetailScreen> {
  late final ReturV2DetailViewModel _vm;
  List<BreadcrumbSegment> _prevBreadcrumb = [];

  @override
  void initState() {
    super.initState();
    _vm = ReturV2DetailViewModel(noRetur: widget.noRetur);
    _vm.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
      AppShell.breadcrumb.value = [
        ..._prevBreadcrumb.map(
          (s) => BreadcrumbSegment(
            s.label,
            onTap: () {
              AppShell.breadcrumb.value = _prevBreadcrumb;
              AppShell.shellNavigatorKey.currentState?.pop();
            },
          ),
        ),
        BreadcrumbSegment(widget.noRetur),
      ];
    });
  }

  @override
  void dispose() {
    final prev = _prevBreadcrumb;
    final noRetur = widget.noRetur;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = AppShell.breadcrumb.value;
      if (current.isNotEmpty && current.last.label == noRetur) {
        AppShell.breadcrumb.value = prev;
      }
    });
    _vm.dispose();
    super.dispose();
  }

  void _openPrintDialog(String sectionTitle, List<ReturV2Output> items) {
    if (items.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => _ReturPrintPickerDialog(
        sectionTitle: sectionTitle,
        items: items,
        onPrint: _printEntries,
      ),
    );
  }

  /// Lock semua label yang dipilih, gabung PDF-nya jadi satu preview, lalu
  /// per-label yang berhasil dicetak: tandai HasBeenPrinted & lepas lock.
  /// Kalau mark/lepas lock gagal (mis. koneksi putus), antre ke
  /// [LabelPrintSyncQueue] supaya disinkronkan ulang nanti — persis alur
  /// [_printLabelsBatch] di InjectProductionInputScreenV3.
  Future<void> _printEntries(List<ReturV2Output> entries) async {
    if (entries.isEmpty) return;
    final lockApi = LabelPrintLockApi();
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    final acquiredCodes = <String>{};
    for (final entry in entries) {
      if (!mounted) break;
      try {
        await lockApi.acquire(entry.labelCode);
        acquiredCodes.add(entry.labelCode);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal lock ${entry.labelCode}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    final printedCodes = <String>{};
    final callbacks = entries.map((entry) {
      return () {
            printedCodes.add(entry.labelCode);
            () async {
              var needsIncrement = false;
              var needsRelease = false;
              try {
                final count = await _markAsPrinted(entry);
                if (count != null) lockVm.setPrintCount(entry.labelCode, count);
              } catch (_) {
                needsIncrement = true;
              }
              try {
                await lockApi.release(entry.labelCode);
              } catch (_) {
                needsRelease = true;
              }
              if (needsIncrement || needsRelease) {
                await queue.enqueue(
                  feature: _featureOf(entry),
                  noLabel: entry.labelCode,
                  needsIncrement: needsIncrement,
                  needsReleaseLock: needsRelease,
                );
              }
            }().ignore();
          }
          as VoidCallback;
    }).toList();

    try {
      await PdfPrintService(defaultSystem: 'pps').previewMultipleFromUrls(
        context: rootCtx,
        pdfUrls: entries.map((e) => Uri.parse(_pdfUrlOf(e))).toList(),
        title: 'Cetak ${entries.length} Label',
        onPrintedCallbacks: callbacks,
      );
    } finally {
      for (final entry in entries) {
        if (acquiredCodes.contains(entry.labelCode) &&
            !printedCodes.contains(entry.labelCode)) {
          () async {
            try {
              await lockApi.release(entry.labelCode);
            } catch (_) {
              await queue.enqueue(
                feature: _featureOf(entry),
                noLabel: entry.labelCode,
                needsReleaseLock: true,
              );
            }
          }().ignore();
        }
      }
      if (mounted) _vm.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReturV2DetailViewModel>.value(
      value: _vm,
      child: Consumer<ReturV2DetailViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: _kSurface,
            body: RefreshIndicator(onRefresh: vm.load, child: _buildBody(vm)),
          );
        },
      ),
    );
  }

  Widget _buildBody(ReturV2DetailViewModel vm) {
    if (vm.isLoading &&
        vm.furnitureWipItems.isEmpty &&
        vm.barangJadiItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null &&
        vm.furnitureWipItems.isEmpty &&
        vm.barangJadiItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              vm.error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _OutputSection(
            title: 'Furniture WIP',
            icon: Icons.chair_alt_rounded,
            items: vm.furnitureWipItems,
            onPrintTap: () =>
                _openPrintDialog('Furniture WIP', vm.furnitureWipItems),
          ),
        ),
        const VerticalDivider(width: 1, color: _kBorder),
        Expanded(
          child: _OutputSection(
            title: 'Barang Jadi',
            icon: Icons.inventory_2_rounded,
            items: vm.barangJadiItems,
            onPrintTap: () =>
                _openPrintDialog('Barang Jadi', vm.barangJadiItems),
          ),
        ),
      ],
    );
  }
}

class _OutputSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ReturV2Output> items;
  final VoidCallback onPrintTap;

  const _OutputSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.onPrintTap,
  });

  @override
  Widget build(BuildContext context) {
    final printedCount = items.where((o) => o.hasBeenPrinted).length;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    Text(
                      '$printedCount/${items.length} dicetak',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: items.isEmpty ? null : onPrintTap,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text(
                  'Cetak',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada output $title',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (context, index) =>
                      _OutputTile(output: items[index]),
                ),
        ),
      ],
    );
  }
}

class _OutputTile extends StatelessWidget {
  final ReturV2Output output;

  const _OutputTile({required this.output});

  @override
  Widget build(BuildContext context) {
    final printed = output.hasBeenPrinted;
    final lokasi = output.lokasiLabel;
    final subtitleParts = [
      output.labelCode,
      '${output.qty} ${output.uom}'.trim(),
      if (lokasi != null) lokasi,
      if (output.dateCreate != null && output.dateCreate!.isNotEmpty)
        output.dateCreate!,
    ];
    final title = output.namaJenis != null && output.namaJenis!.isNotEmpty
        ? output.namaJenis!
        : output.labelCode;

    return Container(
      color: printed ? _kSuccessBg : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            printed ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: printed ? _kSuccess : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: printed ? _kSuccess : const Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: printed
                  ? _kSuccess.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              printed ? 'Sudah Dicetak' : 'Belum Dicetak',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: printed ? _kSuccess : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Print picker dialog (multi-select) ─────────────────────────────────────

/// Dialog pilih label untuk dicetak sekaligus — desain & alur seleksi sama
/// dengan `_BucketPrintDialog` di InjectProductionInputScreenV3.
class _ReturPrintPickerDialog extends StatefulWidget {
  final String sectionTitle;
  final List<ReturV2Output> items;
  final void Function(List<ReturV2Output> selected) onPrint;

  const _ReturPrintPickerDialog({
    required this.sectionTitle,
    required this.items,
    required this.onPrint,
  });

  @override
  State<_ReturPrintPickerDialog> createState() =>
      _ReturPrintPickerDialogState();
}

class _ReturPrintPickerDialogState extends State<_ReturPrintPickerDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.map((e) => e.labelCode).toSet();
  }

  bool get _allSelected => _selected.length == widget.items.length;

  void _toggleAll() => setState(() {
    if (_allSelected) {
      _selected.clear();
    } else {
      _selected.addAll(widget.items.map((e) => e.labelCode));
    }
  });

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.items
        .where((e) => _selected.contains(e.labelCode))
        .toList();
    final selectedCount = selectedItems.length;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.print_outlined,
                      color: _kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Label untuk Dicetak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D23),
                          ),
                        ),
                        Text(
                          widget.sectionTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    style: TextButton.styleFrom(
                      foregroundColor: _kPrimary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      _allSelected ? 'Batalkan Semua' : 'Pilih Semua',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _ReturLabelCheckTile(
                    item: item,
                    isSelected: _selected.contains(item.labelCode),
                    onToggle: () => setState(() {
                      if (_selected.contains(item.labelCode)) {
                        _selected.remove(item.labelCode);
                      } else {
                        _selected.add(item.labelCode);
                      }
                    }),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton.icon(
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onPrint(selectedItems);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: Text(
                  selectedCount == 0
                      ? 'Pilih label dulu'
                      : 'Cetak $selectedCount Label',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturLabelCheckTile extends StatelessWidget {
  final ReturV2Output item;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ReturLabelCheckTile({
    required this.item,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final printed = item.hasBeenPrinted;
    final title = item.namaJenis != null && item.namaJenis!.isNotEmpty
        ? item.namaJenis!
        : item.labelCode;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _kPrimary.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? _kPrimary : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF1A1D23)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  Text(
                    item.labelCode,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.qty} ${item.uom}'.trim(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              printed ? Icons.print : Icons.print_disabled_outlined,
              size: 13,
              color: printed ? _kSuccess : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
