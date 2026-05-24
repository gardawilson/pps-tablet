// lib/features/production/broker/view/washing_production_input_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/broker/view_model/broker_production_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/scan_label_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../widgets/broker_input_group_popover.dart';
import '../../shared/widgets/partial_mode_not_supported_dialog.dart';
import '../../shared/widgets/weight_input_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../model/broker_inputs_model.dart';

import 'package:pps_tablet/features/production/shared/shared.dart';
import '../widgets/broker_lookup_label_dialog.dart';
import '../widgets/broker_lookup_label_partial_dialog.dart';
import '../../../label/broker/widgets/broker_form_dialog.dart';
import '../../../label/broker/widgets/broker_production_output_form_dialog.dart';
import '../../../label/bonggolan/widgets/bonggolan_production_output_form_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/network/label_print_lock_api.dart';
import '../../../../core/services/label_print_sync_queue.dart';
import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../label/broker/repository/broker_repository.dart';
import '../../../label/bonggolan/repository/bonggolan_repository.dart';
import '../../../broker_type/model/broker_type_model.dart';
import '../../../broker_type/widgets/broker_type_dropdown.dart';

const _kBrokerPrimary = Color(0xFF1E6FD9);
const _kBrokerSurface = Color(0xFFF8F9FB);
const _kBrokerBorder = Color(0xFFE2E6EA);
const _kBrokerRadius = 12.0;
const _kBrokerOutput = Color(0xFF0A7349);

BoxDecoration _brokerPanelDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: borderColor ?? _kBrokerBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ],
);

Widget _brokerSectionHeader(IconData icon, String title, {Color? iconColor}) {
  final color = iconColor ?? _kBrokerPrimary;
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D23),
        ),
      ),
    ],
  );
}

class BrokerProductionInputScreen extends StatefulWidget {
  final String noProduksi;
  final int? idMesin;
  final String? namaMesin;
  final int? shift;
  final DateTime? tglProduksi;

  final bool? isLocked;
  final DateTime? lastClosedDate;
  final String? hourStart;
  final String? hourEnd;
  final String? namaJenis;
  final int? outputJenisId;

  const BrokerProductionInputScreen({
    super.key,
    required this.noProduksi,
    this.idMesin,
    this.namaMesin,
    this.shift,
    this.tglProduksi,
    this.isLocked,
    this.lastClosedDate,
    this.hourStart,
    this.hourEnd,
    this.namaJenis,
    this.outputJenisId,
  });

  @override
  State<BrokerProductionInputScreen> createState() =>
      _BrokerProductionInputScreenState();
}

