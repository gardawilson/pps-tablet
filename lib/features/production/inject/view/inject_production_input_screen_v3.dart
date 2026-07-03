import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

import '../../../../common/widgets/confirm_dialog.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/scan_label_dialog.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../../shared/models/production_label_lookup_result.dart';
import '../../shared/widgets/add_cabinet_material_dialog.dart';
import '../../shared/widgets/confirm_save_temp_dialog.dart';
import '../../shared/widgets/save_button_with_badge.dart';
import '../../shared/widgets/unsaved_temp_warning_dialog.dart';
import '../model/inject_batch_model.dart';
import '../model/inject_production_inputs_model.dart';
import '../model/inject_production_model.dart'
    show InjectOutputJenis, InjectProduction;
import '../repository/inject_production_repository.dart';
import '../view_model/inject_production_input_view_model.dart';

import '../view_model/inject_formula_view_model.dart';
import '../widgets/inject_shift_timeline_dialog.dart';
import '../widgets/counter_picker_dialog.dart';
import '../widgets/inject_sak_picker_dialog.dart';
import '../widgets/inject_split_time_dialog.dart';
import '../widgets/inject_terminate_dialog.dart';
import '../../../../features/reject_type/model/reject_type_model.dart';
import '../../../../features/reject_type/view_model/reject_type_view_model.dart';
import '../../../../features/jenis_bonggolan/model/jenis_bonggolan_model.dart';
import '../../../../features/jenis_bonggolan/view_model/jenis_bonggolan_view_model.dart';
import '../../../label/bonggolan/repository/bonggolan_repository.dart';
import '../../../label/furniture_wip/repository/furniture_wip_repository.dart';
import '../../../label/reject/repository/reject_repository.dart';
import '../../../label/packing/repository/packing_repository.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/label_print_lock_api.dart';
import '../../../../core/services/label_print_sync_queue.dart';
import '../../../../core/utils/pdf_print_service.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';

// ── Colour palette ─────────────────────────────────────────────────────────────
const _kInjectPrimary = Color(0xFF0277BD); // biru — input
const _kInjectOutput = Color(0xFF00695C); // darker teal — output
const _kInjectSurface = Color(0xFFF8F9FB);
const _kInjectBorder = Color(0xFFE2E6EA);

class InjectProductionInputScreen extends StatefulWidget {
  final String noProduksi;

  const InjectProductionInputScreen({super.key, required this.noProduksi});

  @override
  State<InjectProductionInputScreen> createState() =>
      _InjectProductionInputScreenState();
}