class _BrokerProductionInputScreenState
    extends State<BrokerProductionInputScreen> {
  String _selectedMode = 'full';
  String _selectedInputTab = 'broker';
  String _selectedOutputTab = 'broker';

  List<BreadcrumbSegment> _prevBreadcrumb = [];
  bool _isReplacing = false;

  @override
  void initState() {
    super.initState();
    _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        BreadcrumbSegment(widget.namaMesin ?? widget.noProduksi),
      ];
      context.read<BrokerProductionInputViewModel>().loadInputs(
        widget.noProduksi,
        force: true,
      );
      context.read<BrokerProductionInputViewModel>().loadOutputs(
        widget.noProduksi,
      );
    });
  }

  @override
  void dispose() {
    if (!_isReplacing) AppShell.breadcrumb.value = _prevBreadcrumb;
    super.dispose();
  }

  // ✅ TAMBAHKAN: Method untuk handle back button
  Future<bool> _onWillPop() async {
    final vm = context.read<BrokerProductionInputViewModel>();

    // Tidak ada temp data, boleh keluar langsung
    if (vm.totalTempCount == 0) {
      AppShell.breadcrumb.value = _prevBreadcrumb;
      return true;
    }

    // Tampilkan dialog konfirmasi
    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UnsavedTempWarningDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
        onSavePressed: () {
          Navigator.of(dialogContext).pop(false);
          _handleSave(context);
        },
      ),
    );

    // Jika user pilih "Keluar & Hapus"
    if (shouldPop == true) {
      vm.clearAllTempItems();
      AppShell.breadcrumb.value = _prevBreadcrumb;
      return true;
    }

    // Batal / Simpan Dulu -> jangan keluar
    return false;
  }

  Future<void> _openTimelineDialog() async {
    if (!mounted) return;
    final idMesin = widget.idMesin;
    final tgl = widget.tglProduksi;
    final namaMesin = widget.namaMesin;
    if (idMesin == null || tgl == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ShiftTimelineDialog(
        idMesin: idMesin,
        namaMesin: namaMesin,
        tanggal: tgl,
        shift: widget.shift ?? 1,
        currentNoProduksi: widget.noProduksi,
      ),
    );
  }

  Future<void> _openSplitDialog() async {
    if (!mounted) return;
    final idMesin = widget.idMesin;
    final tgl = widget.tglProduksi;
    if (idMesin == null || tgl == null) {
      _showSnack(
        'Data mesin/tanggal tidak tersedia',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final splitResult =
        await showDialog<({BrokerProduction prod, String namaJenis})>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _GantiProduksiDialog(
            idMesin: idMesin,
            tanggal: tgl,
            shift: widget.shift ?? 1,
            currentNoProduksi: widget.noProduksi,
          ),
        );

    if (splitResult == null || !mounted) return;

    final newProd = splitResult.prod;
    final namaJenis = splitResult.namaJenis.isNotEmpty
        ? splitResult.namaJenis
        : newProd.outputJenisNama;

    _isReplacing = true;
    AppShell.breadcrumb.value = _prevBreadcrumb;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BrokerProductionInputScreen(
          noProduksi: newProd.noProduksi,
          idMesin: newProd.idMesin,
          namaMesin: widget.namaMesin,
          shift: newProd.shift,
          tglProduksi: newProd.tglProduksi,
          isLocked: false,
          lastClosedDate: null,
          hourStart: newProd.hourStart,
          hourEnd: newProd.hourEnd,
          namaJenis: namaJenis,
          outputJenisId: newProd.outputJenisId,
        ),
      ),
    );
  }

  void _showSnack(String msg, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openScanDialog({String mode = 'full'}) async {
    setState(() => _selectedMode = mode);
    await showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        manualHint: 'X.XXXXXXXXXX',
        headerSubtitle: _modeLabel(_selectedMode),
        acceptedLabels: const [
          (prefix: 'A', label: 'Bahan Baku'),
          (prefix: 'B', label: 'Washing'),
          (prefix: 'D', label: 'Broker'),
          (prefix: 'V', label: 'Gilingan'),
          (prefix: 'F', label: 'Crusher'),
          (prefix: 'H', label: 'Mixer'),
          (prefix: 'BF', label: 'Reject'),
        ],
        onLookup: (code) async => _onCodeReady(context, code),
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'full':
        return 'FULL PALLET';
      case 'select':
        return 'SEBAGIAN PALLET';
      case 'partial':
        return 'PARTIAL';
      default:
        return mode.toUpperCase();
    }
  }

  Widget _categorySlot({
    required bool visible,
    required Widget child,
    double? width,
  }) {
    return visible
        ? SizedBox(width: width ?? 360, child: child)
        : const SizedBox.shrink();
  }

  Widget _buildWorkspaceToolbar({required bool locked, String? namaJenis}) {
    final tglText = widget.tglProduksi == null
        ? null
        : DateFormat(
            'dd MMM yyyy',
            'id_ID',
          ).format(widget.tglProduksi!.toLocal());

    final now = DateTime.now();

    final isToday =
        widget.idMesin != null &&
        widget.tglProduksi != null &&
        () {
          final t = widget.tglProduksi!;
          return t.year == now.year && t.month == now.month && t.day == now.day;
        }();

    final hStart = (widget.hourStart ?? '').trim();
    final hEnd = (widget.hourEnd ?? '').trim();

    bool isWithinTimeRange() {
      if (!isToday) return false;
      if (hStart.isEmpty && hEnd.isEmpty) return false;
      int toMin(String hhmm) {
        final p = hhmm.split(':');
        if (p.length < 2) return -1;
        final h = int.tryParse(p[0]) ?? -1;
        final m = int.tryParse(p[1]) ?? -1;
        if (h < 0 || m < 0) return -1;
        return h * 60 + m;
      }

      final nowMin = now.hour * 60 + now.minute;
      final startMin = hStart.isNotEmpty ? toMin(hStart) : 0;
      final endMin = hEnd.isNotEmpty ? toMin(hEnd) : 23 * 60 + 59;
      if (startMin < 0 || endMin < 0) return false;
      // Overnight shift: end time wraps past midnight (e.g. 16:08 – 00:01)
      if (endMin < startMin) {
        return nowMin >= startMin || nowMin <= endMin;
      }
      return nowMin >= startMin && nowMin <= endMin;
    }

    final isActive = !locked && isWithinTimeRange();

    const kActiveAccent = Color(0xFF00897B);
    const kPastAccent = Color(0xFFF59E0B);
    const kLockedAccent = Color(0xFFF97316);

    final accentColor = locked
        ? kLockedAccent
        : (isActive ? kActiveAccent : kPastAccent);

    final hasJenis = (namaJenis ?? '').trim().isNotEmpty;
    final canChangeJenis = isToday && !locked;

    final statusLabel = locked
        ? 'Locked'
        : (isActive ? 'Sedang Berlangsung' : 'Sudah Lewat');
    final statusIcon = locked
        ? Icons.lock_outline
        : (isActive ? Icons.play_circle_outline : Icons.history_rounded);

    final jamText = (hStart.isNotEmpty || hEnd.isNotEmpty)
        ? '${hStart.isNotEmpty ? hStart : "--:--"} – ${hEnd.isNotEmpty ? hEnd : "--:--"}'
        : '-- : --';

    // Segmen info: ikon kecil + teks inline
    Widget infoTag(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    Widget vline() => Container(
      width: 1,
      height: 18,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              vline(),
              // Jenis produksi — teks saja
              Flexible(
                child: Text(
                  hasJenis ? namaJenis!.trim() : 'Belum ada jenis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasJenis ? accentColor : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Tombol Timeline + Ganti
              if (widget.idMesin != null &&
                  widget.shift != null &&
                  widget.tglProduksi != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: _openSplitDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ganti',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Material(
                color: _kBrokerPrimary,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: _openTimelineDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Riwayat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              vline(),
              // Shift · Jam · Tanggal
              if (tglText != null) ...[
                infoTag(Icons.calendar_today_outlined, tglText),
                dot(),
              ],
              if (widget.shift != null) ...[
                infoTag(Icons.group_outlined, 'Shift ${widget.shift}'),
                dot(),
              ],
              infoTag(Icons.schedule_outlined, jamText),
              const Spacer(),
              // noProduksi + refresh
              Text(
                widget.noProduksi,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 26,
                height: 26,
                child: IconButton(
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    final vm = context.read<BrokerProductionInputViewModel>();
                    vm.loadInputs(widget.noProduksi, force: true);
                    vm.loadOutputs(widget.noProduksi);
                    _showSnack('Data di-refresh');
                  },
                  icon: Icon(
                    Icons.refresh,
                    size: 15,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Handler untuk bulk delete
  Future<bool> _handleBulkDelete(List<dynamic> items) async {
    final vm = context.read<BrokerProductionInputViewModel>();

    final success = await vm.deleteItems(widget.noProduksi, items);

    if (!success && mounted) {
      final errMsg = vm.deleteError ?? 'Gagal menghapus item';
      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(title: 'Gagal Menghapus', message: errMsg),
      );
    }

    return success;
  }

  Future<void> _showTempCardOptions(String labelTitle) async {
    final vm = context.read<BrokerProductionInputViewModel>();

    final tempData = vm.getTemporaryDataForLabel(labelTitle);
    final isSakBased =
        tempData != null &&
        (tempData.brokerItems.isNotEmpty ||
            tempData.brokerPartials.isNotEmpty ||
            tempData.bbItems.isNotEmpty ||
            tempData.bbPartials.isNotEmpty ||
            tempData.washingItems.isNotEmpty ||
            tempData.mixerItems.isNotEmpty ||
            tempData.mixerPartials.isNotEmpty);
    // Partial not supported for Washing (B.) and Crusher (F.)
    final supportsPartial =
        tempData != null &&
        (tempData.brokerItems.isNotEmpty ||
            tempData.brokerPartials.isNotEmpty ||
            tempData.bbItems.isNotEmpty ||
            tempData.bbPartials.isNotEmpty ||
            tempData.gilinganItems.isNotEmpty ||
            tempData.gilinganPartials.isNotEmpty ||
            tempData.mixerItems.isNotEmpty ||
            tempData.mixerPartials.isNotEmpty ||
            tempData.rejectItems.isNotEmpty ||
            tempData.rejectPartials.isNotEmpty);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _TempCardOptionsDialog(
        labelTitle: labelTitle,
        showSebagian: isSakBased,
        showPartial: supportsPartial,
      ),
    );
    if (result == null || !mounted) return;

    if (result == 'delete') {
      vm.deleteTempItemsForLabel(labelTitle);
    } else if (result == 'select' || result == 'partial') {
      // Delete existing temp for this label so user can choose a subset/partial
      vm.deleteTempItemsForLabel(labelTitle);
      setState(() => _selectedMode = result);

      if (!mounted) return;

      // Reload lookup for this label (uses cache, no new scan needed)
      final lookupResult = await vm.lookupLabel(labelTitle);
      if (!mounted) return;

      if (lookupResult == null) {
        _showSnack(
          'Gagal memuat data label: ${vm.lookupError ?? "error tidak diketahui"}',
          backgroundColor: Colors.red,
        );
        return;
      }

      if (result == 'partial') {
        await _handlePartialMode(context, vm, lookupResult);
      } else {
        await _handleSelectMode(context, vm, lookupResult);
      }
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final vm = context.read<BrokerProductionInputViewModel>();

    if (vm.totalTempCount == 0) {
      _showSnack(
        'Tidak ada data untuk disimpan',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // 🔹 Dialog konfirmasi formal
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmSaveTempDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
      ),
    );

    if (confirm != true || !mounted) return;

    // Eksekusi submit → skeleton muncul dari state isSubmitting
    final success = await vm.submitTempItems(widget.noProduksi);

    if (!mounted) return;

    if (success) {
      _showSnack('✅ Data berhasil disimpan', backgroundColor: Colors.green);
    } else {
      final errMsg = vm.submitError ?? 'Kesalahan tidak diketahui';

      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(title: 'Gagal Menyimpan', message: errMsg),
      );
      // retry kalau mau, user tinggal tekan tombol Save lagi
    }
  }

  Future<String?> _onCodeReady(BuildContext context, String code) async {
    final vm = context.read<BrokerProductionInputViewModel>();

    // ✅ VALIDASI: Cek jika mode partial tidak support untuk washing/crusher
    if (_selectedMode == 'partial') {
      final normalized = code.trim().toUpperCase();
      final prefix = normalized.length >= 2 ? normalized.substring(0, 2) : '';

      if (prefix == 'B.' || prefix == 'F.') {
        final labelType = prefix == 'B.' ? 'Washing' : 'Crusher';

        // ✅ Tampilkan dialog informatif
        await PartialModeNotSupportedDialog.show(
          context: context,
          labelType: labelType,
          onOk: () {
            // Optional: Bisa tambahkan aksi setelah user klik OK
            // Misalnya log atau analytics
          },
        );

        return '$labelType tidak mendukung mode PARTIAL';
      }
    }

    // ✅ Lanjutkan proses lookup jika validasi OK
    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return 'Halaman sudah tidak aktif';

    if (vm.lookupError != null) {
      return 'Gagal ambil data: ${vm.lookupError}';
    }

    if (res == null || res.found == false || res.data.isEmpty) {
      return 'Label "$code" tidak memiliki data yang tersedia.';
    }

    // Auto-switch ke tab sesuai tipe label yang discan
    final tab = _tabForLookupResult(res);
    if (tab != null && tab != _selectedInputTab) {
      setState(() => _selectedInputTab = tab);
    }

    // ===== ROUTING BERDASARKAN MODE =====
    if (_selectedMode == 'full') {
      await _handleFullMode(context, vm, res);
    } else if (_selectedMode == 'partial') {
      await _handlePartialMode(context, vm, res);
    } else {
      await _handleSelectMode(context, vm, res);
    }

    return null;
  }

  /// MODE FULL: Langsung commit semua data tanpa dialog
  Future<void> _handleFullMode(
    BuildContext context,
    BrokerProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode!)}'
          : '';
      _showSnack(
        'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix',
      );
      return;
    }

    // Auto-select semua item baru (non-duplicate)
    vm.clearPicks();
    vm.pickAllNew(widget.noProduksi);

    // Commit langsung tanpa dialog
    final result = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

    final msg = result.added > 0
        ? '✅ Auto-added ${result.added} item${result.skipped > 0 ? ' • Duplikat terlewati ${result.skipped}' : ''}'
        : 'Tidak ada item baru ditambahkan';

    _showSnack(
      msg,
      backgroundColor: result.added > 0 ? Colors.green : Colors.orange,
    );
  }

  /// MODE PARTIAL: Dialog khusus untuk partial dengan radio button (single selection)
  Future<void> _handlePartialMode(
    BuildContext context,
    BrokerProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    // Non-sak items (gilingan/reject): langsung tanya berat saja
    final firstItem = res.typedItems.isNotEmpty ? res.typedItems.first : null;
    final isNonSak = firstItem is GilinganItem || firstItem is RejectItem;

    if (isNonSak && res.data.isNotEmpty) {
      final row = res.data.first;
      final beratRaw = row['berat'] ?? row['Berat'];
      final originalBerat = beratRaw != null
          ? (beratRaw as num).toDouble()
          : null;
      if (originalBerat == null || originalBerat <= 0) return;

      final newWeight = await WeightInputDialog.show(
        context,
        maxWeight: originalBerat,
        currentWeight: null,
      );
      if (!mounted || newWeight == null) return;

      final originalIsPartial = row['isPartial'];
      row['isPartial'] = true;
      row['IsPartial'] = true;
      row['berat'] = newWeight;
      row['Berat'] = newWeight;

      vm.clearPicks();
      vm.togglePick(row);
      final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

      row['berat'] = originalBerat;
      row['Berat'] = originalBerat;
      row['isPartial'] = originalIsPartial;
      row['IsPartial'] = originalIsPartial;

      _showSnack(
        r.added > 0
            ? '✅ Ditambahkan ${r.added} item partial'
            : 'Item sudah ada atau gagal ditambahkan',
        backgroundColor: r.added > 0 ? Colors.green : Colors.orange,
      );
      return;
    }

    // Sak-based: tampilkan dialog partial normal
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => LookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  /// MODE SELECT: Dialog dengan checkbox (default all selected untuk item baru)
  Future<void> _handleSelectMode(
    BuildContext context,
    BrokerProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    final freshCount = vm.countNewRowsInLastLookup(widget.noProduksi);

    if (freshCount == 0) {
      final labelCode = _labelCodeOfFirst(res);
      final hasTemp =
          labelCode != null && vm.hasTemporaryDataForLabel(labelCode);
      final suffix = hasTemp
          ? ' • ${vm.getTemporaryDataSummary(labelCode!)}'
          : '';
      _showSnack(
        'Semua item untuk ${labelCode ?? "label ini"} sudah ada.$suffix',
      );
      return;
    }

    // Tampilkan dialog biasa (dengan auto-select default)
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BrokerLookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: _selectedMode,
      ),
    );
  }

  String? _tabForLookupResult(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;
    if (item is BrokerItem) return 'broker';
    if (item is BbItem) return 'bb';
    if (item is WashingItem) return 'washing';
    if (item is CrusherItem) return 'crusher';
    if (item is GilinganItem) return 'gilingan';
    if (item is MixerItem) return 'mixer';
    if (item is RejectItem) return 'reject';
    return null;
  }

  String? _labelCodeOfFirst(ProductionLabelLookupResult res) {
    if (res.typedItems.isEmpty) return null;
    final item = res.typedItems.first;

    if (item is BrokerItem) {
      // ⬇️ TAMBAHKAN: Cek partial code terlebih dahulu
      return (item.noBrokerPartial ?? '').trim().isNotEmpty
          ? item.noBrokerPartial
          : item.noBroker;
    }
    if (item is BbItem) {
      final npart = (item.noBBPartial ?? '').trim();
      return npart.isNotEmpty ? npart : item.noBahanBaku;
    }
    if (item is WashingItem) return item.noWashing;
    if (item is CrusherItem) return item.noCrusher;
    if (item is GilinganItem) {
      return (item.noGilinganPartial ?? '').trim().isNotEmpty
          ? item.noGilinganPartial
          : item.noGilingan;
    }
    if (item is MixerItem) {
      return (item.noMixerPartial ?? '').trim().isNotEmpty
          ? item.noMixerPartial
          : item.noMixer;
    }
    if (item is RejectItem) {
      return (item.noRejectPartial ?? '').trim().isNotEmpty
          ? item.noRejectPartial
          : item.noReject;
    }
    return null;
  }

  Widget _buildInputPanel({
    required BuildContext buttonContext,
    required BrokerProductionInputViewModel vm,
    required bool locked,
    required bool isLookupLoading,
    required int labelCount,
    required Widget child,
  }) {
    return Container(
      decoration: _brokerPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: Row(
              children: [
                _brokerSectionHeader(Icons.input_rounded, 'Label Input'),
                const Spacer(),
                Material(
                  color: locked || isLookupLoading
                      ? Colors.grey.shade100
                      : _kBrokerPrimary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: locked || isLookupLoading
                        ? null
                        : () => _openScanDialog(),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          isLookupLoading
                              ? SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: locked
                                        ? Colors.grey.shade400
                                        : Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.qr_code_scanner,
                                  size: 15,
                                  color: locked
                                      ? Colors.grey.shade400
                                      : Colors.white,
                                ),
                          const SizedBox(width: 4),
                          Text(
                            'Scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: locked
                                  ? Colors.grey.shade400
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveButtonWithBadge(
                  count: vm.totalTempCount,
                  isLoading: vm.isSubmitting,
                  onPressed: () => _handleSave(context),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Hapus Semua Temp',
                  onPressed: vm.totalTempCount > 0
                      ? () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Hapus Semua Temp?'),
                              content: Text(
                                'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    vm.clearAllTempItems();
                                    Navigator.of(dialogContext).pop();
                                    _showSnack('Semua temp items dihapus');
                                  },
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.delete_sweep,
                    size: 20,
                    color: vm.totalTempCount > 0
                        ? Colors.red.shade700
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBrokerBorder),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection({
    required List<BrokerOutput> brokerOutputs,
    required List<BonggolanOutput> bonggolanOutputs,
    required bool isLoading,
    required String? error,
    required double grandInputBerat,
  }) {
    int totalSakBroker = 0;
    double totalBeratBroker = 0.0;
    for (final output in brokerOutputs) {
      totalSakBroker += output.totalSak;
      totalBeratBroker += output.totalBerat;
    }

    double totalBeratBonggolan = 0.0;
    for (final output in bonggolanOutputs) {
      totalBeratBonggolan += output.berat ?? 0.0;
    }

    final totalLabel = brokerOutputs.length + bonggolanOutputs.length;
    final isBrokerOutputTab = _selectedOutputTab == 'broker';
    final activeOutputLabel = isBrokerOutputTab ? 'Broker' : 'Bonggolan';
    final selectedTabChild = _selectedOutputTab == 'broker'
        ? _OutputCategoryContent(
            footer: _BrokerOutputSummaryTile(
              totalLabel: brokerOutputs.length,
              totalSak: totalSakBroker,
              totalBerat: totalBeratBroker,
            ),
            child: brokerOutputs.isEmpty
                ? const _EmptyOutputCategory(message: 'Belum ada output broker')
                : LayoutBuilder(
                    builder: (_, c) => GridView(
                      padding: const EdgeInsets.all(6),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        mainAxisExtent: 78,
                      ),
                      children: brokerOutputs
                          .map((output) => _BrokerOutputTile(output: output))
                          .toList(),
                    ),
                  ),
          )
        : _OutputCategoryContent(
            footer: _BonggolanOutputSummaryTile(
              totalLabel: bonggolanOutputs.length,
              totalBerat: totalBeratBonggolan,
            ),
            child: bonggolanOutputs.isEmpty
                ? const _EmptyOutputCategory(
                    message: 'Belum ada output bonggolan',
                  )
                : LayoutBuilder(
                    builder: (_, c) => GridView(
                      padding: const EdgeInsets.all(6),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        mainAxisExtent: 72,
                      ),
                      children: bonggolanOutputs
                          .map((output) => _BonggolanOutputTile(output: output))
                          .toList(),
                    ),
                  ),
          );

    return Container(
      decoration: _brokerPanelDecoration(
        borderColor: _kBrokerOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                _brokerSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kBrokerOutput,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBrokerBorder),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          _OutputErrorBanner(message: error),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _FolderTabBar(
                                selectedValue: _selectedOutputTab,
                                accentColor: _kBrokerOutput,
                                tabs: [
                                  _PanelTabItem(
                                    value: 'broker',
                                    label: 'Broker',
                                    count: brokerOutputs.length,
                                  ),
                                  _PanelTabItem(
                                    value: 'bonggolan',
                                    label: 'Bonggolan',
                                    count: bonggolanOutputs.length,
                                  ),
                                ],
                                onChanged: (value) {
                                  if (_selectedOutputTab == value) return;
                                  setState(() => _selectedOutputTab = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: _InputCategoryBlock(
                            color: _kBrokerOutput,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _OutputActionButton(
                                      icon: Icons.add,
                                      label: 'Tambah $activeOutputLabel',
                                      color: _kBrokerOutput,
                                      onTap: () async {
                                        if (grandInputBerat == 0) {
                                          if (!context.mounted) return;
                                          showDialog<void>(
                                            context: context,
                                            builder: (_) => ErrorStatusDialog(
                                              title: 'Belum Ada Input',
                                              message:
                                                  'Masukkan label input terlebih dahulu sebelum membuat output.',
                                            ),
                                          );
                                          return;
                                        }

                                        final totalOutputBerat =
                                            totalBeratBroker +
                                            totalBeratBonggolan;

                                        if (totalOutputBerat >=
                                            grandInputBerat) {
                                          if (!context.mounted) return;
                                          showDialog<void>(
                                            context: context,
                                            builder: (_) => ErrorStatusDialog(
                                              title:
                                                  'Berat Output Melebihi Input',
                                              message:
                                                  'Total berat output (${num2(totalOutputBerat)} kg) sudah mencapai atau melebihi total berat input (${num2(grandInputBerat)} kg).\n\nTidak dapat menambah output baru.',
                                            ),
                                          );
                                          return;
                                        }

                                        if (isBrokerOutputTab) {
                                          if (widget.outputJenisId != null) {
                                            await showDialog<void>(
                                              context: context,
                                              builder: (_) =>
                                                  BrokerProductionOutputFormDialog(
                                                    noProduksi:
                                                        widget.noProduksi,
                                                    tglProduksi:
                                                        widget.tglProduksi,
                                                    outputJenisId:
                                                        widget.outputJenisId!,
                                                    outputJenisNama:
                                                        widget.namaJenis ?? '',
                                                    namaMesin: widget.namaMesin,
                                                  ),
                                            );
                                          } else {
                                            await showDialog<void>(
                                              context: context,
                                              builder: (_) => BrokerFormDialog(
                                                preselectNoProduksi:
                                                    widget.noProduksi,
                                                preselectNamaMesin:
                                                    widget.namaMesin,
                                                preselectDate:
                                                    widget.tglProduksi,
                                              ),
                                            );
                                          }
                                        } else {
                                          await showDialog<void>(
                                            context: context,
                                            builder: (_) =>
                                                BonggolanProductionOutputFormDialog(
                                                  noProduksi: widget.noProduksi,
                                                  tglProduksi:
                                                      widget.tglProduksi,
                                                  namaMesin: widget.namaMesin,
                                                ),
                                          );
                                        }

                                        if (!mounted) return;
                                        final vm = context
                                            .read<
                                              BrokerProductionInputViewModel
                                            >();
                                        await vm.loadOutputs(widget.noProduksi);

                                        // Post-add warning if now exceeded
                                        if (!mounted) return;
                                        final newBrokerBerat = vm
                                            .outputsOf(widget.noProduksi)
                                            .fold<double>(
                                              0.0,
                                              (s, o) => s + o.totalBerat,
                                            );
                                        final newBonggolanBerat = vm
                                            .bonggolanOutputsOf(
                                              widget.noProduksi,
                                            )
                                            .fold<double>(
                                              0.0,
                                              (s, o) => s + (o.berat ?? 0.0),
                                            );
                                        final newTotal =
                                            newBrokerBerat + newBonggolanBerat;
                                        if (grandInputBerat > 0 &&
                                            newTotal > grandInputBerat) {
                                          _showSnack(
                                            '⚠️ Total berat output (${num2(newTotal)} kg) melebihi total berat input (${num2(grandInputBerat)} kg)',
                                            backgroundColor: Colors.orange,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SizedBox(
                                        width: constraints.maxWidth,
                                        child: selectedTabChild,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _OutputGrandTotalBar(
                                  totalLabel: totalLabel,
                                  totalSak: totalSakBroker,
                                  totalBerat:
                                      totalBeratBroker + totalBeratBonggolan,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static bool _boolish(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
  }

  static bool _isPartialOf(dynamic item, Map<String, dynamic> row) {
    if (_boolish(row['isPartial']) || _boolish(row['IsPartial'])) return true;

    try {
      if (item is BbItem && item.isPartialRow == true) return true;
      final dynamic dyn = item;
      final hasIsPartial = (dyn as dynamic?)?.isPartial;
      if (hasIsPartial is bool && hasIsPartial) return true;
    } catch (_) {}
    return false;
  }

  Widget _buildSelectedInputTabChild({
    required Map<String, List<BrokerItem>> brokerGroups,
    required Map<String, List<BbItem>> bbGroups,
    required Map<String, List<WashingItem>> washingGroups,
    required Map<String, List<CrusherItem>> crusherGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    required Map<String, List<MixerItem>> mixerGroups,
    required Map<String, List<RejectItem>> rejectGroups,
    required BrokerProductionInputViewModel vm,
    required bool canDelete,
  }) {
    _InputCategorySummaryTile summaryFor({
      required int totalData,
      required int totalSak,
      required double totalBerat,
    }) {
      return _InputCategorySummaryTile(
        summary: SectionSummary(
          totalData: totalData,
          totalSak: totalSak,
          totalBerat: totalBerat,
        ),
        accentColor: _kBrokerPrimary,
      );
    }

    Widget grid;
    Widget? footer;

    if (_selectedInputTab == 'broker') {
      int totalSak = 0;
      double totalBerat = 0.0;
      for (final entry in brokerGroups.entries) {
        for (final item in entry.value) {
          totalSak += 1;
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: brokerGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      );
      grid = brokerGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: brokerGroups.entries.map((entry) {
                  final hasPartial = entry.value.any((x) => x.isPartialRow);
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    expandable: !hasPartial,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? (entry.value
                                  .firstWhere((x) => x.isPartialRow)
                                  .noBroker
                                  ?.toString() ??
                              '-')
                        : null,
                    detailsBuilder: () => [],
                    chipItemsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final dbItems = currentInputs == null
                          ? <BrokerItem>[]
                          : currentInputs.broker.where(
                              (x) => brokerTitleKey(x) == entry.key,
                            );
                      final tempFull = vm.tempBroker.where(
                        (x) => brokerTitleKey(x) == entry.key,
                      );
                      final tempPart = vm.tempBrokerPartial.where(
                        (x) => brokerTitleKey(x) == entry.key,
                      );
                      final items = <BrokerItem>[
                        ...tempPart,
                        ...dbItems,
                        ...tempFull,
                      ];
                      return items.map((item) {
                        final isTemp =
                            vm.tempBroker.contains(item) ||
                            vm.tempBrokerPartial.contains(item);
                        return _InputSakChip(
                          label: 'Sak ${item.noSak ?? '-'}',
                          berat: item.berat,
                          isTemp: isTemp,
                          isPartial: item.isPartialRow,
                          onDelete: isTemp
                              ? () => vm.deleteTempBrokerItem(item)
                              : null,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else if (_selectedInputTab == 'bb') {
      int totalSak = 0;
      double totalBerat = 0.0;
      for (final entry in bbGroups.entries) {
        for (final item in entry.value) {
          totalSak += 1;
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: bbGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      );
      grid = bbGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: bbGroups.entries.map((entry) {
                  final hasPartial = entry.value.any((x) => x.isPartialRow);
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    expandable: !hasPartial,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? bbPairLabel(
                            entry.value.firstWhere((x) => x.isPartialRow),
                          )
                        : null,
                    detailsBuilder: () => [],
                    chipItemsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final dbItems = currentInputs == null
                          ? <BbItem>[]
                          : currentInputs.bb.where(
                              (x) => bbTitleKey(x) == entry.key,
                            );
                      final tempFull = vm.tempBb.where(
                        (x) => bbTitleKey(x) == entry.key,
                      );
                      final tempPart = vm.tempBbPartial.where(
                        (x) => bbTitleKey(x) == entry.key,
                      );
                      final items = [...tempPart, ...dbItems, ...tempFull];
                      return items.map((item) {
                        final isTemp =
                            vm.tempBb.contains(item) ||
                            vm.tempBbPartial.contains(item);
                        return _InputSakChip(
                          label: 'Sak ${item.noSak ?? '-'}',
                          berat: item.berat,
                          isTemp: isTemp,
                          isPartial: item.isPartialRow,
                          onDelete: isTemp
                              ? () => vm.deleteTempBbItem(item)
                              : null,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else if (_selectedInputTab == 'washing') {
      int totalSak = 0;
      double totalBerat = 0.0;
      for (final entry in washingGroups.entries) {
        for (final item in entry.value) {
          totalSak += 1;
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: washingGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      );
      grid = washingGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: washingGroups.entries.map((entry) {
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    detailsBuilder: () => [],
                    chipItemsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final items = [
                        if (currentInputs != null)
                          ...currentInputs.washing.where(
                            (x) => (x.noWashing ?? '-') == entry.key,
                          ),
                        ...vm.tempWashing.where(
                          (x) => (x.noWashing ?? '-') == entry.key,
                        ),
                      ];
                      return items.map((item) {
                        final isTemp = vm.tempWashing.contains(item);
                        return _InputSakChip(
                          label: 'Sak ${item.noSak ?? '-'}',
                          berat: item.berat,
                          isTemp: isTemp,
                          onDelete: isTemp
                              ? () => vm.deleteTempWashingItem(item)
                              : null,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else if (_selectedInputTab == 'crusher') {
      double totalBerat = 0.0;
      for (final entry in crusherGroups.entries) {
        for (final item in entry.value) {
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: crusherGroups.length,
        totalSak: 0,
        totalBerat: totalBerat,
      );
      grid = crusherGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: crusherGroups.entries.map((entry) {
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    detailsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final items = [
                        if (currentInputs != null)
                          ...currentInputs.crusher.where(
                            (x) => (x.noCrusher ?? '-') == entry.key,
                          ),
                        ...vm.tempCrusher.where(
                          (x) => (x.noCrusher ?? '-') == entry.key,
                        ),
                      ];
                      return items.map((item) {
                        final isTemp = vm.tempCrusher.contains(item);
                        return TooltipTableRow(
                          columns: ['${num2(item.berat)} kg'],
                          showDelete: isTemp,
                          onDelete: isTemp
                              ? () => vm.deleteTempCrusherItem(item)
                              : null,
                          isTempRow: isTemp,
                          isHighlighted: isTemp,
                          isDisabled: !isTemp && !canDelete,
                          itemData: item,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else if (_selectedInputTab == 'gilingan') {
      double totalBerat = 0.0;
      for (final entry in gilinganGroups.entries) {
        for (final item in entry.value) {
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: gilinganGroups.length,
        totalSak: 0,
        totalBerat: totalBerat,
      );
      grid = gilinganGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: gilinganGroups.entries.map((entry) {
                  final hasPartial = entry.value.any((x) => x.isPartialRow);
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    expandable: !hasPartial,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? (entry.value
                                  .firstWhere((x) => x.isPartialRow)
                                  .noGilingan ??
                              '-')
                        : null,
                    detailsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final dbItems = currentInputs == null
                          ? <GilinganItem>[]
                          : currentInputs.gilingan.where(
                              (x) => gilinganTitleKey(x) == entry.key,
                            );
                      final tempFull = vm.tempGilingan.where(
                        (x) => gilinganTitleKey(x) == entry.key,
                      );
                      final tempPart = vm.tempGilinganPartial.where(
                        (x) => gilinganTitleKey(x) == entry.key,
                      );
                      final items = [...tempPart, ...dbItems, ...tempFull];
                      return items.map((item) {
                        final isTemp =
                            vm.tempGilingan.contains(item) ||
                            vm.tempGilinganPartial.contains(item);
                        final columns = item.isPartialRow
                            ? <String>[
                                (item.noGilingan ?? '-'),
                                '${num2(item.berat)} kg',
                              ]
                            : <String>['${num2(item.berat)} kg'];
                        return TooltipTableRow(
                          columns: columns,
                          showDelete: isTemp,
                          onDelete: isTemp
                              ? () => vm.deleteTempGilinganItem(item)
                              : null,
                          isTempRow: isTemp,
                          isHighlighted: isTemp,
                          isDisabled: !isTemp && !canDelete,
                          itemData: item,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else if (_selectedInputTab == 'mixer') {
      int totalSak = 0;
      double totalBerat = 0.0;
      for (final entry in mixerGroups.entries) {
        for (final item in entry.value) {
          totalSak += 1;
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: mixerGroups.length,
        totalSak: totalSak,
        totalBerat: totalBerat,
      );
      grid = mixerGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: mixerGroups.entries.map((entry) {
                  final hasPartial = entry.value.any((x) => x.isPartialRow);
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (Icons.inventory_2_outlined, '${entry.value.length} sak'),
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    expandable: !hasPartial,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? (entry.value
                                  .firstWhere((x) => x.isPartialRow)
                                  .noMixer ??
                              '-')
                        : null,
                    detailsBuilder: () => [],
                    chipItemsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final dbItems = currentInputs == null
                          ? <MixerItem>[]
                          : currentInputs.mixer
                                .where((x) => mixerTitleKey(x) == entry.key)
                                .toList();
                      final tempFull = vm.tempMixer
                          .where((x) => mixerTitleKey(x) == entry.key)
                          .toList();
                      final tempPart = vm.tempMixerPartial
                          .where((x) => mixerTitleKey(x) == entry.key)
                          .toList();
                      final items = [...tempPart, ...dbItems, ...tempFull];
                      return items.map((item) {
                        final isTemp =
                            vm.tempMixer.contains(item) ||
                            vm.tempMixerPartial.contains(item);
                        return _InputSakChip(
                          label: 'Sak ${item.noSak ?? '-'}',
                          berat: item.berat,
                          isTemp: isTemp,
                          isPartial: item.isPartialRow,
                          onDelete: isTemp
                              ? () => vm.deleteTempMixerItem(item)
                              : null,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    } else {
      // reject
      double totalBerat = 0.0;
      for (final entry in rejectGroups.entries) {
        for (final item in entry.value) {
          totalBerat += item.berat ?? 0.0;
        }
      }
      footer = summaryFor(
        totalData: rejectGroups.length,
        totalSak: 0,
        totalBerat: totalBerat,
      );
      grid = rejectGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : LayoutBuilder(
              builder: (_, c) => GridView(
                padding: const EdgeInsets.all(6),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: c.maxWidth < 380 ? 2 : 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  mainAxisExtent: 72,
                ),
                children: rejectGroups.entries.map((entry) {
                  final hasPartial = entry.value.any((x) => x.isPartialRow);
                  return _InputGroupExpansionTile(
                    title: entry.key,
                    headerSubtitle:
                        (entry.value.isNotEmpty
                            ? entry.value.first.namaJenis
                            : '-') ??
                        '-',
                    tileMetrics: [
                      (
                        Icons.scale_outlined,
                        '${num2(entry.value.fold<double>(0.0, (sum, item) => sum + (item.berat ?? 0.0)))} kg',
                      ),
                    ],
                    color: Colors.blue,
                    onLongPress: vm.hasTemporaryDataForLabel(entry.key)
                        ? () => _showTempCardOptions(entry.key)
                        : null,
                    isPartialGroup: hasPartial,
                    partialReference: hasPartial
                        ? (entry.value
                                  .firstWhere((x) => x.isPartialRow)
                                  .noReject ??
                              '-')
                        : null,
                    detailsBuilder: () {
                      final currentInputs = vm.inputsOf(widget.noProduksi);
                      final dbItems = currentInputs == null
                          ? <RejectItem>[]
                          : currentInputs.reject.where(
                              (x) => rejectTitleKey(x) == entry.key,
                            );
                      final tempFull = vm.tempReject.where(
                        (x) => rejectTitleKey(x) == entry.key,
                      );
                      final tempPart = vm.tempRejectPartial.where(
                        (x) => rejectTitleKey(x) == entry.key,
                      );
                      final items = [...tempPart, ...dbItems, ...tempFull];
                      return items.map((item) {
                        final isTemp =
                            vm.tempReject.contains(item) ||
                            vm.tempRejectPartial.contains(item);
                        final columns = item.isPartialRow
                            ? <String>[
                                (item.noReject ?? '-'),
                                '${num2(item.berat)} kg',
                              ]
                            : <String>['${num2(item.berat)} kg'];
                        return TooltipTableRow(
                          columns: columns,
                          showDelete: isTemp,
                          onDelete: isTemp
                              ? () => vm.deleteTempRejectItem(item)
                              : null,
                          isTempRow: isTemp,
                          isHighlighted: isTemp,
                          isDisabled: !isTemp && !canDelete,
                          itemData: item,
                        );
                      }).toList();
                    },
                  );
                }).toList(),
              ),
            );
    }

    return _OutputCategoryContent(footer: footer, child: grid);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final outputLoading = vm.isOutputsLoading(widget.noProduksi);
        final outputErr = vm.outputsError(widget.noProduksi);
        final outputs = vm.outputsOf(widget.noProduksi);
        final bonggolanOutputs = vm.bonggolanOutputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = widget.isLocked == true;

        final canDeleteByPerm = perm.can('label_broker:delete');
        final canDelete = canDeleteByPerm && !locked;

        // ✅ WRAP dengan WillPopScope untuk intercept back button
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: _kBrokerSurface,
            resizeToAvoidBottomInset: false,
            body: Builder(
              builder: (_) {
                if (err != null) {
                  return Center(child: Text('Gagal memuat inputs:\n$err'));
                }

                // ===== MERGE DB + TEMP (termasuk PARTIAL) =====
                final brokerAll = loading
                    ? <BrokerItem>[]
                    : [
                        ...vm.tempBroker.reversed,
                        ...vm.tempBrokerPartial.reversed,
                        ...?inputs?.broker,
                      ];
                final bbAll = loading
                    ? <BbItem>[]
                    : [
                        ...vm.tempBb.reversed,
                        ...vm.tempBbPartial.reversed,
                        ...?inputs?.bb,
                      ];
                final washingAll = loading
                    ? <WashingItem>[]
                    : [...vm.tempWashing, ...?inputs?.washing];
                final crusherAll = loading
                    ? <CrusherItem>[]
                    : [...vm.tempCrusher, ...?inputs?.crusher];
                final gilinganAll = loading
                    ? <GilinganItem>[]
                    : [
                        ...vm.tempGilingan.reversed,
                        ...vm.tempGilinganPartial.reversed,
                        ...?inputs?.gilingan,
                      ];
                final mixerAll = loading
                    ? <MixerItem>[]
                    : [
                        ...vm.tempMixer.reversed,
                        ...vm.tempMixerPartial.reversed,
                        ...?inputs?.mixer,
                      ];
                final rejectAll = loading
                    ? <RejectItem>[]
                    : [
                        ...vm.tempReject.reversed,
                        ...vm.tempRejectPartial.reversed,
                        ...?inputs?.reject,
                      ];

                // ===== GROUPED (key = titleKey yang sudah handle partial) =====
                final brokerGroups = groupBy(brokerAll, brokerTitleKey);
                final bbGroups = groupBy(bbAll, bbTitleKey);
                final washingGroups = groupBy(
                  washingAll,
                  (WashingItem e) => e.noWashing ?? '-',
                );
                final crusherGroups = groupBy(
                  crusherAll,
                  (CrusherItem e) => e.noCrusher ?? '-',
                );
                final gilinganGroups = groupBy(gilinganAll, gilinganTitleKey);
                final mixerGroups = groupBy(mixerAll, mixerTitleKey);
                final rejectGroups = groupBy(rejectAll, rejectTitleKey);

                final locked = widget.isLocked == true;
                final closed = widget.lastClosedDate; // boleh null

                return Column(
                  children: [
                    _buildWorkspaceToolbar(
                      locked: locked,
                      namaJenis: widget.namaJenis,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, outerConstraints) {
                          final isWide = outerConstraints.maxWidth >= 800;

                          // ── build input panel ──────────────────────────
                          final inputPanelWidget = Builder(
                            builder: (buttonContext) => _buildInputPanel(
                              buttonContext: buttonContext,
                              vm: vm,
                              locked: locked,
                              isLookupLoading: vm.isLookupLoading,
                              labelCount:
                                  brokerGroups.length +
                                  bbGroups.length +
                                  washingGroups.length +
                                  crusherGroups.length +
                                  gilinganGroups.length +
                                  mixerGroups.length +
                                  rejectGroups.length,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _FolderTabBar(
                                    selectedValue: _selectedInputTab,
                                    accentColor: _kBrokerPrimary,
                                    tabs: [
                                      _PanelTabItem(
                                        value: 'broker',
                                        label: 'Broker',
                                        count: brokerGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'bb',
                                        label: 'Bahan Baku',
                                        count: bbGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'washing',
                                        label: 'Washing',
                                        count: washingGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'crusher',
                                        label: 'Crusher',
                                        count: crusherGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'gilingan',
                                        label: 'Gilingan',
                                        count: gilinganGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'mixer',
                                        label: 'Mixer',
                                        count: mixerGroups.length,
                                      ),
                                      _PanelTabItem(
                                        value: 'reject',
                                        label: 'Reject',
                                        count: rejectGroups.length,
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (_selectedInputTab == value) return;
                                      setState(() => _selectedInputTab = value);
                                    },
                                  ),
                                  Expanded(
                                    child: _InputCategoryBlock(
                                      color: _kBrokerPrimary,
                                      isLoading: loading,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return SizedBox(
                                                  width: constraints.maxWidth,
                                                  child:
                                                      _buildSelectedInputTabChild(
                                                        brokerGroups:
                                                            brokerGroups,
                                                        bbGroups: bbGroups,
                                                        washingGroups:
                                                            washingGroups,
                                                        crusherGroups:
                                                            crusherGroups,
                                                        gilinganGroups:
                                                            gilinganGroups,
                                                        mixerGroups:
                                                            mixerGroups,
                                                        rejectGroups:
                                                            rejectGroups,
                                                        vm: vm,
                                                        canDelete: canDelete,
                                                      ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Builder(
                                            builder: (context) {
                                              double grandBerat = 0.0;
                                              int grandSak =
                                                  brokerAll.length +
                                                  bbAll.length +
                                                  washingAll.length +
                                                  mixerAll.length;
                                              for (final i in brokerAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in bbAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in washingAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in crusherAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in gilinganAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in mixerAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              for (final i in rejectAll) {
                                                grandBerat += i.berat ?? 0.0;
                                              }
                                              return _InputGrandTotalBar(
                                                totalLabel:
                                                    brokerGroups.length +
                                                    bbGroups.length +
                                                    washingGroups.length +
                                                    crusherGroups.length +
                                                    gilinganGroups.length +
                                                    mixerGroups.length +
                                                    rejectGroups.length,
                                                totalSak: grandSak,
                                                totalBerat: grandBerat,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // ── build output panel ─────────────────────────
                          double grandInputBerat = 0.0;
                          for (final i in brokerAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in bbAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in washingAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in crusherAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in gilinganAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in mixerAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }
                          for (final i in rejectAll) {
                            grandInputBerat += i.berat ?? 0.0;
                          }

                          final outputPanelWidget = _buildOutputSection(
                            brokerOutputs: outputs,
                            bonggolanOutputs: bonggolanOutputs,
                            isLoading: outputLoading,
                            error: outputErr,
                            grandInputBerat: grandInputBerat,
                          );

                          // ── responsive layout ──────────────────────────
                          if (isWide) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: inputPanelWidget),
                                  const SizedBox(width: 16),
                                  Expanded(child: outputPanelWidget),
                                ],
                              ),
                            );
                          }

                          // narrow: stacked, each panel gets half height
                          final panelH =
                              (outerConstraints.maxHeight - 16 - 32) / 2;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: panelH,
                                  child: inputPanelWidget,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: panelH,
                                  child: outputPanelWidget,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BrokerOutputTile extends StatelessWidget {
  final BrokerOutput output;

  const _BrokerOutputTile({required this.output});

  Future<void> _handlePrint(BuildContext context) async {
    final noBroker = (output.noBroker ?? '').trim();
    if (noBroker.isEmpty) return;

    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    final lockApi = LabelPrintLockApi();
    final repo = BrokerRepository(api: ApiClient());
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    var isLockAcquired = false;
    var isPrinted = false;

    try {
      await lockApi.acquire(noBroker);
      isLockAcquired = true;

      await PdfPrintService(defaultSystem: 'pps').previewFromUrl(
        context: rootCtx,
        pdfUrl: Uri.parse(ApiConstants.brokerLabelPdf(noBroker)),
        title: noBroker,
        onPrinted: () {
          isPrinted = true;
          () async {
            var needsIncrement = false;
            var needsRelease = false;

            try {
              final count = await repo.markAsPrinted(noBroker);
              if (count != null) {
                lockVm.setPrintCount(noBroker, count);
              }
            } catch (_) {
              needsIncrement = true;
            }

            try {
              await lockApi.release(noBroker);
            } catch (_) {
              needsRelease = true;
            }

            if (needsIncrement || needsRelease) {
              await queue.enqueue(
                feature: 'broker',
                noLabel: noBroker,
                needsIncrement: needsIncrement,
                needsReleaseLock: needsRelease,
              );
            }
          }().ignore();
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (isLockAcquired && !isPrinted) {
        () async {
          try {
            await lockApi.release(noBroker);
          } catch (_) {
            await queue.enqueue(
              feature: 'broker',
              noLabel: noBroker,
              needsReleaseLock: true,
            );
          }
        }().ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBrokerBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => _BrokerOutputDetailDialog(
              output: output,
              onPrint: () => _handlePrint(context),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title row: noBroker + print count
              Row(
                children: [
                  Expanded(
                    child: Text(
                      output.noBroker ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.print_outlined,
                    size: 11,
                    color: output.printedCount > 0
                        ? _kBrokerOutput
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'x${output.printedCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: output.printedCount > 0
                          ? _kBrokerOutput
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                output.namaJenis ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              // Metrics
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  _MiniMetric(
                    icon: Icons.inventory_2_outlined,
                    text: '${output.totalSak} sak',
                  ),
                  _MiniMetric(
                    icon: Icons.scale_outlined,
                    text: '${num2(output.totalBerat)} kg',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonggolanOutputTile extends StatelessWidget {
  final BonggolanOutput output;

  const _BonggolanOutputTile({required this.output});

  Future<void> _handlePrint(BuildContext context) async {
    final noBonggolan = (output.noBonggolan ?? '').trim();
    if (noBonggolan.isEmpty) return;

    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    final lockApi = LabelPrintLockApi();
    final repo = BonggolanRepository();
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    var isLockAcquired = false;
    var isPrinted = false;

    try {
      await lockApi.acquire(noBonggolan);
      isLockAcquired = true;

      await PdfPrintService(defaultSystem: 'pps').previewFromUrl(
        context: rootCtx,
        pdfUrl: Uri.parse(ApiConstants.bonggolanLabelPdf(noBonggolan)),
        title: noBonggolan,
        onPrinted: () {
          isPrinted = true;
          () async {
            var needsIncrement = false;
            var needsRelease = false;

            try {
              final count = await repo.markAsPrinted(noBonggolan);
              if (count != null) {
                lockVm.setPrintCount(noBonggolan, count);
              }
            } catch (_) {
              needsIncrement = true;
            }

            try {
              await lockApi.release(noBonggolan);
            } catch (_) {
              needsRelease = true;
            }

            if (needsIncrement || needsRelease) {
              await queue.enqueue(
                feature: 'bonggolan',
                noLabel: noBonggolan,
                needsIncrement: needsIncrement,
                needsReleaseLock: needsRelease,
              );
            }
          }().ignore();
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (isLockAcquired && !isPrinted) {
        () async {
          try {
            await lockApi.release(noBonggolan);
          } catch (_) {
            await queue.enqueue(
              feature: 'bonggolan',
              noLabel: noBonggolan,
              needsReleaseLock: true,
            );
          }
        }().ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBrokerBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => _BonggolanOutputDetailDialog(
              output: output,
              onPrint: () => _handlePrint(context),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      output.noBonggolan ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.print_outlined,
                    size: 11,
                    color: output.printedCount > 0
                        ? _kBrokerOutput
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'x${output.printedCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: output.printedCount > 0
                          ? _kBrokerOutput
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                output.namaBonggolan ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              _MiniMetric(
                icon: Icons.scale_outlined,
                text: '${num2(output.berat)} kg',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokerOutputSummaryTile extends StatelessWidget {
  final int totalLabel;
  final int totalSak;
  final double totalBerat;

  const _BrokerOutputSummaryTile({
    required this.totalLabel,
    required this.totalSak,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kBrokerOutput.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBrokerOutput.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _InlineStat(
            label: 'Label',
            value: '$totalLabel',
            color: _kBrokerOutput,
          ),
          const SizedBox(width: 10),
          _InlineStat(label: 'Sak', value: '$totalSak', color: _kBrokerOutput),
          const SizedBox(width: 10),
          _InlineStat(
            label: 'Berat',
            value: '${num2(totalBerat)} kg',
            color: _kBrokerOutput,
          ),
        ],
      ),
    );
  }
}

class _OutputActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutputActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputGrandTotalBar extends StatelessWidget {
  final int totalLabel;
  final int totalSak;
  final double totalBerat;

  const _OutputGrandTotalBar({
    required this.totalLabel,
    required this.totalSak,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              const Icon(
                Icons.summarize_outlined,
                size: 13,
                color: _kBrokerOutput,
              ),
              const SizedBox(width: 5),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kBrokerOutput,
                ),
              ),
              const SizedBox(width: 10),
              _InlineStat(
                label: 'Label',
                value: '$totalLabel',
                color: _kBrokerOutput,
              ),
              const SizedBox(width: 10),
              _InlineStat(
                label: 'Sak',
                value: '$totalSak',
                color: _kBrokerOutput,
              ),
              const SizedBox(width: 10),
              _InlineStat(
                label: 'Berat',
                value: '${num2(totalBerat)} kg',
                color: _kBrokerOutput,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BonggolanOutputSummaryTile extends StatelessWidget {
  final int totalLabel;
  final double totalBerat;

  const _BonggolanOutputSummaryTile({
    required this.totalLabel,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kBrokerOutput.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBrokerOutput.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _InlineStat(
            label: 'Label',
            value: '$totalLabel',
            color: _kBrokerOutput,
          ),
          const SizedBox(width: 10),
          _InlineStat(
            label: 'Berat',
            value: '${num2(totalBerat)} kg',
            color: _kBrokerOutput,
          ),
        ],
      ),
    );
  }
}

class _OutputCategoryContent extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const _OutputCategoryContent({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        if (footer != null) ...[const SizedBox(height: 10), footer!],
      ],
    );
  }
}

class _InputCategoryBlock extends StatelessWidget {
  final Color color;
  final bool isLoading;
  final String? label;
  final SectionSummary Function()? summaryBuilder;
  final Widget child;

  const _InputCategoryBlock({
    required this.color,
    required this.child,
    this.isLoading = false,
    this.label,
    this.summaryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final summary = summaryBuilder?.call();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) ...[
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(child: child),
          if (summary != null) ...[
            const SizedBox(height: 10),
            _InputCategorySummaryTile(summary: summary, accentColor: color),
          ],
        ],
      ),
    );
  }
}

class _InputGrandTotalBar extends StatelessWidget {
  final int totalLabel;
  final int totalSak;
  final double totalBerat;

  const _InputGrandTotalBar({
    required this.totalLabel,
    required this.totalSak,
    required this.totalBerat,
  });

  @override
  Widget build(BuildContext context) {
    const color = _kBrokerPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              const Icon(Icons.summarize_outlined, size: 13, color: color),
              const SizedBox(width: 5),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              _InlineStat(label: 'Label', value: '$totalLabel', color: color),
              const SizedBox(width: 10),
              _InlineStat(label: 'Sak', value: '$totalSak', color: color),
              const SizedBox(width: 10),
              _InlineStat(
                label: 'Berat',
                value: '${num2(totalBerat)} kg',
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InlineStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InputCategorySummaryTile extends StatelessWidget {
  final SectionSummary summary;
  final Color accentColor;

  const _InputCategorySummaryTile({
    required this.summary,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _InlineStat(
            label: 'Label',
            value: '${summary.totalData}',
            color: accentColor,
          ),
          if (summary.totalSak > 0) ...[
            const SizedBox(width: 10),
            _InlineStat(
              label: 'Sak',
              value: '${summary.totalSak}',
              color: accentColor,
            ),
          ],
          const SizedBox(width: 10),
          _InlineStat(
            label: 'Berat',
            value: '${num2(summary.totalBerat)} kg',
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

class _InputSakChip {
  final String label;
  final double? berat;
  final bool isTemp;
  final bool isPartial;
  final VoidCallback? onDelete;

  const _InputSakChip({
    required this.label,
    this.berat,
    this.isTemp = false,
    this.isPartial = false,
    this.onDelete,
  });
}

class _InputGroupExpansionTile extends StatelessWidget {
  final String title;
  final String? headerSubtitle;
  final List<(IconData, String)> tileMetrics;
  final Color color;
  final List<Widget> Function() detailsBuilder;
  final List<_InputSakChip> Function()? chipItemsBuilder;
  final bool expandable;
  final bool isPartialGroup;
  final String? partialReference;
  final VoidCallback? onLongPress;

  const _InputGroupExpansionTile({
    required this.title,
    required this.color,
    required this.detailsBuilder,
    this.chipItemsBuilder,
    this.headerSubtitle,
    this.tileMetrics = const [],
    this.expandable = true,
    this.isPartialGroup = false,
    this.partialReference,
    this.onLongPress,
  });

  Widget _buildHeader(bool hasTempForThis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: hasTempForThis
                              ? Colors.brown.shade800
                              : const Color(0xFF1A1D23),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPartialGroup) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'P',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((headerSubtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    headerSubtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
                if (tileMetrics.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: tileMetrics
                        .map((m) => _MiniMetric(icon: m.$1, text: m.$2))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrokerProductionInputViewModel>();
    final hasTempForThis = vm.hasTemporaryDataForLabel(title);

    final bgColor = hasTempForThis ? Colors.yellow.shade50 : Colors.white;
    final borderColor = hasTempForThis ? Colors.amber.shade200 : _kBrokerBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (chipItemsBuilder != null) {
            showDialog<void>(
              context: context,
              builder: (_) => _SakChipDetailDialog(
                title: title,
                subtitle: headerSubtitle ?? '-',
                metrics: tileMetrics,
                chips: chipItemsBuilder!(),
              ),
            );
          } else {
            showDialog<void>(
              context: context,
              builder: (_) => _InputGroupDetailDialog(
                title: title,
                subtitle: headerSubtitle ?? '-',
                metrics: tileMetrics,
                details: detailsBuilder(),
              ),
            );
          }
        },
        onLongPress: onLongPress,
        child: _buildHeader(hasTempForThis),
      ),
    );
  }
}

class _SakChipDetailDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(IconData, String)> metrics;
  final List<_InputSakChip> chips;

  const _SakChipDetailDialog({
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle.isNotEmpty ? subtitle : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Chip grid
            Flexible(
              child: chips.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: chips.length,
                        itemBuilder: (_, i) {
                          final chip = chips[i];
                          final bgColor = chip.isTemp
                              ? Colors.amber.shade50
                              : chip.isPartial
                              ? Colors.deepOrange.shade50
                              : const Color(0xFFF0F7FF);
                          final borderColor = chip.isTemp
                              ? Colors.amber.shade300
                              : chip.isPartial
                              ? Colors.deepOrange.shade200
                              : const Color(0xFFBFDBFE);
                          final textColor = chip.isPartial
                              ? Colors.deepOrange.shade800
                              : const Color(0xFF1D4ED8);
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          chip.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${num2(chip.berat)} kg',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (chip.isPartial)
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'P',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (chip.isTemp && chip.onDelete != null)
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: GestureDetector(
                                    onTap: chip.onDelete,
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 9,
                                        color: Colors.brown,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBrokerBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempCardOptionsDialog extends StatelessWidget {
  final String labelTitle;
  final bool showSebagian;
  final bool showPartial;
  const _TempCardOptionsDialog({
    required this.labelTitle,
    this.showSebagian = true,
    this.showPartial = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: const BoxDecoration(
                color: _kBrokerPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (showSebagian) ...[
                    _TempOptionTile(
                      icon: Icons.checklist_rounded,
                      title: 'Sebagian Pallet',
                      value: 'select',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showPartial) ...[
                    _TempOptionTile(
                      icon: Icons.call_split_rounded,
                      title: 'Partial',
                      value: 'partial',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _TempOptionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus Temp',
                    value: 'delete',
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDestructive;

  const _TempOptionTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : _kBrokerPrimary;
    return Material(
      color: isDestructive ? Colors.red.shade50 : _kBrokerSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDestructive ? Colors.red.shade200 : _kBrokerBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputGroupDetailDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(IconData, String)> metrics;
  final List<Widget> details;

  const _InputGroupDetailDialog({
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle.isNotEmpty ? subtitle : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Detail rows
            Flexible(
              child: details.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemBuilder: (_, i) => details[i],
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade200,
                      ),
                      itemCount: details.length,
                    ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBrokerBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerOutputDetailDialog extends StatelessWidget {
  final BrokerOutput output;
  final VoidCallback? onPrint;

  const _BrokerOutputDetailDialog({required this.output, this.onPrint});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          output.namaJenis ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          output.noBroker ?? '-',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            // Grid sak
            Flexible(
              child: output.detailSak.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada detail sak',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1.6,
                            ),
                        itemCount: output.detailSak.length,
                        itemBuilder: (_, i) {
                          final s = output.detailSak[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7FF),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sak ${s.noSak ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${num2(s.berat)} kg',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            // Footer total
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onPrint != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPrint!();
                      },
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Print'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBrokerBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonggolanOutputDetailDialog extends StatelessWidget {
  final BonggolanOutput output;
  final VoidCallback? onPrint;

  const _BonggolanOutputDetailDialog({required this.output, this.onPrint});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      output.namaBonggolan ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    output.noBonggolan ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MiniMetric(
                    icon: Icons.scale_outlined,
                    text: '${num2(output.berat)} kg',
                  ),
                  const SizedBox(height: 8),
                  _MiniMetric(
                    icon: Icons.print_outlined,
                    text: 'Print ${output.printedCount}x',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onPrint != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPrint!();
                      },
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Print'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBrokerBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTabItem {
  final String value;
  final String label;
  final int count;

  const _PanelTabItem({
    required this.value,
    required this.label,
    required this.count,
  });
}

class _PanelTabBar extends StatelessWidget {
  final String selectedValue;
  final List<_PanelTabItem> tabs;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const _PanelTabBar({
    required this.selectedValue,
    required this.tabs,
    required this.onChanged,
    this.accentColor = _kBrokerOutput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBrokerBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = tab.value == selectedValue;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onChanged(tab.value),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : _kBrokerBorder,
                            ),
                          ),
                          child: Text(
                            '${tab.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Folder-style (card tab) tab bar — active tab connects visually to content below.
class _FolderTabBar extends StatelessWidget {
  final String selectedValue;
  final List<_PanelTabItem> tabs;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const _FolderTabBar({
    required this.selectedValue,
    required this.tabs,
    required this.onChanged,
    this.accentColor = _kBrokerPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.32),
          width: 1.1,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      // no bottom padding: selected tab overlaps the seam to content block
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: tabs.map((tab) {
            final isSelected = tab.value == selectedValue;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onChanged(tab.value),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(top: isSelected ? 0 : 4),
                      padding: EdgeInsets.fromLTRB(
                        10,
                        isSelected ? 7 : 5,
                        10,
                        isSelected ? 9 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFDDE1E7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(7),
                        ),
                        border: isSelected
                            ? Border.all(
                                color: accentColor.withValues(alpha: 0.32),
                                width: 1.1,
                              )
                            : Border.all(
                                color: const Color(0xFFC5CAD3),
                                width: 1,
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? accentColor
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.1)
                                  : const Color(0xFFC5CAD3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? accentColor
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Strip putih menutupi border bawah tab yang selected
                    if (isSelected)
                      Positioned(
                        bottom: 0,
                        left: 1.1,
                        right: 1.1,
                        child: Container(height: 2, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyOutputCategory extends StatelessWidget {
  final String message;

  const _EmptyOutputCategory({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    );
  }
}

class _OutputErrorBanner extends StatelessWidget {
  final String message;

  const _OutputErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(
        'Sebagian output gagal dimuat:\n$message',
        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniMetric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog: Ganti Produksi — timeline shift + form buat produksi baru
// ---------------------------------------------------------------------------
class _GantiProduksiDialog extends StatefulWidget {
  const _GantiProduksiDialog({
    required this.idMesin,
    required this.tanggal,
    required this.shift,
    required this.currentNoProduksi,
  });

  final int idMesin;
  final DateTime tanggal;
  final int shift;
  final String currentNoProduksi;

  @override
  State<_GantiProduksiDialog> createState() => _GantiProduksiDialogState();
}

class _GantiProduksiDialogState extends State<_GantiProduksiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourCtrl = TextEditingController(
    text: () {
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }(),
  );
  BrokerType? _selectedJenis;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    _hourCtrl.text = '$h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJenis == null) {
      setState(() => _errorMsg = 'Pilih jenis broker terlebih dahulu');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final repo = BrokerProductionRepository();
      final result = await repo.addProduksi(
        idMesin: widget.idMesin,
        tanggal: widget.tanggal,
        hourStart: _hourCtrl.text.trim(),
        outputJenisId: _selectedJenis!.idBroker,
      );
      if (mounted)
        Navigator.of(
          context,
        ).pop((prod: result, namaJenis: _selectedJenis!.nama));
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.tanggal.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                decoration: const BoxDecoration(
                  color: _kBrokerPrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ganti Produksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$tglLabel  ·  Shift ${widget.shift}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Form — jam + jenis
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _hourCtrl,
                            readOnly: true,
                            onTap: _pickTime,
                            decoration: InputDecoration(
                              labelText: 'Jam Mulai',
                              hintText: '08:00',
                              suffixIcon: const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: _kBrokerBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: _kBrokerPrimary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Wajib diisi';
                              final p = v.trim().split(':');
                              if (p.length < 2) return 'HH:mm';
                              final h = int.tryParse(p[0]);
                              final m = int.tryParse(p[1]);
                              if (h == null || m == null || h > 23 || m > 59)
                                return 'Tidak valid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BrokerTypeDropdown(
                            onChanged: (bt) => setState(() {
                              _selectedJenis = bt;
                              _errorMsg = null;
                            }),
                            validator: (v) =>
                                v == null ? 'Wajib pilih jenis' : null,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Error banner
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Footer
              const SizedBox(height: 12),
              const Divider(height: 1, color: _kBrokerBorder),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: _kBrokerBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBrokerPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 15),
                      label: Text(
                        _isLoading ? 'Menyimpan...' : 'Ganti Produksi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog: Timeline produksi shift
// ---------------------------------------------------------------------------
class _ShiftTimelineDialog extends StatefulWidget {
  const _ShiftTimelineDialog({
    required this.idMesin,
    required this.namaMesin,
    required this.tanggal,
    required this.shift,
    required this.currentNoProduksi,
  });

  final int idMesin;
  final String? namaMesin;
  final DateTime tanggal;
  final int shift;
  final String currentNoProduksi;

  @override
  State<_ShiftTimelineDialog> createState() => _ShiftTimelineDialogState();
}

class _ShiftTimelineDialogState extends State<_ShiftTimelineDialog> {
  late Future<List<BrokerProduction>> _future;

  @override
  void initState() {
    super.initState();
    _future = BrokerProductionRepository().fetchByMesinTanggalShift(
      idMesin: widget.idMesin,
      tanggal: widget.tanggal,
      shift: widget.shift,
    );
  }

  Widget _buildTimeline(List<BrokerProduction> list) {
    final sorted = [...list]
      ..sort((a, b) {
        int toMin(String? hhmm) {
          if (hhmm == null || hhmm.isEmpty) return 0;
          final p = hhmm.split(':');
          return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        }

        return toMin(a.hourStart).compareTo(toMin(b.hourStart));
      });
    final lastEnd = (sorted.isEmpty ? '' : sorted.last.hourEnd ?? '').trim();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        if (i == sorted.length) {
          return Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  lastEnd,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        }
        final prod = sorted[i];
        final isCurrent = prod.noProduksi == widget.currentNoProduksi;
        final isLast = i == sorted.length - 1;
        final jamStart = (prod.hourStart ?? '').trim();
        final nodeColor = isCurrent
            ? _kBrokerPrimary
            : prod.isLocked
            ? const Color(0xFFF97316)
            : Colors.grey.shade400;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    jamStart.isNotEmpty ? jamStart : '--:--',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? _kBrokerPrimary : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? _kBrokerPrimary : Colors.white,
                      border: Border.all(color: nodeColor, width: 2),
                    ),
                    child: isCurrent
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  if (isLast) const SizedBox(height: 4),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _kBrokerPrimary.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? _kBrokerPrimary.withValues(alpha: 0.4)
                            : _kBrokerBorder,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.outputJenisNama ?? 'Belum ada jenis',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: prod.outputJenisNama != null
                                      ? const Color(0xFF1A1D23)
                                      : Colors.grey.shade400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                prod.noProduksi,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kBrokerPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Sedang berlangsung',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _kBrokerPrimary,
                              ),
                            ),
                          )
                        else if (prod.isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF97316,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tglLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.tanggal.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: const BoxDecoration(
                color: _kBrokerPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.view_list_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Produksi ${widget.namaMesin} (Shift ${widget.shift})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tglLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<BrokerProduction>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snap.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _future = BrokerProductionRepository()
                                  .fetchByMesinTanggalShift(
                                    idMesin: widget.idMesin,
                                    tanggal: widget.tanggal,
                                    shift: widget.shift,
                                  );
                            }),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada produksi pada shift ini.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildTimeline(list),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: _kBrokerBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