class _InjectProductionInputScreenState
    extends State<InjectProductionInputScreen> {
  String _selectedInputTab = 'fwip';

  // ── Header (fetched from API) ─────────────────────────────────────────────
  final _prodRepo = InjectProductionRepository();
  InjectProduction? _header;
  // Cache label so dispose() can read it after _header may be gone
  late String _cachedBreadcrumbLabel;

  List<BreadcrumbSegment> _prevBreadcrumb = [];

  // ── Hourly bucket states ───────────────────────────────────────────────────
  final Map<String, _HourlyBucketData> _bucketStates = {};
  List<String> _bucketLabelOrder = [];
  final Map<String, DateTime> _bucketStartTimes = {};
  final Map<String, DateTime> _bucketEndTimes = {};
  Timer? _statusTimer;

  // ── Batch / pcs-per-label ─────────────────────────────────────────────────
  InjectPcsPerLabelResult? _pcsPerLabelData;

  String get _breadcrumbLabel {
    final mesin = (_header?.namaMesin ?? '').trim();
    if (mesin.isNotEmpty) return '$mesin (${widget.noProduksi})';
    return widget.noProduksi;
  }

  // Terminate hanya boleh ketika ada bucket available (range jam sekarang belum diinput)
  bool get _canTerminate => _bucketLabelOrder.any(
    (l) => _bucketStates[l]?.status == _HourlyBucketStatus.available,
  );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cachedBreadcrumbLabel = widget.noProduksi;
    _loadHeader();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(_recomputeBucketStatuses);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Capture prev here (not in initState) so any pending dispose callbacks
      // from the previous screen have already fired and reset the breadcrumb.
      _prevBreadcrumb = List<BreadcrumbSegment>.from(AppShell.breadcrumb.value);
      _updateBreadcrumb();

      final vm = context.read<InjectProductionInputViewModel>();
      if (vm.inputsOf(widget.noProduksi) == null &&
          !vm.isInputsLoading(widget.noProduksi)) {
        vm.loadInputs(widget.noProduksi);
      }

      context.read<InjectFormulaViewModel>().load(widget.noProduksi);
    });
  }

  Future<void> _loadHeader() async {
    try {
      final results = await Future.wait([
        _prodRepo.fetchOne(widget.noProduksi),
        _prodRepo.fetchPcsPerLabel(widget.noProduksi),
        _prodRepo.fetchBatch(widget.noProduksi),
      ]);
      if (!mounted) return;

      final header = results[0] as InjectProduction;
      final pcsPerLabel = results[1] as InjectPcsPerLabelResult;
      final batches = results[2] as List<InjectBatchItem>;

      setState(() {
        _header = header;
        _pcsPerLabelData = pcsPerLabel;
        _cachedBreadcrumbLabel = _breadcrumbLabel;
        _initBucketStatesFromHeader(header);
        _restoreBucketStatesFromBatches(batches, pcsPerLabel);
        _recomputeBucketStatuses();
      });
      _updateBreadcrumb();
    } catch (_) {}
  }

  void _restoreBucketStatesFromBatches(
    List<InjectBatchItem> batches,
    InjectPcsPerLabelResult pcsPerLabelData,
  ) {
    for (final batch in batches) {
      final bucketLabel = _bucketLabelOrder.firstWhere(
        (l) => l.startsWith(batch.hourStart),
        orElse: () => '',
      );
      if (bucketLabel.isEmpty) continue;

      final isLast = _bucketLabelOrder.last == bucketLabel;
      final carryInByJenis = <int, int>{};
      final pcsInByJenis = <int, int>{};
      final carryOutByJenis = <int, int>{};
      int labelsCreated = 0;

      if (batch.jenisItems.isNotEmpty) {
        for (final ji in batch.jenisItems) {
          carryInByJenis[ji.idJenis] = ji.carryOverIn;
          pcsInByJenis[ji.idJenis] = ji.pcsInput;
          carryOutByJenis[ji.idJenis] = ji.carryOverOut;
          final ppl = pcsPerLabelData.pplForJenis(ji.idJenis);
          final totalPcs = ji.carryOverIn + ji.pcsInput;
          if (isLast) {
            labelsCreated += (totalPcs ~/ ppl) + (totalPcs % ppl > 0 ? 1 : 0);
          } else {
            labelsCreated += totalPcs ~/ ppl;
          }
        }
      } else {
        // Legacy fallback
        final ppl = pcsPerLabelData.items.isNotEmpty
            ? pcsPerLabelData.items.first.pcsPerLabel.clamp(1, 999999)
            : 100;
        final totalPcs = batch.carryOverIn + batch.pcsInput;
        if (isLast) {
          labelsCreated = (totalPcs ~/ ppl) + (totalPcs % ppl > 0 ? 1 : 0);
        } else {
          labelsCreated = totalPcs ~/ ppl;
        }
      }

      final bonggolanLabel = batch.labels.bonggolan.isNotEmpty
          ? batch.labels.bonggolan.first
          : null;
      final rejectLabel = batch.labels.reject.isNotEmpty
          ? batch.labels.reject.first
          : null;
      _bucketStates[bucketLabel] = _HourlyBucketData(
        status: _HourlyBucketStatus.submitted,
        carryOverIn: batch.carryOverIn,
        carryOverInByJenis: carryInByJenis,
        pcsInput: batch.pcsInput,
        pcsInputByJenis: pcsInByJenis,
        labelsCreated: labelsCreated,
        carryOverOut: batch.carryOverOut,
        carryOverOutByJenis: carryOutByJenis,
        berat: batch.berat,
        cycleTime: batch.cycleTime,
        counter: batch.counter,
        beratBonggolan: bonggolanLabel?.berat,
        namaBonggolan:
            bonggolanLabel != null && bonggolanLabel.namaJenis.isNotEmpty
            ? bonggolanLabel.namaJenis
            : null,
        beratReject: rejectLabel?.berat,
        namaReject: rejectLabel != null && rejectLabel.namaJenis.isNotEmpty
            ? rejectLabel.namaJenis
            : null,
        labelsFwip: batch.labels.furnitureWip,
        labelsBarangJadi: batch.labels.barangJadi,
        labelsBonggolan: batch.labels.bonggolan,
        labelsReject: batch.labels.reject,
      );
    }
  }

  List<String> _computeHourBucketLabels(InjectProduction header) {
    final startMinutes = _parseMinutes(header.hourStart);
    final endMinutes = _parseMinutes(header.hourEnd);
    if (startMinutes == null || endMinutes == null) return [];

    var durationMinutes = endMinutes - startMinutes;
    if (durationMinutes <= 0) durationMinutes += 24 * 60;
    if (durationMinutes <= 0) return [];

    final tgl = header.tglProduksi;
    final anchorDate = tgl != null
        ? DateTime(tgl.year, tgl.month, tgl.day)
        : DateTime.now();
    final startDateTime = anchorDate.add(Duration(minutes: startMinutes));

    final labels = <String>[];
    final startRemainder = startMinutes % 60;
    final firstBucketDuration = startRemainder == 0
        ? 60
        : (60 - startRemainder);
    var offset = 0;
    while (offset < durationMinutes) {
      final step = (offset == 0 && startRemainder != 0)
          ? firstBucketDuration
          : 60;
      final nextOffset = (offset + step) > durationMinutes
          ? durationMinutes
          : offset + step;
      final bucketStart = startDateTime.add(Duration(minutes: offset));
      final bucketEnd = startDateTime.add(Duration(minutes: nextOffset));
      final label =
          '${_formatHourMinute(bucketStart)} - ${_formatHourMinute(bucketEnd)}';
      labels.add(label);
      _bucketStartTimes[label] = bucketStart;
      _bucketEndTimes[label] = bucketEnd;
      offset = nextOffset;
    }
    return labels;
  }

  void _initBucketStatesFromHeader(InjectProduction header) {
    final labels = _computeHourBucketLabels(header);
    if (labels.isEmpty) return;
    _bucketLabelOrder = labels;
    // Initialize all as locked; _recomputeBucketStatuses will set correct status
    for (final label in labels) {
      if (!_bucketStates.containsKey(label)) {
        _bucketStates[label] = const _HourlyBucketData(
          status: _HourlyBucketStatus.locked,
          carryOverIn: 0,
          pcsInput: 0,
          labelsCreated: 0,
          carryOverOut: 0,
        );
      }
    }
  }

  // Recompute non-submitted bucket statuses based on current time.
  // Must be called inside setState or within a setState callback.
  void _recomputeBucketStatuses() {
    final now = DateTime.now();
    final isComplete = _header?.isComplete ?? false;
    final lastLabel = _bucketLabelOrder.isNotEmpty
        ? _bucketLabelOrder.last
        : null;
    int lastSubmittedCarryOut = 0;
    var lastCarryOutByJenis = <int, int>{};

    for (final label in _bucketLabelOrder) {
      final startDt = _bucketStartTimes[label];
      final endDt = _bucketEndTimes[label];
      if (startDt == null || endDt == null) continue;

      final current = _bucketStates[label];
      if (current?.status == _HourlyBucketStatus.submitted) {
        lastSubmittedCarryOut = current?.carryOverOut ?? 0;
        lastCarryOutByJenis = Map.from(current?.carryOverOutByJenis ?? {});
        continue;
      }

      // Bucket terakhir & produksi belum selesai → tidak expired meski jam sudah lewat
      final isLastAndIncomplete = !isComplete && label == lastLabel;
      final isPastEnd = !now.isBefore(endDt);

      final _HourlyBucketStatus newStatus;
      if (isPastEnd && !isLastAndIncomplete) {
        newStatus = _HourlyBucketStatus.expired;
      } else if (!now.isBefore(startDt)) {
        newStatus = _HourlyBucketStatus.available;
      } else {
        newStatus = _HourlyBucketStatus.locked;
      }

      // Overdue: bucket terakhir yang belum selesai tapi sudah lewat jam akhirnya
      final isOverdue = isLastAndIncomplete && isPastEnd;

      final isActive =
          newStatus == _HourlyBucketStatus.available ||
          newStatus == _HourlyBucketStatus.expired;
      _bucketStates[label] = _HourlyBucketData(
        status: newStatus,
        isOverdue: isOverdue,
        carryOverIn: isActive ? lastSubmittedCarryOut : 0,
        carryOverInByJenis: isActive ? Map.from(lastCarryOutByJenis) : {},
        pcsInput: 0,
        labelsCreated: 0,
        carryOverOut: 0,
      );
    }
  }

  Future<void> _onBucketSubmit(
    String label,
    List<_JenisSubmitItem> jenisItems,
    double? berat,
    double? cycleTime,
    int? counter,
    double? beratBonggolan,
    double? beratReject,
    int? idRejectBonggolan,
    int? idRejectReject, {
    String? namaBonggolan,
    String? namaReject,
    bool isLastBucket = false,
  }) async {
    if (_bucketStates[label] == null) return;

    final pplData = _pcsPerLabelData;
    final hourStart = label.split(' - ').first.trim();

    final itemsToSubmit = jenisItems
        .where((i) => i.pcs > 0 || i.carryOverIn > 0)
        .toList();
    if (itemsToSubmit.isEmpty) return;

    final carryOutByJenis = <int, int>{};
    int totalCarryOverIn = 0;
    int totalPcsInput = 0;
    int totalLabelsCreated = 0;
    int totalCarryOverOut = 0;

    final itemsPayload = itemsToSubmit.map((item) {
      final ppl = pplData?.pplForJenis(item.jenis.idJenis) ?? 100;
      final totalPcs = item.carryOverIn + item.pcs;
      final carryOut = isLastBucket ? 0 : totalPcs % ppl;
      carryOutByJenis[item.jenis.idJenis] = carryOut;
      totalCarryOverIn += item.carryOverIn;
      totalPcsInput += item.pcs;
      totalCarryOverOut += carryOut;
      if (isLastBucket) {
        totalLabelsCreated += (totalPcs ~/ ppl) + (totalPcs % ppl > 0 ? 1 : 0);
      } else {
        totalLabelsCreated += totalPcs ~/ ppl;
      }
      return <String, dynamic>{
        'idJenis': item.jenis.idJenis,
        'pcsInput': item.pcs,
        'carryOverIn': item.carryOverIn,
        'carryOverOut': carryOut,
      };
    }).toList();

    final payload = <String, dynamic>{
      'noProduksi': widget.noProduksi,
      'hourStart': hourStart,
      if (berat != null) 'berat': berat,
      if (cycleTime != null) 'cycleTime': cycleTime,
      if (counter != null) 'counter': counter,
      'items': itemsPayload,
      if (isLastBucket && idRejectBonggolan != null && beratBonggolan != null)
        'bonggolan': {
          'idBonggolan': idRejectBonggolan,
          'berat': beratBonggolan,
        },
      if (isLastBucket && idRejectReject != null && beratReject != null)
        'reject': {'idReject': idRejectReject, 'berat': beratReject},
    };

    final InjectBatchSubmitResult result;
    try {
      result = await _prodRepo.submitBatch(payload);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan: $e', backgroundColor: Colors.red);
      return;
    }
    if (!mounted) return;

    setState(() {
      _bucketStates[label] = _HourlyBucketData(
        status: _HourlyBucketStatus.submitted,
        carryOverIn: totalCarryOverIn,
        carryOverInByJenis: {
          for (final i in itemsToSubmit) i.jenis.idJenis: i.carryOverIn,
        },
        pcsInput: totalPcsInput,
        pcsInputByJenis: {
          for (final i in itemsToSubmit) i.jenis.idJenis: i.pcs,
        },
        labelsCreated: totalLabelsCreated,
        carryOverOut: totalCarryOverOut,
        carryOverOutByJenis: carryOutByJenis,
        berat: berat,
        cycleTime: cycleTime,
        counter: counter,
        beratBonggolan: result.bonggolan?.berat ?? beratBonggolan,
        namaBonggolan: (result.bonggolan?.namaJenis.isNotEmpty == true)
            ? result.bonggolan!.namaJenis
            : namaBonggolan,
        beratReject: result.reject?.berat ?? beratReject,
        namaReject: (result.reject?.namaJenis.isNotEmpty == true)
            ? result.reject!.namaJenis
            : namaReject,
        labelsFwip: result.furnitureWIP,
        labelsBarangJadi: result.barangJadi,
        labelsBonggolan: result.bonggolan != null ? [result.bonggolan!] : [],
        labelsReject: result.reject != null ? [result.reject!] : [],
      );
      _recomputeBucketStatuses();
    });

    if (totalLabelsCreated > 0) {
      _showSnack(
        '✅ $totalLabelsCreated label tercipta',
        backgroundColor: Colors.green,
      );
    } else if (totalPcsInput > 0) {
      _showSnack(
        '✅ Pcs tersimpan · sisa $totalCarryOverOut pcs carry-over',
        backgroundColor: Colors.green,
      );
    } else {
      _showSnack('✅ Data tersimpan', backgroundColor: Colors.green);
    }
  }

  void _updateBreadcrumb() {
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
      BreadcrumbSegment(_breadcrumbLabel),
    ];
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    // Breadcrumb must update after the current frame — updating a ValueNotifier
    // during unmount triggers setState on AppShell while the tree is locked.
    final prev = _prevBreadcrumb;
    final label = _cachedBreadcrumbLabel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = AppShell.breadcrumb.value;
      if (current.isNotEmpty && current.last.label == label) {
        AppShell.breadcrumb.value = prev;
      }
    });
    super.dispose();
  }

  // ── Back ───────────────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final vm = context.read<InjectProductionInputViewModel>();
    if (vm.totalTempCount == 0) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnsavedTempWarningDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
        onSavePressed: () {
          Navigator.of(ctx).pop(false);
          _handleSave();
        },
      ),
    );

    if (shouldPop == true) {
      vm.clearAllTempItems();
      return true;
    }
    return false;
  }

  // ── Snack ──────────────────────────────────────────────────────────────────

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

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final vm = context.read<InjectProductionInputViewModel>();
    if (vm.totalTempCount == 0) {
      _showSnack(
        'Tidak ada data untuk disimpan',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmSaveTempDialog(
        totalTempCount: vm.totalTempCount,
        submitSummary: vm.getSubmitSummary(),
      ),
    );
    if (confirm != true || !mounted) return;

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
    }
  }

  Future<void> _confirmClearTemp() async {
    final vm = context.read<InjectProductionInputViewModel>();
    if (vm.totalTempCount == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Hapus Semua Temp?',
        message:
            'Yakin ingin menghapus ${vm.totalTempCount} item temp?\n'
            'Data yang belum disimpan akan hilang.',
        confirmLabel: 'Hapus',
        confirmIcon: Icons.delete_sweep,
      ),
    );
    if (confirmed != true || !mounted) return;
    vm.clearAllTempItems();
    _showSnack('Semua temp items dihapus');
  }

  // ── Riwayat (Timeline) ───────────────────────────────────────────────────

  Future<void> _openTimelineDialog() async {
    if (!mounted) return;
    await ProductionFlowHelpers.openTimeline(
      context: context,
      idMesin: _header?.idMesin,
      tanggal: _header?.tglProduksi,
      onMissingContext: () => _showSnack(
        'Data mesin/tanggal tidak tersedia',
        backgroundColor: Colors.orange,
      ),
      dialogBuilder: (idMesin, tgl) => InjectShiftTimelineDialog(
        namaMesin: _header?.namaMesin,
        tanggal: tgl,
        shift: _header?.shift ?? 1,
        currentNoProduksi: widget.noProduksi,
        primaryColor: _kInjectPrimary,
        borderColor: _kInjectBorder,
        emptyMessage: 'Belum ada riwayat produksi pada shift ini.',
        loadTimeline: () async {
          final list = await _prodRepo.fetchByMesinTanggalShift(
            idMesin: idMesin,
            tanggal: tgl,
            shift: _header?.shift ?? 1,
          );
          return list
              .map(
                (e) => InjectShiftTimelineEntry(
                  noProduksi: e.noProduksi,
                  hourStart: e.hourStart,
                  hourEnd: e.hourEnd,
                  isLocked: e.isLocked,
                  outputs: e.outputs.map((o) => o.namaJenis).toList(),
                  namaCetakan: e.namaCetakan,
                  namaWarna: e.namaWarna,
                  namaFurnitureMaterial: e.namaFurnitureMaterial,
                ),
              )
              .toList();
        },
      ),
    );
  }

  // ── Terminate ─────────────────────────────────────────────────────────────

  Future<void> _openTerminateDialog() async {
    final h = _header;
    if (h == null || widget.noProduksi.isEmpty) return;

    // Cari bucket available terakhir
    final lastAvailable = _bucketLabelOrder.reversed.firstWhere(
      (l) => _bucketStates[l]?.status == _HourlyBucketStatus.available,
      orElse: () => '',
    );

    // carryOverIn untuk terminate = carryOverOut dari bucket submitted terakhir.
    // Jika ada bucket available, carryOverIn-nya sudah diset = carryOverOut submitted terakhir.
    // Jika tidak ada bucket available, ambil langsung dari submitted terakhir.
    int carryOverIn;
    Map<int, int> carryOverInByJenis;
    String terminateHourStart;

    if (lastAvailable.isNotEmpty) {
      carryOverIn = _bucketStates[lastAvailable]?.carryOverIn ?? 0;
      carryOverInByJenis =
          _bucketStates[lastAvailable]?.carryOverInByJenis ??
          const <int, int>{};
      terminateHourStart = lastAvailable.split(' - ').first.trim();
    } else {
      // Fallback: langsung dari carryOverOut bucket submitted terakhir
      final lastSubmitted = _bucketLabelOrder.reversed.firstWhere(
        (l) => _bucketStates[l]?.status == _HourlyBucketStatus.submitted,
        orElse: () => '',
      );
      carryOverIn = _bucketStates[lastSubmitted]?.carryOverOut ?? 0;
      carryOverInByJenis =
          _bucketStates[lastSubmitted]?.carryOverOutByJenis ??
          const <int, int>{};
      // hourStart = ujung akhir dari bucket submitted terakhir (= awal bucket berikutnya)
      terminateHourStart = lastSubmitted.isNotEmpty
          ? lastSubmitted.split(' - ').last.trim()
          : '';
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InjectTerminateDialog(
        noProduksi: widget.noProduksi,
        hourStart: terminateHourStart,
        hourEnd: h.hourEnd ?? '',
        carryOverIn: carryOverIn,
        carryOverInByJenis: carryOverInByJenis,
        outputJenisList: h.outputs,
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _showSnack(
        '✅ Produksi berhasil di-terminate',
        backgroundColor: Colors.red,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── Split Time (Ganti) ────────────────────────────────────────────────────

  Future<void> _openSplitTimeDialog() async {
    final h = _header;
    if (h == null || h.idMesin == 0 || h.tglProduksi == null) return;

    // Tampilkan menu pilih mode ganti
    final mode = await showDialog<_GantiMode>(
      context: context,
      builder: (ctx) => _GantiModeDialog(
        currentCetakan: h.namaCetakan,
        currentWarna: h.namaWarna,
        currentMaterial: h.namaFurnitureMaterial,
      ),
    );
    if (!mounted || mode == null) return;

    // Cari bucket available terakhir untuk carry-over dan hourStart
    final lastAvailable = _bucketLabelOrder.reversed.firstWhere(
      (l) => _bucketStates[l]?.status == _HourlyBucketStatus.available,
      orElse: () => '',
    );
    final carryOverIn = _bucketStates[lastAvailable]?.carryOverIn ?? 0;
    final lastBucketHourStart = lastAvailable.isNotEmpty
        ? lastAvailable.split(' - ').first.trim()
        : null;

    final result = await showDialog<InjectBatchSubmitResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InjectSplitTimeDialog(
        idMesin: h.idMesin,
        tglProduksi: h.tglProduksi!,
        currentHourEnd: h.hourEnd,
        currentCetakan: h.namaCetakan,
        currentWarna: h.namaWarna,
        currentMaterial: h.namaFurnitureMaterial,
        lockedIdCetakan: mode == _GantiMode.warnaAndMaterial
            ? h.idCetakan
            : null,
        lockedNamaCetakan: mode == _GantiMode.warnaAndMaterial
            ? h.namaCetakan
            : null,
        carryOverIn: carryOverIn,
        pcsPerLabel: _pcsPerLabelData?.items.isNotEmpty == true
            ? _pcsPerLabelData!.items.first.pcsPerLabel
            : 100,
        counterCurrent: _pcsPerLabelData?.counterCurrent,
        outputJenisList: h.outputs,
        noProduksi: widget.noProduksi,
        lastBucketHourStart: lastBucketHourStart,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      _showSnack('✅ Produksi berhasil diganti', backgroundColor: Colors.green);
      // Fetch ulang batch untuk mendapatkan label terbaru dari bucket yang di-split
      if (lastBucketHourStart != null && mounted) {
        try {
          final batches = await _prodRepo.fetchBatch(widget.noProduksi);
          if (!mounted) return;
          final matchedBatch = batches.cast<InjectBatchItem?>().firstWhere(
            (b) => b?.hourStart == lastBucketHourStart,
            orElse: () => null,
          );
          if (matchedBatch != null) {
            final printEntries = _buildPrintableEntriesFromBatch(matchedBatch);
            if (printEntries.isNotEmpty && mounted) {
              await showDialog<void>(
                context: context,
                builder: (_) => _BucketPrintDialog(
                  hourLabel: lastBucketHourStart,
                  entries: printEntries,
                  onPrint: (selected) => _printLabelsBatch(selected),
                ),
              );
            }
          }
        } catch (_) {}
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── Scan / Lookup ──────────────────────────────────────────────────────────

  Future<void> _openScanDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        manualHint: 'BB. / D. / H. / V.',
        acceptedLabels: const [
          (prefix: 'BB', label: 'Furniture WIP'),
          (prefix: 'D', label: 'Broker'),
          (prefix: 'H', label: 'Mixer'),
          (prefix: 'V', label: 'Gilingan'),
        ],
        onLookup: _onCodeReady,
      ),
    );
  }

  Future<String?> _onCodeReady(String code) async {
    final vm = context.read<InjectProductionInputViewModel>();
    final res = await vm.lookupLabel(code, force: true);
    if (!mounted) return 'Halaman sudah tidak aktif';
    if (vm.lookupError != null) return 'Gagal ambil data: ${vm.lookupError}';
    if (res == null || res.found == false || res.data.isEmpty) {
      return 'Label "$code" tidak memiliki data yang tersedia.';
    }

    // TODO: re-enable prefix validation setelah formula siap
    // const allowedPrefixes = {
    //   PrefixType.furnitureWip,
    //   PrefixType.broker,
    //   PrefixType.mixer,
    //   PrefixType.gilingan,
    // };
    // if (!allowedPrefixes.contains(res.prefixType)) {
    //   if (mounted) {
    //     await showDialog<void>(
    //       context: context,
    //       builder: (_) => ErrorStatusDialog(
    //         title: 'Label Tidak Diizinkan',
    //         message:
    //             'Label "${res.prefix}" tidak dapat digunakan di proses Inject.\n\n'
    //             'Prefix yang diperbolehkan: BB (Furniture WIP), D (Broker), H (Mixer), V (Gilingan).',
    //       ),
    //     );
    //   }
    //   return 'Prefix ${res.prefix} tidak diperbolehkan untuk proses Inject';
    // }

    if (res.prefixType == PrefixType.furnitureWip) {
      await _handleFwipPcsFlow(vm, res);
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => InjectSakPickerDialog(noProduksi: widget.noProduksi),
      );
    }
    return null;
  }

  Future<void> _handleFwipPcsFlow(
    InjectProductionInputViewModel vm,
    ProductionLabelLookupResult res,
  ) async {
    int totalAdded = 0, totalSkipped = 0;
    for (int i = 0; i < res.typedItems.length; i++) {
      final item = res.typedItems[i];
      if (item is! FurnitureWipItem) continue;
      final rawRow = res.data[i];
      final simpleKey = res.simpleKey(rawRow);
      if (vm.isInTempKeys(simpleKey)) {
        totalSkipped++;
        continue;
      }
      if (!mounted) break;
      final result = await showDialog<ProductionPcsInputResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProductionPcsInputDialog(
          item: item,
          itemIndex: i,
          totalItems: res.typedItems.length,
          primaryColor: _kInjectPrimary,
        ),
      );
      if (result == null) continue;
      final originalPcs = rawRow['pcs'] ?? rawRow['Pcs'];
      final originalIsPartial = rawRow['isPartial'];
      if (result.isPartial) {
        rawRow['pcs'] = result.pcs;
        rawRow['Pcs'] = result.pcs;
        rawRow['isPartial'] = true;
        rawRow['IsPartial'] = true;
      }
      vm.clearPicks();
      vm.togglePick(rawRow);
      final r = vm.commitPickedToTemp(noProduksi: widget.noProduksi);
      rawRow['pcs'] = originalPcs;
      rawRow['Pcs'] = originalPcs;
      rawRow['isPartial'] = originalIsPartial;
      rawRow['IsPartial'] = originalIsPartial;
      totalAdded += r.added;
      totalSkipped += r.skipped;
    }
    if (!mounted) return;
    _showSnack(
      totalAdded > 0
          ? '✅ Ditambahkan $totalAdded item${totalSkipped > 0 ? ' • $totalSkipped terlewati' : ''}'
          : 'Tidak ada item yang ditambahkan',
      backgroundColor: totalAdded > 0 ? Colors.green : Colors.orange,
    );
  }

  // ── Cabinet Material ───────────────────────────────────────────────────────

  Future<void> _openAddMaterialDialog(InjectProductionInputViewModel vm) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AddCabinetMaterialDialog(
        idWarehouse: 5,
        loadMaterials: ({required idWarehouse, bool force = false}) => vm
            .loadMasterCabinetMaterials(idWarehouse: idWarehouse, force: force),
        isAlreadyInTemp: (id) => vm.hasCabinetMaterialInTemp(id),
        onAddTemp: ({required masterItem, required jumlah}) =>
            vm.addTempCabinetMaterialFromMaster(
              masterItem: masterItem,
              Jumlah: jumlah,
            ),
      ),
    );
  }

  Future<void> _deleteExistingMaterial(
    InjectProductionInputViewModel vm,
    CabinetMaterialItem item,
  ) async {
    final name = item.Nama ?? 'Material';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Hapus Material?',
        message: 'Yakin ingin menghapus $name?',
        confirmLabel: 'Hapus',
        confirmIcon: Icons.delete_outline,
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await vm.deleteItems(widget.noProduksi, [item]);
    if (!mounted) return;
    _showSnack(
      success ? '✅ Material berhasil dihapus' : (vm.deleteError ?? 'Gagal'),
      backgroundColor: success ? Colors.green : Colors.red,
    );
  }

  // ── Title keys ─────────────────────────────────────────────────────────────

  String _fwipTitleKey(FurnitureWipItem e) {
    final part = (e.noFurnitureWIPPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noFurnitureWIP ?? '-');
  }

  String _brokerTitleKey(BrokerItem e) {
    final part = (e.noBrokerPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noBroker ?? '-');
  }

  String _mixerTitleKey(MixerItem e) {
    final part = (e.noMixerPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noMixer ?? '-');
  }

  String _gilinganTitleKey(GilinganItem e) {
    final part = (e.noGilinganPartial ?? '').trim();
    return part.isNotEmpty ? part : (e.noGilingan ?? '-');
  }

  // ── Input panel ────────────────────────────────────────────────────────────

  Widget _buildInputPanel({
    required InjectProductionInputViewModel vm,
    required bool locked,
    required bool loading,
    required bool canDelete,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required Map<String, List<BrokerItem>> brokerGroups,
    required Map<String, List<MixerItem>> mixerGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
  }) {
    // ── per-tab metrics ────────────────────────────────────────────
    double fwipBerat = 0;
    int fwipPcs = 0;
    for (final items in fwipGroups.values) {
      for (final i in items) {
        fwipPcs += i.pcs ?? 0;
        fwipBerat += i.berat ?? 0;
      }
    }
    int brokerSak = 0;
    double brokerBerat = 0;
    for (final items in brokerGroups.values) {
      for (final i in items) {
        brokerSak += 1;
        brokerBerat += i.berat ?? 0;
      }
    }
    int mixerSak = 0;
    double mixerBerat = 0;
    for (final items in mixerGroups.values) {
      for (final i in items) {
        mixerSak += 1;
        mixerBerat += i.berat ?? 0;
      }
    }
    double gilinganBerat = 0;
    for (final items in gilinganGroups.values) {
      for (final i in items) {
        gilinganBerat += i.berat ?? 0;
      }
    }
    final materialCount = materialAll.length;

    // ── grand total ────────────────────────────────────────────────
    final grandLabel =
        fwipGroups.length +
        brokerGroups.length +
        mixerGroups.length +
        gilinganGroups.length +
        materialCount;
    final grandSak = brokerSak + mixerSak;
    final grandBerat = fwipBerat + brokerBerat + mixerBerat + gilinganBerat;

    // ── active-tab summary ─────────────────────────────────────────
    SectionSummary activeTabSummary() {
      switch (_selectedInputTab) {
        case 'fwip':
          return SectionSummary(
            totalData: fwipGroups.length,
            totalSak: fwipPcs,
            totalBerat: 0,
          );
        case 'broker':
          return SectionSummary(
            totalData: brokerGroups.length,
            totalSak: brokerSak,
            totalBerat: brokerBerat,
          );
        case 'mixer':
          return SectionSummary(
            totalData: mixerGroups.length,
            totalSak: mixerSak,
            totalBerat: mixerBerat,
          );
        case 'gilingan':
          return SectionSummary(
            totalData: gilinganGroups.length,
            totalSak: 0,
            totalBerat: gilinganBerat,
          );
        case 'material':
          return SectionSummary(
            totalData: materialCount,
            totalSak: materialCount,
            totalBerat: 0,
          );
        default:
          return SectionSummary(totalData: 0, totalSak: 0, totalBerat: 0);
      }
    }

    final tabCounts = {
      'fwip': fwipGroups.length,
      'broker': brokerGroups.length,
      'mixer': mixerGroups.length,
      'gilingan': gilinganGroups.length,
      'material': materialCount,
    };

    return Container(
      decoration: productionPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.input_rounded,
                  'Label Input',
                  primaryColor: _kInjectPrimary,
                ),
                const Spacer(),
                SaveButtonWithBadge(
                  count: vm.totalTempCount,
                  isLoading: vm.isSubmitting,
                  onPressed: _handleSave,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Hapus Semua Temp',
                  onPressed: vm.totalTempCount > 0 ? _confirmClearTemp : null,
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
          const Divider(height: 1, color: _kInjectBorder),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductionFolderTabBar(
                    selectedValue: _selectedInputTab,
                    accentColor: _kInjectPrimary,
                    tabs: [
                      ProductionTabItem(
                        value: 'fwip',
                        label: 'Furniture WIP',
                        count: tabCounts['fwip'] ?? 0,
                      ),
                      ProductionTabItem(
                        value: 'broker',
                        label: 'Broker',
                        count: tabCounts['broker'] ?? 0,
                      ),
                      ProductionTabItem(
                        value: 'mixer',
                        label: 'Mixer',
                        count: tabCounts['mixer'] ?? 0,
                      ),
                      ProductionTabItem(
                        value: 'gilingan',
                        label: 'Gilingan',
                        count: tabCounts['gilingan'] ?? 0,
                      ),
                      ProductionTabItem(
                        value: 'material',
                        label: 'Material',
                        count: tabCounts['material'] ?? 0,
                      ),
                    ],
                    onChanged: (v) {
                      if (_selectedInputTab != v) {
                        setState(() => _selectedInputTab = v);
                      }
                    },
                  ),
                  Expanded(
                    child: ProductionInputCategoryBlock(
                      color: _kInjectPrimary,
                      isLoading: loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (ctx, c) => SizedBox(
                                width: c.maxWidth,
                                child: _buildActiveInputTab(
                                  vm: vm,
                                  locked: locked,
                                  canDelete: canDelete,
                                  fwipGroups: fwipGroups,
                                  brokerGroups: brokerGroups,
                                  mixerGroups: mixerGroups,
                                  gilinganGroups: gilinganGroups,
                                  materialAll: materialAll,
                                  tempMaterialIds: tempMaterialIds,
                                  constraints: c,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProductionCategorySummaryTile(
                                      summary: activeTabSummary(),
                                      accentColor: _kInjectPrimary,
                                      sakLabel:
                                          (_selectedInputTab == 'fwip' ||
                                              _selectedInputTab == 'material')
                                          ? 'Qty'
                                          : 'Sak',
                                      showBerat:
                                          _selectedInputTab != 'fwip' &&
                                          _selectedInputTab != 'material',
                                      showLabel:
                                          _selectedInputTab != 'material',
                                    ),
                                    const SizedBox(height: 6),
                                    ProductionInputGrandTotalBar(
                                      totalLabel: grandLabel,
                                      totalSak: grandSak,
                                      totalBerat: grandBerat,
                                      color: _kInjectPrimary,
                                      sakLabel: 'Qty',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_selectedInputTab == 'material')
                                FloatingActionButton(
                                  heroTag: 'fab_add_inject_material',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kInjectPrimary,
                                  foregroundColor: Colors.white,
                                  onPressed: locked
                                      ? null
                                      : () => _openAddMaterialDialog(vm),
                                  child: const Icon(Icons.add),
                                )
                              else
                                FloatingActionButton(
                                  heroTag: 'fab_scan_inject_input',
                                  mini: true,
                                  backgroundColor: locked
                                      ? Colors.grey.shade300
                                      : _kInjectPrimary,
                                  foregroundColor: Colors.white,
                                  onPressed: locked || vm.isLookupLoading
                                      ? null
                                      : _openScanDialog,
                                  child: vm.isLookupLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.qr_code_scanner),
                                ),
                            ],
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

  Widget _buildActiveInputTab({
    required InjectProductionInputViewModel vm,
    required bool locked,
    required bool canDelete,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required Map<String, List<BrokerItem>> brokerGroups,
    required Map<String, List<MixerItem>> mixerGroups,
    required Map<String, List<GilinganItem>> gilinganGroups,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
    required BoxConstraints constraints,
  }) {
    switch (_selectedInputTab) {
      case 'fwip':
        return _buildFwipTab(
          vm: vm,
          fwipGroups: fwipGroups,
          constraints: constraints,
        );
      case 'broker':
        return _buildLabelGroupTab<BrokerItem>(
          groups: brokerGroups,
          emptyMessage: 'Belum ada label Broker',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempBroker.contains(item) ||
                  vm.tempBrokerPartial.contains(item);
              return ProductionSakChip(
                label: item.noBroker ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempBrokerItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'mixer':
        return _buildLabelGroupTab<MixerItem>(
          groups: mixerGroups,
          emptyMessage: 'Belum ada label Mixer',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempMixer.contains(item) ||
                  vm.tempMixerPartial.contains(item);
              return ProductionSakChip(
                label: item.noMixer ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempMixerItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'gilingan':
        return _buildLabelGroupTab<GilinganItem>(
          groups: gilinganGroups,
          emptyMessage: 'Belum ada label Gilingan',
          constraints: constraints,
          tileBuilder: (key, items) => ProductionInputGroupTile(
            title: key,
            headerSubtitle:
                (items.isNotEmpty ? items.first.namaJenis : '-') ?? '-',
            tileMetrics: [
              (
                Icons.scale_outlined,
                '${items.fold<double>(0, (s, i) => s + (i.berat ?? 0)).toStringAsFixed(1)} kg',
              ),
            ],
            color: _kInjectPrimary,
            isTemp: vm.hasTemporaryDataForLabel(key),
            expandable: true,
            isPartialGroup: items.any((x) => x.isPartialRow),
            detailsBuilder: () => [],
            chipItemsBuilder: () => items.map((item) {
              final isTemp =
                  vm.tempGilingan.contains(item) ||
                  vm.tempGilinganPartial.contains(item);
              return ProductionSakChip(
                label: item.noGilingan ?? '-',
                berat: item.berat,
                isTemp: isTemp,
                isPartial: item.isPartialRow,
                onDelete: isTemp ? () => vm.deleteTempGilinganItem(item) : null,
              );
            }).toList(),
          ),
        );
      case 'material':
        return _buildMaterialTab(
          vm: vm,
          locked: locked,
          canDelete: canDelete,
          materialAll: materialAll,
          tempMaterialIds: tempMaterialIds,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFwipTab({
    required InjectProductionInputViewModel vm,
    required Map<String, List<FurnitureWipItem>> fwipGroups,
    required BoxConstraints constraints,
  }) {
    return ProductionOutputCategoryContent(
      footer: const SizedBox.shrink(),
      child: fwipGroups.isEmpty
          ? const Center(
              child: Text('Tidak ada data', style: TextStyle(fontSize: 11)),
            )
          : GridView(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 380 ? 2 : 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 72,
              ),
              children: fwipGroups.entries.map((entry) {
                final hasPartial = entry.value.any((x) => x.isPartialRow);
                return ProductionInputGroupTile(
                  title: entry.key,
                  headerSubtitle:
                      (entry.value.isNotEmpty
                          ? entry.value.first.namaJenis
                          : '-') ??
                      '-',
                  tileMetrics: [
                    (
                      Icons.inventory_2_outlined,
                      '${entry.value.fold<int>(0, (s, i) => s + (i.pcs ?? 0))} pcs',
                    ),
                  ],
                  color: _kInjectPrimary,
                  isTemp: vm.hasTemporaryDataForLabel(entry.key),
                  expandable: !hasPartial,
                  isPartialGroup: hasPartial,
                  partialReference: hasPartial
                      ? (entry.value
                                .firstWhere((x) => x.isPartialRow)
                                .noFurnitureWIP ??
                            '-')
                      : null,
                  detailsBuilder: () => [],
                  chipItemsBuilder: () {
                    final dbItems =
                        vm
                            .inputsOf(widget.noProduksi)
                            ?.furnitureWip
                            .where((x) => _fwipTitleKey(x) == entry.key) ??
                        const [];
                    final items = [
                      ...vm.tempFurnitureWipPartial.where(
                        (x) => _fwipTitleKey(x) == entry.key,
                      ),
                      ...dbItems,
                      ...vm.tempFurnitureWip.where(
                        (x) => _fwipTitleKey(x) == entry.key,
                      ),
                    ];
                    return items.map((item) {
                      final isTemp =
                          vm.tempFurnitureWip.contains(item) ||
                          vm.tempFurnitureWipPartial.contains(item);
                      return ProductionSakChip(
                        label: item.noFurnitureWIP ?? '-',
                        berat: item.berat,
                        isTemp: isTemp,
                        isPartial: item.isPartialRow,
                        onDelete: isTemp
                            ? () => vm.deleteTempFurnitureWipItem(item)
                            : null,
                      );
                    }).toList();
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLabelGroupTab<T>({
    required Map<String, List<T>> groups,
    required String emptyMessage,
    required BoxConstraints constraints,
    required Widget Function(String key, List<T> items) tileBuilder,
  }) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return GridView(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: constraints.maxWidth < 380 ? 2 : 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 72,
      ),
      children: groups.entries.map((e) => tileBuilder(e.key, e.value)).toList(),
    );
  }

  Widget _buildMaterialTab({
    required InjectProductionInputViewModel vm,
    required bool locked,
    required bool canDelete,
    required List<CabinetMaterialItem> materialAll,
    required Set<int> tempMaterialIds,
  }) {
    if (materialAll.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada material kabinet.\nTambah dengan tombol + di bawah.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: materialAll.length,
      itemBuilder: (context, index) {
        final item = materialAll[index];
        final id = item.IdCabinetMaterial ?? 0;
        final isTemp = id == 0 || tempMaterialIds.contains(id);
        return _MaterialListTile(
          item: item,
          isTemp: isTemp,
          onDeleteTemp: isTemp
              ? () {
                  vm.deleteTempCabinetMaterialItem(item);
                  _showSnack(
                    '✅ Material TEMP dihapus',
                    backgroundColor: Colors.green,
                  );
                }
              : null,
          onDeleteExisting: (!isTemp && canDelete)
              ? () => _deleteExistingMaterial(vm, item)
              : null,
        );
      },
    );
  }

  // ── Toolbar skeleton ─────────────────────────────────────────────────────

  Widget _buildToolbarSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: Colors.grey.shade300, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _skeletonBox(w: 72, h: 20, r: 20),
              const SizedBox(width: 16),
              _skeletonBox(w: 140, h: 14, r: 4),
              const SizedBox(width: 10),
              _skeletonBox(w: 100, h: 14, r: 4),
              const Spacer(),
              _skeletonBox(w: 64, h: 24, r: 6),
              const SizedBox(width: 6),
              _skeletonBox(w: 64, h: 24, r: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({required double w, required double h, double r = 4}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  // ── Bucket print ──────────────────────────────────────────────────────────

  List<_PrintableLabelEntry> _buildPrintableEntries(String label) {
    final data = _bucketStates[label];
    if (data == null) return [];
    final outputs = _header?.outputs ?? const [];
    final singleOutputJenis = outputs.length == 1
        ? outputs.first.namaJenis
        : '';
    String resolveJenis(String fromLabel) =>
        fromLabel.isNotEmpty ? fromLabel : singleOutputJenis;
    final entries = <_PrintableLabelEntry>[];
    for (final c in data.labelsFwip) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: resolveJenis(c.namaJenis),
          category: 'Furniture WIP',
          pdfUrl: ApiConstants.furnitureWipLabelPdf(c.code),
          feature: 'furniture_wip',
          markAsPrinted: () => FurnitureWipRepository().markAsPrinted(c.code),
          pcs: c.pcs,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in data.labelsBarangJadi) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Barang Jadi',
          pdfUrl: ApiConstants.packingLabelPdf(c.code),
          feature: 'packing',
          markAsPrinted: () =>
              PackingRepository(api: ApiClient()).markAsPrinted(c.code),
          pcs: c.pcs,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in data.labelsBonggolan) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Bonggolan',
          pdfUrl: ApiConstants.bonggolanLabelPdf(c.code),
          feature: 'bonggolan',
          markAsPrinted: () => BonggolanRepository().markAsPrinted(c.code),
          berat: c.berat,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in data.labelsReject) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Reject',
          pdfUrl: ApiConstants.rejectLabelPdf(c.code),
          feature: 'reject',
          markAsPrinted: () =>
              RejectRepository(api: ApiClient()).markAsPrinted(c.code),
          berat: c.berat,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    return entries;
  }

  List<_PrintableLabelEntry> _buildPrintableEntriesFromBatch(
    InjectBatchItem batch,
  ) {
    final outputs = _header?.outputs ?? const [];
    final singleOutputJenis = outputs.length == 1
        ? outputs.first.namaJenis
        : '';
    String resolveJenis(String fromLabel) =>
        fromLabel.isNotEmpty ? fromLabel : singleOutputJenis;
    final entries = <_PrintableLabelEntry>[];
    for (final c in batch.labels.furnitureWip) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: resolveJenis(c.namaJenis),
          category: 'Furniture WIP',
          pdfUrl: ApiConstants.furnitureWipLabelPdf(c.code),
          feature: 'furniture_wip',
          markAsPrinted: () => FurnitureWipRepository().markAsPrinted(c.code),
          pcs: c.pcs,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in batch.labels.barangJadi) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Barang Jadi',
          pdfUrl: ApiConstants.packingLabelPdf(c.code),
          feature: 'packing',
          markAsPrinted: () =>
              PackingRepository(api: ApiClient()).markAsPrinted(c.code),
          pcs: c.pcs,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in batch.labels.bonggolan) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Bonggolan',
          pdfUrl: ApiConstants.bonggolanLabelPdf(c.code),
          feature: 'bonggolan',
          markAsPrinted: () => BonggolanRepository().markAsPrinted(c.code),
          berat: c.berat,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    for (final c in batch.labels.reject) {
      entries.add(
        _PrintableLabelEntry(
          code: c.code,
          namaJenis: c.namaJenis,
          category: 'Reject',
          pdfUrl: ApiConstants.rejectLabelPdf(c.code),
          feature: 'reject',
          markAsPrinted: () =>
              RejectRepository(api: ApiClient()).markAsPrinted(c.code),
          berat: c.berat,
          hasBeenPrinted: c.hasBeenPrinted,
        ),
      );
    }
    return entries;
  }

  void _openBucketPrintDialog(BuildContext ctx, String label) {
    final entries = _buildPrintableEntries(label);
    if (entries.isEmpty) return;
    showDialog<void>(
      context: ctx,
      builder: (_) => _BucketPrintDialog(
        hourLabel: label,
        entries: entries,
        onPrint: (selected) => _printLabelsBatch(selected),
      ),
    );
  }

  Future<void> _printLabelsBatch(List<_PrintableLabelEntry> entries) async {
    if (entries.isEmpty) return;
    final lockApi = LabelPrintLockApi();
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    // Acquire locks for all labels before opening the viewer
    final acquiredCodes = <String>{};
    for (final entry in entries) {
      if (!mounted) break;
      try {
        await lockApi.acquire(entry.code);
        acquiredCodes.add(entry.code);
      } catch (e) {
        if (mounted) {
          _showSnack(
            'Gagal lock ${entry.code}: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }

    // Track which labels were printed (synchronous, so finally block is accurate)
    final printedCodes = <String>{};

    // Build per-label callbacks — fire-and-forget async inside VoidCallback
    final callbacks = entries.map((entry) {
      return () {
            printedCodes.add(entry.code);
            () async {
              var needsIncrement = false;
              var needsRelease = false;
              try {
                final count = await entry.markAsPrinted();
                if (count != null) lockVm.setPrintCount(entry.code, count);
              } catch (_) {
                needsIncrement = true;
              }
              try {
                await lockApi.release(entry.code);
              } catch (_) {
                needsRelease = true;
              }
              if (needsIncrement || needsRelease) {
                await queue.enqueue(
                  feature: entry.feature,
                  noLabel: entry.code,
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
        pdfUrls: entries.map((e) => Uri.parse(e.pdfUrl)).toList(),
        title: 'Cetak ${entries.length} Label',
        onPrintedCallbacks: callbacks,
      );
    } finally {
      // Release locks for labels that were NOT printed (user cancelled / failed)
      for (final entry in entries) {
        if (acquiredCodes.contains(entry.code) &&
            !printedCodes.contains(entry.code)) {
          () async {
            try {
              await lockApi.release(entry.code);
            } catch (_) {
              await queue.enqueue(
                feature: entry.feature,
                noLabel: entry.code,
                needsReleaseLock: true,
              );
            }
          }().ignore();
        }
      }
    }
  }

  // ── Output panel ───────────────────────────────────────────────────────────

  Widget _buildOutputPanel() {
    return Container(
      decoration: productionPanelDecoration(
        borderColor: _kInjectOutput.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            child: Row(
              children: [
                productionSectionHeader(
                  Icons.output_rounded,
                  'Label Output',
                  iconColor: _kInjectOutput,
                  primaryColor: _kInjectPrimary,
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1, color: _kInjectBorder),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ProductionInputCategoryBlock(
                color: _kInjectOutput,
                isLoading: false,
                showBorder: false,
                contentPadding: EdgeInsets.zero,
                child: _buildBucketOutputList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBucketOutputList() {
    if (_bucketLabelOrder.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data jam produksi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return _buildHourlyOutputTimeline<_BucketLabelEntry>(
      groups: _bucketLabelOrder.map((label) {
        final data = _bucketStates[label];
        final codes = <String>[
          ...?data?.labelsFwip.map((c) => c.code),
          ...?data?.labelsBarangJadi.map((c) => c.code),
          ...?data?.labelsBonggolan.map((c) => c.code),
          ...?data?.labelsReject.map((c) => c.code),
        ];
        return _HourlyTimelineGroup<_BucketLabelEntry>(
          label: label,
          items: const [],
          summaryText: codes.isEmpty ? null : codes.join(' · '),
        );
      }).toList(),
      emptyRangeMessage: 'Belum ada output',
      icon: Icons.schedule_outlined,
      summaryTextBuilder: (items) => '',
      tileBuilder: (_) => const SizedBox.shrink(),
      hourPcsSectionBuilder: (label) {
        final data = _bucketStates[label];
        if (data == null) return const SizedBox.shrink();
        final isLastBucket =
            _bucketLabelOrder.isNotEmpty && _bucketLabelOrder.last == label;
        return _HourlyPcsSection(
          data: data,
          headerOutputs: _header?.outputs ?? const [],
          pplByJenis: _pcsPerLabelData?.pplByJenis ?? const {},
          isLastBucket: isLastBucket,
          onSubmit:
              (
                jenisItems,
                berat,
                cycleTime,
                counter,
                beratBonggolan,
                beratReject,
                idRejectBonggolan,
                idRejectReject,
                namaBonggolan,
                namaReject,
              ) => _onBucketSubmit(
                label,
                jenisItems,
                berat,
                cycleTime,
                counter,
                beratBonggolan,
                beratReject,
                idRejectBonggolan,
                idRejectReject,
                namaBonggolan: namaBonggolan,
                namaReject: namaReject,
                isLastBucket: isLastBucket,
              ),
          onPrint: (ctx) => _openBucketPrintDialog(ctx, label),
          counterCurrent: _pcsPerLabelData?.counterCurrent,
          standarBerat: _pcsPerLabelData?.standarBerat,
          standarCycleTime: _pcsPerLabelData?.standarCycleTime,
        );
      },
      initiallyCollapsed: (label) {
        final status = _bucketStates[label]?.status;
        return status != _HourlyBucketStatus.available;
      },
      cardColorBuilder: (label) {
        final data = _bucketStates[label];
        if (data == null) return null;
        switch (data.status) {
          case _HourlyBucketStatus.submitted:
            return const Color(0xFF15803D);
          case _HourlyBucketStatus.available:
            return data.isOverdue ? const Color(0xFFB45309) : _kInjectPrimary;
          case _HourlyBucketStatus.expired:
            return const Color(0xFFDC2626);
          case _HourlyBucketStatus.locked:
            return null;
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<InjectProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);
        final perm = context.watch<PermissionViewModel>();
        final locked = _header?.isLocked == true;
        final canDelete = perm.can('label_crusher:delete') && !locked;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            // ignore: use_build_context_synchronously
            final nav = Navigator.of(this.context);
            final canPop = await _onWillPop();
            if (canPop && mounted) nav.pop();
          },
          child: Scaffold(
            backgroundColor: _kInjectSurface,
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                if (_header == null)
                  _buildToolbarSkeleton()
                else
                  ProductionWorkspaceToolbar(
                    isLocked: locked,
                    idMesin: _header?.idMesin,
                    namaJenis: _header?.namaJenis ?? _header?.namaMesin,
                    namaJenisList: (_header?.outputs ?? [])
                        .map((o) => o.namaJenis)
                        .toList(),
                    tglProduksi: _header?.tglProduksi,
                    shift: _header?.shift,
                    hourStart: _header?.hourStart,
                    hourEnd: _header?.hourEnd,
                    showTimeInfo: false,
                    primaryColor: _kInjectPrimary,
                    produksiStatus: _header?.produksiStatus,
                    onGanti: _canTerminate ? _openSplitTimeDialog : null,
                    gantiDisabledReason: _canTerminate
                        ? null
                        : 'Tidak dapat ganti produksi: data pada jam saat ini sudah diinput. Tunggu jam berikutnya.',
                    onTerminate: _canTerminate ? _openTerminateDialog : null,
                    terminateDisabledReason: _canTerminate
                        ? null
                        : 'Tidak dapat terminate: data pada jam saat ini sudah diinput. Tunggu jam berikutnya.',
                    onRiwayat: _openTimelineDialog,
                    onRefresh: () {
                      vm.loadInputs(widget.noProduksi, force: true);
                      _showSnack('Data di-refresh');
                    },
                    trailingActions: const [],
                  ),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (err != null) {
                        return Center(
                          child: Text('Gagal memuat inputs:\n$err'),
                        );
                      }

                      final fwipAll = loading
                          ? <FurnitureWipItem>[]
                          : [
                              ...vm.tempFurnitureWip.reversed,
                              ...vm.tempFurnitureWipPartial.reversed,
                              ...?inputs?.furnitureWip,
                            ];
                      final brokerAll = loading
                          ? <BrokerItem>[]
                          : [
                              ...vm.tempBroker.reversed,
                              ...vm.tempBrokerPartial.reversed,
                              ...?inputs?.broker,
                            ];
                      final mixerAll = loading
                          ? <MixerItem>[]
                          : [
                              ...vm.tempMixer.reversed,
                              ...vm.tempMixerPartial.reversed,
                              ...?inputs?.mixer,
                            ];
                      final gilinganAll = loading
                          ? <GilinganItem>[]
                          : [
                              ...vm.tempGilingan.reversed,
                              ...vm.tempGilinganPartial.reversed,
                              ...?inputs?.gilingan,
                            ];
                      final tempMat = vm.tempCabinetMaterial;
                      final dbMat =
                          inputs?.cabinetMaterial ??
                          const <CabinetMaterialItem>[];
                      final materialAll = <CabinetMaterialItem>[
                        ...tempMat,
                        ...dbMat,
                      ];
                      final tempMaterialIds = tempMat
                          .map((x) => x.IdCabinetMaterial ?? 0)
                          .where((id) => id > 0)
                          .toSet();

                      final fwipGroups = _groupBy(fwipAll, _fwipTitleKey);
                      final brokerGroups = _groupBy(brokerAll, _brokerTitleKey);
                      final mixerGroups = _groupBy(mixerAll, _mixerTitleKey);
                      final gilinganGroups = _groupBy(
                        gilinganAll,
                        _gilinganTitleKey,
                      );

                      final outputPanel = Expanded(child: _buildOutputPanel());
                      final inputPanel = Expanded(
                        child: _buildInputPanel(
                          vm: vm,
                          locked: locked,
                          loading: loading,
                          canDelete: canDelete,
                          fwipGroups: fwipGroups,
                          brokerGroups: brokerGroups,
                          mixerGroups: mixerGroups,
                          gilinganGroups: gilinganGroups,
                          materialAll: materialAll,
                          tempMaterialIds: tempMaterialIds,
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            inputPanel,
                            const SizedBox(width: 16),
                            outputPanel,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Ganti mode ────────────────────────────────────────────────────────────────

enum _GantiMode { cetakan, warnaAndMaterial }

class _GantiModeDialog extends StatelessWidget {
  const _GantiModeDialog({
    this.currentCetakan,
    this.currentWarna,
    this.currentMaterial,
  });

  final String? currentCetakan;
  final String? currentWarna;
  final String? currentMaterial;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0F766E);

    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pilih Jenis Ganti',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((currentCetakan ?? '').isNotEmpty) ...[
                Text(
                  'Produksi saat ini: ${currentCetakan ?? '-'}'
                  '${(currentWarna ?? '').isNotEmpty ? ' · ${currentWarna}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              option(
                icon: Icons.view_in_ar_rounded,
                title: 'Ganti Cetakan',
                subtitle: 'Pilih cetakan, warna & material baru dari awal',
                onTap: () => Navigator.of(context).pop(_GantiMode.cetakan),
              ),
              const SizedBox(height: 8),
              option(
                icon: Icons.palette_outlined,
                title: 'Ganti Warna & Material',
                subtitle: 'Cetakan tetap sama, hanya ganti warna & material',
                onTap: () =>
                    Navigator.of(context).pop(_GantiMode.warnaAndMaterial),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Map<K, List<T>> _groupBy<K, T>(Iterable<T> items, K Function(T) keyFn) {
  final map = <K, List<T>>{};
  for (final item in items) {
    (map[keyFn(item)] ??= []).add(item);
  }
  return map;
}

int? _parseMinutes(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return (hour * 60) + minute;
}

String _formatHourMinute(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Widget _buildHourlyOutputTimeline<T>({
  required List<_HourlyTimelineGroup<T>> groups,
  required String emptyRangeMessage,
  required IconData icon,
  required String Function(List<T> items) summaryTextBuilder,
  required Widget Function(T item) tileBuilder,
  String Function(T item)? categoryKeyBuilder,
  List<String>? categoryOrder,
  Widget Function(String categoryKey, int count)? categoryHeaderBuilder,
  String Function(T item)? subGroupKeyBuilder,
  Widget Function(String subGroupKey)? subGroupHeaderBuilder,
  Widget Function(String label)? hourPcsSectionBuilder,
  Widget? Function(String label)? headerActionBuilder,
  bool Function(String label)? initiallyCollapsed,
  Color? Function(String label)? cardColorBuilder,
}) {
  if (groups.isEmpty) {
    return Center(
      child: Text(
        emptyRangeMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.all(6),
    itemCount: groups.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final group = groups[index];
      final startCollapsed = initiallyCollapsed?.call(group.label) ?? false;
      final accentColor = cardColorBuilder?.call(group.label);
      return _CollapsibleHourlyCard<T>(
        group: group,
        icon: icon,
        summaryTextBuilder: summaryTextBuilder,
        tileBuilder: tileBuilder,
        categoryKeyBuilder: categoryKeyBuilder,
        categoryOrder: categoryOrder,
        categoryHeaderBuilder: categoryHeaderBuilder,
        subGroupKeyBuilder: subGroupKeyBuilder,
        subGroupHeaderBuilder: subGroupHeaderBuilder,
        hourPcsSectionBuilder: hourPcsSectionBuilder,
        headerActionBuilder: headerActionBuilder,
        initiallyCollapsed: startCollapsed,
        accentColor: accentColor,
      );
    },
  );
}

class _CollapsibleHourlyCard<T> extends StatefulWidget {
  const _CollapsibleHourlyCard({
    required this.group,
    required this.icon,
    required this.summaryTextBuilder,
    required this.tileBuilder,
    this.categoryKeyBuilder,
    this.categoryOrder,
    this.categoryHeaderBuilder,
    this.subGroupKeyBuilder,
    this.subGroupHeaderBuilder,
    this.hourPcsSectionBuilder,
    this.headerActionBuilder,
    this.initiallyCollapsed = false,
    this.accentColor,
  });

  final _HourlyTimelineGroup<T> group;
  final IconData icon;
  final String Function(List<T> items) summaryTextBuilder;
  final Widget Function(T item) tileBuilder;
  final String Function(T item)? categoryKeyBuilder;
  final List<String>? categoryOrder;
  final Widget Function(String categoryKey, int count)? categoryHeaderBuilder;
  final String Function(T item)? subGroupKeyBuilder;
  final Widget Function(String subGroupKey)? subGroupHeaderBuilder;
  final Widget Function(String label)? hourPcsSectionBuilder;
  final Widget? Function(String label)? headerActionBuilder;
  final bool initiallyCollapsed;
  final Color? accentColor;

  @override
  State<_CollapsibleHourlyCard<T>> createState() =>
      _CollapsibleHourlyCardState<T>();
}

class _CollapsibleHourlyCardState<T> extends State<_CollapsibleHourlyCard<T>> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final hasItems = group.items.isNotEmpty;
    final statusColor =
        widget.accentColor ??
        (hasItems ? _kInjectOutput : const Color(0xFF94A3B8));
    final summary =
        widget.group.summaryText ?? widget.summaryTextBuilder(group.items);

    final borderColor = widget.accentColor != null
        ? widget.accentColor!.withValues(alpha: 0.30)
        : (hasItems ? const Color(0xFFD9E3E7) : const Color(0xFFE2E8F0));
    final bgColor = widget.accentColor != null
        ? widget.accentColor!.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.78);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (always visible, tappable) ──────────────────
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            borderRadius: _collapsed
                ? BorderRadius.circular(12)
                : const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 13, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          group.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summary,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (widget.headerActionBuilder != null)
                    widget.headerActionBuilder!(group.label) ??
                        const SizedBox.shrink(),
                  if (hasItems || widget.hourPcsSectionBuilder != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: statusColor.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Collapsible body ────────────────────────────────────
          if (!_collapsed) ...[
            const Divider(height: 1, color: Color(0xFFEEF2F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasItems) ...[
                    if (widget.categoryKeyBuilder != null)
                      _buildCategorised(group.items)
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            group.items
                                .map(widget.tileBuilder)
                                .expand((w) => [w, const SizedBox(height: 4)])
                                .toList()
                              ..removeLast(),
                      ),
                  ],
                  if (widget.hourPcsSectionBuilder != null) ...[
                    if (hasItems) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEF2F5)),
                      const SizedBox(height: 8),
                    ],
                    widget.hourPcsSectionBuilder!(group.label),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorised(List<T> items) {
    final keyBuilder = widget.categoryKeyBuilder!;
    final order = <String>[];
    final catMap = <String, List<T>>{};
    for (final item in items) {
      final key = keyBuilder(item);
      if (!catMap.containsKey(key)) {
        order.add(key);
        catMap[key] = [];
      }
      catMap[key]!.add(item);
    }
    final catOrder = widget.categoryOrder;
    if (catOrder != null) {
      order.sort((a, b) {
        final ai = catOrder.indexOf(a);
        final bi = catOrder.indexOf(b);
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });
    }
    final widgets = <Widget>[];
    for (var ci = 0; ci < order.length; ci++) {
      final cat = order[ci];
      final catItems = catMap[cat]!;
      if (widget.categoryHeaderBuilder != null) {
        widgets.add(widget.categoryHeaderBuilder!(cat, catItems.length));
        widgets.add(const SizedBox(height: 4));
      }
      // Sub-group by namaJenis if builder provided
      final sgKeyBuilder = widget.subGroupKeyBuilder;
      if (sgKeyBuilder != null) {
        final sgOrder = <String>[];
        final sgMap = <String, List<T>>{};
        for (final item in catItems) {
          final key = sgKeyBuilder(item);
          if (!sgMap.containsKey(key)) {
            sgOrder.add(key);
            sgMap[key] = [];
          }
          sgMap[key]!.add(item);
        }
        for (var si = 0; si < sgOrder.length; si++) {
          final sg = sgOrder[si];
          final sgItems = sgMap[sg]!;
          if (widget.subGroupHeaderBuilder != null && sg.isNotEmpty) {
            widgets.add(widget.subGroupHeaderBuilder!(sg));
            widgets.add(const SizedBox(height: 4));
          }
          widgets.add(
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sgItems
                  .map(
                    (item) =>
                        SizedBox(width: 110, child: widget.tileBuilder(item)),
                  )
                  .toList(),
            ),
          );
          if (si < sgOrder.length - 1) widgets.add(const SizedBox(height: 8));
        }
      } else {
        for (var j = 0; j < catItems.length; j++) {
          widgets.add(widget.tileBuilder(catItems[j]));
          if (j < catItems.length - 1) widgets.add(const SizedBox(height: 4));
        }
      }
      if (ci < order.length - 1) widgets.add(const SizedBox(height: 8));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _HourlyTimelineGroup<T> {
  const _HourlyTimelineGroup({
    required this.label,
    required this.items,
    this.summaryText,
  });

  final String label;
  final List<T> items;
  final String? summaryText;
}

// ── Printable label entry ─────────────────────────────────────────────────────

class _PrintableLabelEntry {
  const _PrintableLabelEntry({
    required this.code,
    required this.namaJenis,
    required this.category,
    required this.pdfUrl,
    required this.feature,
    required this.markAsPrinted,
    this.pcs,
    this.berat,
    this.hasBeenPrinted = 0,
  });
  final String code;
  final String namaJenis;
  final String category;
  final String pdfUrl;
  final String feature;
  final Future<int?> Function() markAsPrinted;
  final int? pcs;
  final double? berat;
  final int hasBeenPrinted;
}

// ── Bucket label entry ────────────────────────────────────────────────────────

class _BucketLabelEntry {
  const _BucketLabelEntry({required this.category, required this.code});
  final String category;
  final String code;
}

// ── Hourly bucket state ────────────────────────────────────────────────────────

enum _HourlyBucketStatus { locked, available, submitted, expired }

class _HourlyBucketData {
  const _HourlyBucketData({
    required this.status,
    required this.carryOverIn,
    required this.pcsInput,
    required this.labelsCreated,
    required this.carryOverOut,
    this.isOverdue = false,
    this.berat,
    this.cycleTime,
    this.counter,
    this.beratBonggolan,
    this.namaBonggolan,
    this.beratReject,
    this.namaReject,
    this.carryOverInByJenis = const {},
    this.pcsInputByJenis = const {},
    this.carryOverOutByJenis = const {},
    this.labelsFwip = const [],
    this.labelsBarangJadi = const [],
    this.labelsBonggolan = const [],
    this.labelsReject = const [],
  });

  final _HourlyBucketStatus status;
  // true when bucket is the last incomplete bucket and current time has passed hourEnd
  final bool isOverdue;
  final int carryOverIn;
  final int pcsInput;
  final int labelsCreated;
  final int carryOverOut;
  final double? berat;
  final double? cycleTime;
  final int? counter;
  final double? beratBonggolan;
  final String? namaBonggolan;
  final double? beratReject;
  final String? namaReject;
  final Map<int, int> carryOverInByJenis;
  final Map<int, int> pcsInputByJenis;
  final Map<int, int> carryOverOutByJenis;
  final List<InjectBatchLabelItem> labelsFwip;
  final List<InjectBatchLabelItem> labelsBarangJadi;
  final List<InjectBatchLabelItem> labelsBonggolan;
  final List<InjectBatchLabelItem> labelsReject;
}

class _JenisSubmitItem {
  const _JenisSubmitItem({
    required this.jenis,
    required this.pcs,
    required this.carryOverIn,
  });
  final InjectOutputJenis jenis;
  final int pcs;
  final int carryOverIn;
}

// ── Hourly Pcs Section ────────────────────────────────────────────────────────

class _HourlyPcsSection extends StatefulWidget {
  const _HourlyPcsSection({
    required this.data,
    required this.headerOutputs,
    required this.onSubmit,
    this.pplByJenis = const {},
    this.isLastBucket = false,
    this.onPrint,
    this.counterCurrent,
    this.standarBerat,
    this.standarCycleTime,
  });

  final _HourlyBucketData data;
  final List<InjectOutputJenis> headerOutputs;
  final Map<int, int> pplByJenis;
  final bool isLastBucket;
  final void Function(BuildContext ctx)? onPrint;
  final int? counterCurrent;
  final double? standarBerat;
  final double? standarCycleTime;
  final Future<void> Function(
    List<_JenisSubmitItem> jenisItems,
    double? berat,
    double? cycleTime,
    int? counter,
    double? beratBonggolan,
    double? beratReject,
    int? idRejectBonggolan,
    int? idRejectReject,
    String? namaBonggolan,
    String? namaReject,
  )
  onSubmit;

  @override
  State<_HourlyPcsSection> createState() => _HourlyPcsSectionState();
}

class _HourlyPcsSectionState extends State<_HourlyPcsSection> {
  final Map<int, TextEditingController> _jenisCtrl = {};
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _beratBonggolanCtrl = TextEditingController();
  final _beratRejectCtrl = TextEditingController();
  int? _counterValue;
  JenisBonggolan? _bonggolanJenis;
  RejectType? _rejectJenis;
  bool _isSubmitting = false;
  bool _beratError = false;
  bool _cycleError = false;
  bool _counterError = false;

  @override
  void initState() {
    super.initState();
    _syncJenisControllers(widget.headerOutputs);
  }

  @override
  void didUpdateWidget(_HourlyPcsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncJenisControllers(widget.headerOutputs);
  }

  void _syncJenisControllers(List<InjectOutputJenis> outputs) {
    for (final jenis in outputs) {
      if (!_jenisCtrl.containsKey(jenis.idJenis)) {
        final ctrl = TextEditingController();
        ctrl.addListener(() {
          if (mounted) setState(() {});
        });
        _jenisCtrl[jenis.idJenis] = ctrl;
      }
    }
  }

  int _carryInForJenis(int idJenis) {
    final byJenis = widget.data.carryOverInByJenis;
    if (byJenis.containsKey(idJenis)) return byJenis[idJenis]!;
    if (widget.headerOutputs.length == 1) return widget.data.carryOverIn;
    return 0;
  }

  @override
  void dispose() {
    for (final ctrl in _jenisCtrl.values) ctrl.dispose();
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    _beratBonggolanCtrl.dispose();
    _beratRejectCtrl.dispose();
    super.dispose();
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (widget.headerOutputs.isEmpty) return;

    final jenisItems = <_JenisSubmitItem>[];
    for (final jenis in widget.headerOutputs) {
      final pcs =
          int.tryParse(_jenisCtrl[jenis.idJenis]?.text.trim() ?? '') ?? 0;
      if (pcs < 0) return;
      jenisItems.add(
        _JenisSubmitItem(
          jenis: jenis,
          pcs: pcs,
          carryOverIn: _carryInForJenis(jenis.idJenis),
        ),
      );
    }

    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final cycleTime = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
    final counter = _counterValue;

    final hasBeratErr = berat == null;
    final hasCycleErr = cycleTime == null;
    final hasCounterErr = counter == null;

    if (hasBeratErr || hasCycleErr || hasCounterErr) {
      setState(() {
        _beratError = hasBeratErr;
        _cycleError = hasCycleErr;
        _counterError = hasCounterErr;
      });
      if (hasBeratErr) {
        _showValidationError('Berat harus diisi');
      } else if (hasCycleErr) {
        _showValidationError('Cycle Time harus diisi');
      } else {
        _showValidationError('Counter harus dipilih');
      }
      return;
    }

    setState(() {
      _beratError = false;
      _cycleError = false;
      _counterError = false;
    });

    // ── Counter odometer validation (must be >= counterCurrent) ──
    final minCounter = widget.counterCurrent;
    if (minCounter != null && counter < minCounter) {
      setState(() => _counterError = true);
      _showValidationError(
        'Counter tidak boleh kurang dari $minCounter (odometer saat ini)',
      );
      return;
    }

    // ── Standar warning (berat & cycle time) ────────────────────
    final standarBerat = widget.standarBerat;
    final standarCycle = widget.standarCycleTime;
    final beratWarning = standarBerat != null && berat != standarBerat;
    final cycleWarning = standarCycle != null && cycleTime != standarCycle;
    if (beratWarning || cycleWarning) {
      final lines = <String>[];
      if (beratWarning) {
        lines.add('• Berat: $berat gr (standar: $standarBerat gr)');
      }
      if (cycleWarning) {
        lines.add('• Cycle Time: $cycleTime sec (standar: $standarCycle sec)');
      }
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => _StandarWarningDialog(
          beratWarning: beratWarning
              ? (input: berat, standar: standarBerat)
              : null,
          cycleWarning: cycleWarning
              ? (input: cycleTime, standar: standarCycle)
              : null,
        ),
      );
      if (!mounted || proceed != true) return;
    }

    final beratBonggolan = widget.isLastBucket
        ? double.tryParse(_beratBonggolanCtrl.text.replaceAll(',', '.'))
        : null;
    final beratReject = widget.isLastBucket
        ? double.tryParse(_beratRejectCtrl.text.replaceAll(',', '.'))
        : null;

    int? idRejectBonggolan;
    int? idRejectReject;
    if (widget.isLastBucket) {
      if (beratBonggolan != null && beratBonggolan > 0) {
        final picked = _bonggolanJenis ?? await _showBonggolanJenisPicker();
        if (!mounted) return;
        if (picked == null) return;
        setState(() => _bonggolanJenis = picked);
        idRejectBonggolan = picked.idBonggolan;
      }
      if (beratReject != null && beratReject > 0) {
        final picked =
            _rejectJenis ?? await _showRejectTypePicker('Jenis Reject');
        if (!mounted) return;
        if (picked == null) return;
        setState(() => _rejectJenis = picked);
        idRejectReject = picked.idReject;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        jenisItems,
        berat,
        cycleTime,
        counter,
        beratBonggolan,
        beratReject,
        idRejectBonggolan,
        idRejectReject,
        _bonggolanJenis?.namaBonggolan,
        _rejectJenis?.namaReject,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.data.status) {
      case _HourlyBucketStatus.locked:
        return _buildLocked();
      case _HourlyBucketStatus.available:
        return _buildAvailable();
      case _HourlyBucketStatus.submitted:
        return _buildSubmitted();
      case _HourlyBucketStatus.expired:
        return _buildExpired();
    }
  }

  Future<JenisBonggolan?> _showBonggolanJenisPicker() async {
    final vm = context.read<JenisBonggolanViewModel>();
    await vm.ensureLoaded();
    if (!mounted) return null;
    return showDialog<JenisBonggolan>(
      context: context,
      builder: (ctx) => _BonggolanJenisPickerDialog(vm: vm),
    );
  }

  Future<RejectType?> _showRejectTypePicker(String title) async {
    final vm = context.read<RejectTypeViewModel>();
    await vm.ensureLoaded();
    if (!mounted) return null;
    return showDialog<RejectType>(
      context: context,
      builder: (ctx) => _RejectTypePickerDialog(title: title, vm: vm),
    );
  }

  Widget _readonlyChip({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(icon, size: 11, color: accent),
              const SizedBox(width: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpired() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFCA5A5)),
    ),
    child: Row(
      children: [
        Icon(Icons.cancel_outlined, size: 14, color: Colors.red.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Jam ini sudah lewat dan tidak diinput',
            style: TextStyle(fontSize: 11, color: Colors.red.shade600),
          ),
        ),
      ],
    ),
  );

  Widget _buildLocked() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Row(
      children: [
        Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Selesaikan range jam sebelumnya terlebih dahulu',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ],
    ),
  );

  Widget _buildAvailable() {
    final isOverdue = widget.data.isOverdue;
    final accent = isOverdue ? const Color(0xFFB45309) : _kInjectPrimary;
    const mutedColor = Color(0xFF9CA3AF);
    final outputs = widget.headerOutputs;
    final multiJenis = outputs.length > 1;

    // Build one input row per jenis
    Widget buildJenisRow(InjectOutputJenis jenis, {bool showLabel = false}) {
      final ctrl = _jenisCtrl[jenis.idJenis] ?? TextEditingController();
      final carryIn = _carryInForJenis(jenis.idJenis);
      final pcsTyped = int.tryParse(ctrl.text.trim()) ?? 0;
      final ppl = (widget.pplByJenis[jenis.idJenis] ?? 100).clamp(1, 999999);
      final carryOut = widget.isLastBucket ? 0 : (carryIn + pcsTyped) % ppl;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                jenis.namaJenis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _readonlyChip(
                  label: 'Carry Over Sebelumnya',
                  value: '$carryIn / $ppl pcs',
                  icon: Icons.arrow_forward,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jumlah Item Bagus (pcs)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan pcs...',
                          hintStyle: const TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                            fontWeight: FontWeight.w400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _readonlyChip(
                  label: 'Carry Over Sesudah',
                  value: '$carryOut pcs',
                  icon: Icons.arrow_forward,
                  accent: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFFBEB) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.30),
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.precision_manufacturing_outlined,
                size: 13,
                color: accent,
              ),
              const SizedBox(width: 5),
              Text(
                'Input Batch Produksi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Per-jenis input rows ──
          for (int i = 0; i < outputs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            buildJenisRow(outputs[i], showLabel: multiJenis),
          ],
          // ── Sisa Akhir Shift (last bucket only) ──────────────────
          if (widget.isLastBucket) ...[
            const SizedBox(height: 10),
            // Bonggolan: jenis (flex 3) + berat (flex 2) — pilih jenis dulu
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildJenisPicker(
                    label: 'Jenis Bonggolan',
                    selectedName: _bonggolanJenis?.namaBonggolan,
                    onTap: () async {
                      final picked = await _showBonggolanJenisPicker();
                      if (picked != null && mounted) {
                        setState(() => _bonggolanJenis = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _qcField(
                    label: 'Berat Bonggolan (kg)',
                    ctrl: _beratBonggolanCtrl,
                    hint: '0.0',
                    decimal: true,
                    enabled: _bonggolanJenis != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Reject: jenis (flex 3) + berat (flex 2) — pilih jenis dulu
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildJenisPicker(
                    label: 'Jenis Reject',
                    selectedName: _rejectJenis?.namaReject,
                    onTap: () async {
                      final picked = await _showRejectTypePicker(
                        'Jenis Reject',
                      );
                      if (picked != null && mounted) {
                        setState(() => _rejectJenis = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _qcField(
                    label: 'Berat Reject (kg)',
                    ctrl: _beratRejectCtrl,
                    hint: '0.0',
                    decimal: true,
                    enabled: _rejectJenis != null,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _qcField(
                  label: 'Berat (gr)',
                  ctrl: _beratCtrl,
                  hint: '0.0',
                  decimal: true,
                  isError: _beratError,
                  onChanged: () {
                    if (_beratError) setState(() => _beratError = false);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _qcField(
                  label: 'Cycle Time (sec)',
                  ctrl: _cycleCtrl,
                  hint: '0.0',
                  decimal: true,
                  isError: _cycleError,
                  onChanged: () {
                    if (_cycleError) setState(() => _cycleError = false);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildCounterField()),
            ],
          ),
          const SizedBox(height: 10),
          // ── Step 3/4: Simpan ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterField() {
    const accent = _kInjectPrimary;
    const errorColor = Color(0xFFDC2626);
    final hasValue = _counterValue != null;
    final minCounter = widget.counterCurrent;
    final borderColor = _counterError
        ? errorColor
        : hasValue
        ? accent
        : accent.withValues(alpha: 0.30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          minCounter != null ? 'Counter · min $minCounter' : 'Counter',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _counterError ? errorColor : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (_) => CounterPickerDialog(
                initialValue: _counterValue ?? (minCounter ?? 0),
                minValue: minCounter,
              ),
            );
            if (picked != null && mounted) {
              setState(() {
                _counterValue = picked;
                _counterError = false;
              });
            }
          },
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: _counterError ? const Color(0xFFFEF2F2) : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: borderColor,
                width: (_counterError || hasValue) ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasValue)
                  Text(
                    '$_counterValue',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  )
                else
                  Text(
                    _counterError ? 'Wajib dipilih' : 'Pilih',
                    style: TextStyle(
                      fontSize: 11,
                      color: _counterError ? errorColor : Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  size: 14,
                  color: _counterError
                      ? errorColor
                      : hasValue
                      ? accent
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _qcField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required bool decimal,
    bool enabled = true,
    bool isError = false,
    VoidCallback? onChanged,
  }) {
    const accent = _kInjectPrimary;
    const errorColor = Color(0xFFDC2626);
    const mutedColor = Color(0xFF9CA3AF);
    final borderColor = isError
        ? errorColor
        : enabled
        ? accent.withValues(alpha: 0.30)
        : accent.withValues(alpha: 0.20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isError
                ? errorColor
                : enabled
                ? const Color(0xFF374151)
                : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 30,
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            onChanged: onChanged != null ? (_) => onChanged() : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: mutedColor, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: borderColor,
                  width: isError ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: isError ? errorColor : accent,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: isError
                  ? const Color(0xFFFEF2F2)
                  : enabled
                  ? Colors.white
                  : const Color(0xFFF3F4F6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJenisPickerDisabled({
    required String label,
    required String? namaJenis,
  }) {
    const accent = Color(0xFF92400E);
    final hasValue = namaJenis != null && namaJenis.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: hasValue
                  ? accent.withValues(alpha: 0.30)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? namaJenis : '-',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? accent : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.expand_more, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJenisPicker({
    required String label,
    required String? selectedName,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFF92400E);
    final hasValue = selectedName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: hasValue ? accent : accent.withValues(alpha: 0.30),
                width: hasValue ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? selectedName : 'Pilih...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue ? accent : Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 14,
                  color: hasValue ? accent : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitted() {
    final data = widget.data;
    final hasLabels = data.labelsCreated > 0;
    const greenAccent = Color(0xFF15803D);
    final outputs = widget.headerOutputs;
    final multiJenis = outputs.length > 1;

    Widget buildJenisRowDisabled(InjectOutputJenis jenis) {
      final carryIn = data.carryOverInByJenis.containsKey(jenis.idJenis)
          ? data.carryOverInByJenis[jenis.idJenis]!
          : (outputs.length == 1 ? data.carryOverIn : 0);
      final pcsIn = data.pcsInputByJenis.containsKey(jenis.idJenis)
          ? data.pcsInputByJenis[jenis.idJenis]!
          : (outputs.length == 1 ? data.pcsInput : 0);
      final carryOut = data.carryOverOutByJenis.containsKey(jenis.idJenis)
          ? data.carryOverOutByJenis[jenis.idJenis]!
          : (outputs.length == 1 ? data.carryOverOut : 0);
      final ppl = (widget.pplByJenis[jenis.idJenis] ?? 100).clamp(1, 999999);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (multiJenis) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: greenAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                jenis.namaJenis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: greenAccent,
                ),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Carry Over Sebelumnya
              Expanded(
                child: _readonlyChip(
                  label: 'Carry Over Sebelumnya',
                  value: '$carryIn / $ppl pcs',
                  icon: Icons.arrow_forward,
                  accent: greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              // Jumlah Item Bagus — disabled TextField
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jumlah Item Bagus (pcs)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: TextEditingController(text: '$pcsIn'),
                        enabled: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: greenAccent.withValues(alpha: 0.25),
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: greenAccent.withValues(alpha: 0.25),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0FDF4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Carry Over Sesudah
              Expanded(
                child: _readonlyChip(
                  label: 'Carry Over Sesudah',
                  value: '$carryOut pcs',
                  icon: Icons.arrow_forward,
                  accent: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: hasLabels ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasLabels ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header status
          Row(
            children: [
              Icon(
                hasLabels ? Icons.check_circle_outline : Icons.save_outlined,
                size: 13,
                color: hasLabels ? greenAccent : Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Text(
                'Pcs Tersimpan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasLabels ? greenAccent : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Per-jenis rows (disabled form)
          for (int i = 0; i < outputs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            buildJenisRowDisabled(outputs[i]),
          ],
          // Sisa Akhir Shift — same layout as _buildAvailable but disabled
          if (widget.isLastBucket) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildJenisPickerDisabled(
                    label: 'Jenis Bonggolan',
                    namaJenis: data.namaBonggolan,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _qcField(
                    label: 'Berat Bonggolan (kg)',
                    ctrl: TextEditingController(
                      text: data.beratBonggolan != null
                          ? data.beratBonggolan!.toStringAsFixed(1)
                          : '',
                    ),
                    hint: '-',
                    decimal: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildJenisPickerDisabled(
                    label: 'Jenis Reject',
                    namaJenis: data.namaReject,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _qcField(
                    label: 'Berat Reject (kg)',
                    ctrl: TextEditingController(
                      text: data.beratReject != null
                          ? data.beratReject!.toStringAsFixed(1)
                          : '',
                    ),
                    hint: '-',
                    decimal: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFD1FAE5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _qcField(
                  label: 'Berat (gr)',
                  ctrl: TextEditingController(
                    text: data.berat != null
                        ? data.berat!.toStringAsFixed(1)
                        : '',
                  ),
                  hint: '-',
                  decimal: true,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _qcField(
                  label: 'Cycle Time (sec)',
                  ctrl: TextEditingController(
                    text: data.cycleTime != null
                        ? data.cycleTime!.toStringAsFixed(1)
                        : '',
                  ),
                  hint: '-',
                  decimal: true,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildCounterDisplay(data.counter)),
            ],
          ),
          if (hasLabels && widget.onPrint != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton.icon(
                onPressed: () => widget.onPrint!(context),
                style: FilledButton.styleFrom(
                  backgroundColor: greenAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 15),
                label: Text(
                  'Cetak Label',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterDisplay(int? counter) {
    const accent = _kInjectPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Counter',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.center,
          child: Text(
            counter != null ? '$counter' : '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: counter != null ? accent : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

class _JenisPickerForAutoCreate extends StatelessWidget {
  const _JenisPickerForAutoCreate({
    required this.options,
    required this.labelsCount,
    this.pcsPerLabel = 100,
  });

  final List<InjectOutputJenis> options;
  final int labelsCount;
  final int pcsPerLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kInjectOutput.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.label_outline,
                      size: 16,
                      color: _kInjectOutput,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Jenis Label',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Akan dibuat $labelsCount label (${labelsCount * pcsPerLabel} pcs)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
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
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kInjectBorder),
            ...options.asMap().entries.map((entry) {
              final i = entry.key;
              final o = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(o),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _kInjectOutput.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kInjectOutput,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.namaJenis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  '$pcsPerLabel pcs / label',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < options.length - 1)
                    const Divider(
                      height: 1,
                      color: _kInjectBorder,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Material list tile ─────────────────────────────────────────────────────────

class _MaterialListTile extends StatelessWidget {
  const _MaterialListTile({
    required this.item,
    required this.isTemp,
    this.onDeleteTemp,
    this.onDeleteExisting,
  });

  final CabinetMaterialItem item;
  final bool isTemp;
  final VoidCallback? onDeleteTemp;
  final VoidCallback? onDeleteExisting;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTemp ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTemp ? const Color(0xFFFFD54F) : const Color(0xFFE2E6EA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.Nama ?? 'Material',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jumlah: ${item.Jumlah ?? 0} ${item.NamaUOM ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (isTemp && onDeleteTemp != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
              onPressed: onDeleteTemp,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            )
          else if (!isTemp && onDeleteExisting != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              onPressed: onDeleteExisting,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

// ── Bucket print dialog ───────────────────────────────────────────────────────

class _BucketPrintDialog extends StatefulWidget {
  const _BucketPrintDialog({
    required this.hourLabel,
    required this.entries,
    required this.onPrint,
  });

  final String hourLabel;
  final List<_PrintableLabelEntry> entries;
  final void Function(List<_PrintableLabelEntry> selected) onPrint;

  @override
  State<_BucketPrintDialog> createState() => _BucketPrintDialogState();
}

class _BucketPrintDialogState extends State<_BucketPrintDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.entries.map((e) => e.code).toSet();
  }

  bool get _allSelected => _selected.length == widget.entries.length;

  void _toggleAll() => setState(() {
    if (_allSelected) {
      _selected.clear();
    } else {
      _selected.addAll(widget.entries.map((e) => e.code));
    }
  });

  static const _catColors = {
    'Furniture WIP': Color(0xFF0F766E),
    'Barang Jadi': Color(0xFF1D4ED8),
    'Bonggolan': Color(0xFF92400E),
    'Reject': Color(0xFFB91C1C),
  };
  static const _catOrder = [
    'Furniture WIP',
    'Barang Jadi',
    'Bonggolan',
    'Reject',
  ];

  @override
  Widget build(BuildContext context) {
    const accent = _kInjectOutput;

    final grouped = <String, List<_PrintableLabelEntry>>{};
    for (final e in widget.entries) {
      (grouped[e.category] ??= []).add(e);
    }

    final selectedEntries = widget.entries
        .where((e) => _selected.contains(e.code))
        .toList();
    final selectedCount = selectedEntries.length;

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
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.print_outlined,
                      color: accent,
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
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          widget.hourLabel,
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
                      foregroundColor: accent,
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
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            // ── Label list ───────────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                children: [
                  for (final cat in _catOrder)
                    if (grouped.containsKey(cat)) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (_catColors[cat] ?? accent).withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _catColors[cat] ?? accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Divider(
                                height: 1,
                                color: (_catColors[cat] ?? accent).withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final entry in grouped[cat]!) ...[
                        _LabelCheckTile(
                          entry: entry,
                          catColor: _catColors[cat] ?? accent,
                          isSelected: _selected.contains(entry.code),
                          onToggle: () => setState(() {
                            if (_selected.contains(entry.code)) {
                              _selected.remove(entry.code);
                            } else {
                              _selected.add(entry.code);
                            }
                          }),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            // ── Print button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton.icon(
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onPrint(selectedEntries);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
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

class _LabelCheckTile extends StatelessWidget {
  const _LabelCheckTile({
    required this.entry,
    required this.catColor,
    required this.isSelected,
    required this.onToggle,
  });

  final _PrintableLabelEntry entry;
  final Color catColor;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final printed = entry.hasBeenPrinted;
    final printColor = printed > 0
        ? const Color(0xFF15803D)
        : const Color(0xFF9CA3AF);
    final qtyText = entry.pcs != null
        ? '${entry.pcs} pcs'
        : entry.berat != null
        ? '${entry.berat!.toStringAsFixed(1)} kg'
        : '';

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? catColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? catColor.withValues(alpha: 0.35)
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
                color: isSelected ? catColor : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? catColor : const Color(0xFFD1D5DB),
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
                    entry.code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  if (entry.namaJenis.isNotEmpty)
                    Text(
                      entry.namaJenis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ),
            if (qtyText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                qtyText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: catColor,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  printed > 0 ? Icons.print : Icons.print_disabled_outlined,
                  size: 11,
                  color: printColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${printed}x',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: printColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bucket label row ──────────────────────────────────────────────────────────

// ── Reject Type Picker Dialog ─────────────────────────────────────────────────

class _BonggolanJenisPickerDialog extends StatelessWidget {
  const _BonggolanJenisPickerDialog({required this.vm});

  final JenisBonggolanViewModel vm;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF92400E);
    final items = vm.list;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.recycling_outlined,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Jenis Bonggolan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
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
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Tidak ada data jenis bonggolan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFE2E6EA),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (ctx, i) {
                    final jb = items[i];
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(jb),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                jb.namaBonggolan,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RejectTypePickerDialog extends StatelessWidget {
  const _RejectTypePickerDialog({required this.title, required this.vm});

  final String title;
  final RejectTypeViewModel vm;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF92400E);
    final items = vm.list;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.recycling_outlined,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
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
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E6EA)),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Tidak ada data jenis',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFE2E6EA),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (ctx, i) {
                    final rt = items[i];
                    final code = (rt.itemCode ?? '').trim();
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(rt),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rt.namaReject,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (code.isNotEmpty)
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ── Standar Warning Dialog ────────────────────────────────────────────────────

typedef _StandarWarningEntry = ({double? input, double? standar});

class _StandarWarningDialog extends StatelessWidget {
  const _StandarWarningDialog({this.beratWarning, this.cycleWarning});

  final _StandarWarningEntry? beratWarning;
  final _StandarWarningEntry? cycleWarning;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFEA580C);
    const orangeLight = Color(0xFFFFF7ED);
    const orangeBorder = Color(0xFFFED7AA);

    Widget diffRow({
      required IconData icon,
      required String fieldLabel,
      required double? input,
      required double? standar,
      required String unit,
    }) {
      final diff = (input ?? 0) - (standar ?? 0);
      final isOver = diff > 0;
      final diffColor = isOver
          ? const Color(0xFFDC2626)
          : const Color(0xFF2563EB);
      final diffIcon = isOver
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
      final diffLabel = isOver
          ? '+${diff.toStringAsFixed(1)}'
          : diff.toStringAsFixed(1);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: orangeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 12, color: orange),
                ),
                const SizedBox(width: 7),
                Text(
                  fieldLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(diffIcon, size: 10, color: diffColor),
                      const SizedBox(width: 2),
                      Text(
                        '$diffLabel $unit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: diffColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StandarCompareChip(
                    label: 'Input',
                    value: '${input?.toStringAsFixed(1) ?? '-'} $unit',
                    color: diffColor,
                    isHighlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.compare_arrows_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StandarCompareChip(
                    label: 'Standar',
                    value: '${standar?.toStringAsFixed(1) ?? '-'} $unit',
                    color: const Color(0xFF15803D),
                    isHighlight: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: orangeLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: orangeBorder),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nilai Tidak Sesuai Standar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Periksa kembali sebelum menyimpan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Diff cards ─────────────────────────────────
              if (beratWarning != null) ...[
                diffRow(
                  icon: Icons.scale_outlined,
                  fieldLabel: 'Berat',
                  input: beratWarning!.input,
                  standar: beratWarning!.standar,
                  unit: 'gr',
                ),
                if (cycleWarning != null) const SizedBox(height: 8),
              ],
              if (cycleWarning != null)
                diffRow(
                  icon: Icons.timer_outlined,
                  fieldLabel: 'Cycle Time',
                  input: cycleWarning!.input,
                  standar: cycleWarning!.standar,
                  unit: 'sec',
                ),
              const SizedBox(height: 14),
              // ── Actions ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 15),
                      label: const Text(
                        'Tetap Simpan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _StandarCompareChip extends StatelessWidget {
  const _StandarCompareChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isHighlight,
  });

  final String label;
  final String value;
  final Color color;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isHighlight ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
