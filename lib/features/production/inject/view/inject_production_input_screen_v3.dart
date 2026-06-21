import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pps_tablet/core/view/app_shell.dart';
import 'package:pps_tablet/features/production/shared/shared.dart';

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
import '../widgets/inject_formula_dialog_v2.dart';
import '../widgets/inject_shift_timeline_dialog.dart';
import '../widgets/inject_sak_picker_dialog.dart';
import '../widgets/inject_split_time_dialog.dart';

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

  // ── Batch / pcs-per-label ─────────────────────────────────────────────────
  InjectPcsPerLabelResult? _pcsPerLabelData;

  String get _breadcrumbLabel {
    final mesin = (_header?.namaMesin ?? '').trim();
    if (mesin.isNotEmpty) return '$mesin (${widget.noProduksi})';
    return widget.noProduksi;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cachedBreadcrumbLabel = widget.noProduksi;
    _loadHeader();
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
        _restoreBucketStatesFromBatches(batches, pcsPerLabel.pcsPerLabel);
      });
      _updateBreadcrumb();
    } catch (_) {}
  }

  void _restoreBucketStatesFromBatches(
    List<InjectBatchItem> batches,
    int pcsPerLabel,
  ) {
    for (final batch in batches) {
      final bucketLabel = _bucketLabelOrder.firstWhere(
        (l) => l.startsWith(batch.hourStart),
        orElse: () => '',
      );
      if (bucketLabel.isEmpty) continue;

      final isLast = _bucketLabelOrder.last == bucketLabel;
      final totalPcs = batch.carryOverIn + batch.pcsInput;
      final int labelsCreated;
      if (isLast) {
        final full = totalPcs ~/ pcsPerLabel;
        final rem = totalPcs % pcsPerLabel;
        labelsCreated = full + (rem > 0 ? 1 : 0);
      } else {
        labelsCreated = totalPcs ~/ pcsPerLabel;
      }

      _bucketStates[bucketLabel] = _HourlyBucketData(
        status: _HourlyBucketStatus.submitted,
        carryOverIn: batch.carryOverIn,
        pcsInput: batch.pcsInput,
        labelsCreated: labelsCreated,
        carryOverOut: batch.carryOverOut,
        berat: batch.berat,
        cycleTime: batch.cycleTime,
        counter: batch.counter,
        labelsFwip: batch.labels.furnitureWip,
        labelsBonggolan: batch.labels.bonggolan,
        labelsReject: batch.labels.reject,
      );

      // Unlock next bucket if not last
      if (!isLast) {
        final idx = _bucketLabelOrder.indexOf(bucketLabel);
        if (idx >= 0 && idx < _bucketLabelOrder.length - 1) {
          final nextLabel = _bucketLabelOrder[idx + 1];
          if (_bucketStates[nextLabel]?.status == _HourlyBucketStatus.locked) {
            _bucketStates[nextLabel] = _HourlyBucketData(
              status: _HourlyBucketStatus.available,
              carryOverIn: batch.carryOverOut,
              pcsInput: 0,
              labelsCreated: 0,
              carryOverOut: 0,
            );
          }
        }
      }
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
      labels.add(
        '${_formatHourMinute(bucketStart)} - ${_formatHourMinute(bucketEnd)}',
      );
      offset = nextOffset;
    }
    return labels;
  }

  void _initBucketStatesFromHeader(InjectProduction header) {
    final labels = _computeHourBucketLabels(header);
    if (labels.isEmpty) return;
    _bucketLabelOrder = labels;
    for (int i = 0; i < labels.length; i++) {
      if (!_bucketStates.containsKey(labels[i])) {
        _bucketStates[labels[i]] = _HourlyBucketData(
          status: i == 0
              ? _HourlyBucketStatus.available
              : _HourlyBucketStatus.locked,
          carryOverIn: 0,
          pcsInput: 0,
          labelsCreated: 0,
          carryOverOut: 0,
        );
      }
    }
  }

  Future<void> _onBucketSubmit(
    String label,
    int pcs,
    InjectOutputJenis? jenis,
    double? berat,
    double? cycleTime,
    int? counter,
    double? beratBonggolan,
    double? beratReject, {
    bool isLastBucket = false,
  }) async {
    final data = _bucketStates[label];
    if (data == null) return;

    final pcsPerLabel = _pcsPerLabelData?.pcsPerLabel ?? 100;
    final idFurnitureWIP = _pcsPerLabelData?.idFurnitureWIP;
    final totalPcs = data.carryOverIn + pcs;

    // Derive hour start from bucket label ("08:00 - 09:00" → "08:00")
    final hourStart = label.split(' - ').first.trim();

    final payload = <String, dynamic>{
      'noProduksi': widget.noProduksi,
      'hourStart': hourStart,
      'carryOverIn': data.carryOverIn,
      'pcsInput': pcs,
      'carryOverOut': isLastBucket ? 0 : totalPcs % pcsPerLabel,
      if (berat != null) 'berat': berat,
      if (cycleTime != null) 'cycleTime': cycleTime,
      if (counter != null) 'counter': counter,
      if (idFurnitureWIP != null && jenis != null) 'idJenis': idFurnitureWIP,
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

    final int labelsCreated;
    final int carryOverOut;
    if (jenis != null) {
      if (isLastBucket) {
        final fullLabels = totalPcs ~/ pcsPerLabel;
        final remainder = totalPcs % pcsPerLabel;
        labelsCreated = fullLabels + (remainder > 0 ? 1 : 0);
        carryOverOut = 0;
      } else {
        labelsCreated = totalPcs ~/ pcsPerLabel;
        carryOverOut = totalPcs % pcsPerLabel;
      }
    } else {
      labelsCreated = 0;
      carryOverOut = isLastBucket ? 0 : totalPcs;
    }

    setState(() {
      _bucketStates[label] = _HourlyBucketData(
        status: _HourlyBucketStatus.submitted,
        carryOverIn: data.carryOverIn,
        pcsInput: pcs,
        labelsCreated: labelsCreated,
        carryOverOut: carryOverOut,
        berat: berat,
        cycleTime: cycleTime,
        counter: counter,
        beratBonggolan: beratBonggolan,
        beratReject: beratReject,
        labelsFwip: result.furnitureWIP,
        labelsBonggolan: result.bonggolan != null ? [result.bonggolan!] : [],
        labelsReject: result.reject != null ? [result.reject!] : [],
      );

      final idx = _bucketLabelOrder.indexOf(label);
      if (!isLastBucket && idx >= 0 && idx < _bucketLabelOrder.length - 1) {
        final nextLabel = _bucketLabelOrder[idx + 1];
        final nextData = _bucketStates[nextLabel];
        if (nextData?.status == _HourlyBucketStatus.locked) {
          _bucketStates[nextLabel] = _HourlyBucketData(
            status: _HourlyBucketStatus.available,
            carryOverIn: carryOverOut,
            pcsInput: 0,
            labelsCreated: 0,
            carryOverOut: 0,
          );
        }
      }
    });

    String snackMsg;
    final created = result.furnitureWIP;
    if (isLastBucket && jenis != null) {
      final fullLabels = totalPcs ~/ pcsPerLabel;
      final remainder = totalPcs % pcsPerLabel;
      if (remainder > 0) {
        snackMsg =
            '✅ $labelsCreated label ${jenis.namaJenis} tercipta ($fullLabels×${pcsPerLabel}pcs + 1×${remainder}pcs sisa)';
      } else {
        snackMsg = '✅ $labelsCreated label ${jenis.namaJenis} tercipta';
      }
    } else if (created.isNotEmpty) {
      snackMsg =
          '✅ ${created.length} label ${jenis!.namaJenis} tercipta · sisa $carryOverOut pcs carry-over';
    } else {
      snackMsg = '✅ Pcs tersimpan · $totalPcs pcs (belum cukup 1 label)';
    }
    _showSnack(snackMsg, backgroundColor: Colors.green);
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

  void _confirmClearTemp() {
    final vm = context.read<InjectProductionInputViewModel>();
    if (vm.totalTempCount == 0) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Temp?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${vm.totalTempCount} item temp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              vm.clearAllTempItems();
              Navigator.of(ctx).pop();
              _showSnack('Semua temp items dihapus');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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

    final result = await showDialog<bool>(
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
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _showSnack('✅ Produksi berhasil diganti', backgroundColor: Colors.green);
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
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Material?'),
        content: Text('Yakin ingin menghapus $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(12, 1, 1, 1),
            child: productionSectionHeader(
              Icons.output_rounded,
              'Label Output',
              iconColor: _kInjectOutput,
              primaryColor: _kInjectPrimary,
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
        final items = <_BucketLabelEntry>[
          ...?data?.labelsFwip.map(
            (c) => _BucketLabelEntry(category: 'Furniture WIP', code: c),
          ),
          ...?data?.labelsBonggolan.map(
            (c) => _BucketLabelEntry(category: 'Bonggolan', code: c),
          ),
          ...?data?.labelsReject.map(
            (c) => _BucketLabelEntry(category: 'Reject', code: c),
          ),
        ];
        return _HourlyTimelineGroup(label: label, items: items);
      }).toList(),
      emptyRangeMessage: 'Belum ada output',
      icon: Icons.schedule_outlined,
      summaryTextBuilder: (_) => '',
      tileBuilder: (item) => _BucketLabelRow(entry: item),
      categoryKeyBuilder: (item) => item.category,
      categoryOrder: const ['Furniture WIP', 'Bonggolan', 'Reject'],
      categoryHeaderBuilder: (cat, _) {
        const catColors = {
          'Furniture WIP': Color(0xFF0F766E),
          'Bonggolan': Color(0xFF92400E),
          'Reject': Color(0xFFB91C1C),
        };
        final color = catColors[cat] ?? _kInjectOutput;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        );
      },
      hourPcsSectionBuilder: (label) {
        final data = _bucketStates[label];
        if (data == null) return const SizedBox.shrink();
        final isLastBucket =
            _bucketLabelOrder.isNotEmpty && _bucketLabelOrder.last == label;
        return _HourlyPcsSection(
          data: data,
          headerOutputs: _header?.outputs ?? const [],
          pcsPerLabel: _pcsPerLabelData?.pcsPerLabel ?? 100,
          isLastBucket: isLastBucket,
          onSubmit:
              (
                pcs,
                jenis,
                berat,
                cycleTime,
                counter,
                beratBonggolan,
                beratReject,
              ) => _onBucketSubmit(
                label,
                pcs,
                jenis,
                berat,
                cycleTime,
                counter,
                beratBonggolan,
                beratReject,
                isLastBucket: isLastBucket,
              ),
        );
      },
      initiallyCollapsed: (_) => true,
      cardColorBuilder: (label) {
        final data = _bucketStates[label];
        if (data == null) return null;
        switch (data.status) {
          case _HourlyBucketStatus.submitted:
            return const Color(0xFF15803D);
          case _HourlyBucketStatus.available:
            return _kInjectPrimary;
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
                    onGanti: _openSplitTimeDialog,
                    onRiwayat: _openTimelineDialog,
                    onRefresh: () {
                      vm.loadInputs(widget.noProduksi, force: true);
                      _showSnack('Data di-refresh');
                    },
                    trailingActions: [
                      const SizedBox(width: 4),
                      Consumer<InjectFormulaViewModel>(
                        builder: (_, fvm, __) => SizedBox(
                          height: 26,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              foregroundColor: _kInjectPrimary,
                              backgroundColor: _kInjectPrimary.withValues(
                                alpha: 0.07,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: fvm.isLoading
                                ? null
                                : () {
                                    final data = fvm.data;
                                    if (data == null) return;
                                    showDialog<void>(
                                      context: context,
                                      builder: (_) =>
                                          InjectFormulaDialogV2(data: data),
                                    );
                                  },
                            icon: fvm.isLoading
                                ? const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                : const Icon(Icons.science_outlined, size: 13),
                            label: const Text(
                              'Formula',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ],
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
  Widget Function(String label)? hourPcsSectionBuilder,
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
        hourPcsSectionBuilder: hourPcsSectionBuilder,
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
    this.hourPcsSectionBuilder,
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
  final Widget Function(String label)? hourPcsSectionBuilder;
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
    final summary = widget.summaryTextBuilder(group.items);

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
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
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
      for (var j = 0; j < catItems.length; j++) {
        widgets.add(widget.tileBuilder(catItems[j]));
        if (j < catItems.length - 1) widgets.add(const SizedBox(height: 4));
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
  const _HourlyTimelineGroup({required this.label, required this.items});

  final String label;
  final List<T> items;
}

// ── Bucket label entry ────────────────────────────────────────────────────────

class _BucketLabelEntry {
  const _BucketLabelEntry({required this.category, required this.code});
  final String category;
  final String code;
}

// ── Hourly bucket state ────────────────────────────────────────────────────────

enum _HourlyBucketStatus { locked, available, submitted }

class _HourlyBucketData {
  const _HourlyBucketData({
    required this.status,
    required this.carryOverIn,
    required this.pcsInput,
    required this.labelsCreated,
    required this.carryOverOut,
    this.berat,
    this.cycleTime,
    this.counter,
    this.beratBonggolan,
    this.beratReject,
    this.labelsFwip = const [],
    this.labelsBonggolan = const [],
    this.labelsReject = const [],
  });

  final _HourlyBucketStatus status;
  final int carryOverIn;
  final int pcsInput;
  final int labelsCreated;
  final int carryOverOut;
  final double? berat;
  final double? cycleTime;
  final int? counter;
  final double? beratBonggolan;
  final double? beratReject;
  final List<String> labelsFwip;
  final List<String> labelsBonggolan;
  final List<String> labelsReject;
}

// ── Hourly Pcs Section ────────────────────────────────────────────────────────

class _HourlyPcsSection extends StatefulWidget {
  const _HourlyPcsSection({
    required this.data,
    required this.headerOutputs,
    required this.onSubmit,
    this.pcsPerLabel = 100,
    this.isLastBucket = false,
  });

  final _HourlyBucketData data;
  final List<InjectOutputJenis> headerOutputs;
  final int pcsPerLabel;
  final bool isLastBucket;
  final Future<void> Function(
    int pcs,
    InjectOutputJenis? jenis,
    double? berat,
    double? cycleTime,
    int? counter,
    double? beratBonggolan,
    double? beratReject,
  )
  onSubmit;

  @override
  State<_HourlyPcsSection> createState() => _HourlyPcsSectionState();
}

class _HourlyPcsSectionState extends State<_HourlyPcsSection> {
  final _pcsCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _beratBonggolanCtrl = TextEditingController();
  final _beratRejectCtrl = TextEditingController();
  int? _counterValue = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pcsCtrl.dispose();
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    _beratBonggolanCtrl.dispose();
    _beratRejectCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final pcs = int.tryParse(_pcsCtrl.text.trim());
    if (pcs == null || pcs < 0) return;

    final pcsPerLabel = widget.pcsPerLabel;
    final totalPcs = widget.data.carryOverIn + pcs;
    final labelsToCreate = totalPcs ~/ pcsPerLabel;
    // Jam akhir: sisa pcs pun dibuatkan label, sehingga picker muncul selama totalPcs > 0
    final needJenisPicker = widget.isLastBucket
        ? totalPcs > 0
        : labelsToCreate > 0;

    InjectOutputJenis? pickedJenis;
    if (needJenisPicker) {
      final outputs = widget.headerOutputs;
      if (outputs.isEmpty) return;
      final displayCount = widget.isLastBucket
          ? (labelsToCreate + (totalPcs % pcsPerLabel > 0 ? 1 : 0))
          : labelsToCreate;
      if (outputs.length == 1) {
        pickedJenis = outputs.first;
      } else {
        pickedJenis = await showDialog<InjectOutputJenis>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _JenisPickerForAutoCreate(
            options: outputs,
            labelsCount: displayCount,
            pcsPerLabel: pcsPerLabel,
          ),
        );
        if (pickedJenis == null || !mounted) return;
      }
    }

    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final cycleTime = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
    final counter = _counterValue;
    final beratBonggolan = widget.isLastBucket
        ? double.tryParse(_beratBonggolanCtrl.text.replaceAll(',', '.'))
        : null;
    final beratReject = widget.isLastBucket
        ? double.tryParse(_beratRejectCtrl.text.replaceAll(',', '.'))
        : null;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        pcs,
        pickedJenis,
        berat,
        cycleTime,
        counter,
        beratBonggolan,
        beratReject,
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
    }
  }

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
    const accent = _kInjectPrimary;
    const mutedColor = Color(0xFF9CA3AF);
    final carryOver = widget.data.carryOverIn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.precision_manufacturing_outlined,
                size: 13,
                color: accent,
              ),
              SizedBox(width: 5),
              Text(
                'Input Pcs Produksi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Carry-over (1/2) + Input pcs (1/2) ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Carry-over
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Carry-over masuk',
                      style: TextStyle(
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
                        border: Border.all(
                          color: accent.withValues(alpha: 0.20),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            size: 11,
                            color: accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$carryOver pcs',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Input pcs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jumlah Barang Bagus (pcs)',
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
                        controller: _pcsCtrl,
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
                            borderSide: const BorderSide(
                              color: accent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: '/ ${widget.pcsPerLabel} pcs',
                          suffixStyle: const TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── Sisa Akhir Shift (last bucket only) ──────────────────
          if (widget.isLastBucket) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _qcField(
                    label: 'Berat Bonggolan (kg)',
                    ctrl: _beratBonggolanCtrl,
                    hint: '0.0',
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _qcField(
                    label: 'Berat Reject (kg)',
                    ctrl: _beratRejectCtrl,
                    hint: '0.0',
                    decimal: true,
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
                  label: 'Berat (kg)',
                  ctrl: _beratCtrl,
                  hint: '0.0',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _qcField(
                  label: 'Cycle Time (dtk)',
                  ctrl: _cycleCtrl,
                  hint: '0.0',
                  decimal: true,
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
    final hasValue = _counterValue != null;
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
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (_) =>
                  _CounterPickerDialog(initialValue: _counterValue ?? 0),
            );
            if (picked != null && mounted) {
              setState(() => _counterValue = picked);
            }
          },
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: hasValue ? accent : accent.withValues(alpha: 0.30),
                width: hasValue ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasValue) ...[
                  Text(
                    '$_counterValue',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ] else
                  Text(
                    'Pilih',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                const SizedBox(width: 4),
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

  Widget _qcField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required bool decimal,
  }) {
    const accent = _kInjectPrimary;
    const mutedColor = Color(0xFF9CA3AF);
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
        SizedBox(
          height: 30,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: mutedColor, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.30)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: accent),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitted() {
    final data = widget.data;
    final hasLabels = data.labelsCreated > 0;
    final totalPcs = data.carryOverIn + data.pcsInput;
    const greenAccent = Color(0xFF15803D);
    const mutedColor = Color(0xFF6B7280);

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
          const SizedBox(height: 8),
          _PcsInfoRow(
            label: 'Carry-over masuk',
            value: '${data.carryOverIn} pcs',
            color: mutedColor,
          ),
          const SizedBox(height: 3),
          _PcsInfoRow(
            label: 'Pcs jam ini',
            value: '${data.pcsInput} pcs',
            color: const Color(0xFF374151),
            bold: true,
          ),
          const SizedBox(height: 3),
          _PcsInfoRow(
            label: 'Total',
            value: '$totalPcs pcs',
            color: const Color(0xFF374151),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _PcsInfoRow(
            label: 'Label tercipta',
            value: '${data.labelsCreated} label',
            color: hasLabels ? greenAccent : mutedColor,
            bold: hasLabels,
          ),
          const SizedBox(height: 3),
          _PcsInfoRow(
            label: 'Carry-over keluar',
            value: '${data.carryOverOut} pcs',
            color: mutedColor,
          ),
          if (data.beratBonggolan != null || data.beratReject != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            Row(
              children: [
                const Icon(
                  Icons.recycling_outlined,
                  size: 10,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Sisa Akhir Shift',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (data.beratBonggolan != null)
                  Expanded(
                    child: _PcsInfoRow(
                      label: 'Bonggolan',
                      value: '${data.beratBonggolan!.toStringAsFixed(1)} kg',
                      color: mutedColor,
                    ),
                  ),
                if (data.beratReject != null)
                  Expanded(
                    child: _PcsInfoRow(
                      label: 'Reject',
                      value: '${data.beratReject!.toStringAsFixed(1)} kg',
                      color: mutedColor,
                    ),
                  ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          Row(
            children: [
              Expanded(
                child: _PcsInfoRow(
                  label: 'Berat',
                  value: data.berat != null
                      ? '${data.berat!.toStringAsFixed(1)} kg'
                      : '-',
                  color: mutedColor,
                ),
              ),
              Expanded(
                child: _PcsInfoRow(
                  label: 'Cycle',
                  value: data.cycleTime != null
                      ? '${data.cycleTime!.toStringAsFixed(1)}s'
                      : '-',
                  color: mutedColor,
                ),
              ),
              Expanded(
                child: _PcsInfoRow(
                  label: 'Counter',
                  value: data.counter != null ? '${data.counter}' : '-',
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PcsInfoRow extends StatelessWidget {
  const _PcsInfoRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
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

// ── Counter Drum Picker ────────────────────────────────────────────────────────

class _CounterPickerDialog extends StatefulWidget {
  const _CounterPickerDialog({required this.initialValue});
  final int initialValue;

  @override
  State<_CounterPickerDialog> createState() => _CounterPickerDialogState();
}

class _CounterPickerDialogState extends State<_CounterPickerDialog> {
  static const int _max = 999;
  late final FixedExtentScrollController _scrollCtrl;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue.clamp(0, _max);
    _scrollCtrl = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (_selected + delta).clamp(0, _max);
    if (next == _selected) return;
    setState(() => _selected = next);
    _scrollCtrl.animateToItem(
      next,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = _kInjectPrimary;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.speed_outlined,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Counter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
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
              const SizedBox(height: 16),
              // ── Drum wheel ───────────────────────────────────────
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _scrollCtrl,
                      itemExtent: 44,
                      perspective: 0.003,
                      diameterRatio: 2.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) =>
                          setState(() => _selected = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _max + 1,
                        builder: (context, index) {
                          final isSelected = index == _selected;
                          return Center(
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontSize: isSelected ? 26 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                                color: isSelected
                                    ? accent
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // ── +/- buttons + value display ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CounterStepBtn(
                    icon: Icons.remove,
                    onTap: () => _step(-1),
                    onLongPress: () => _step(-10),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$_selected',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _CounterStepBtn(
                    icon: Icons.add,
                    onTap: () => _step(1),
                    onLongPress: () => _step(10),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Confirm ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text(
                    'Konfirmasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

class _CounterStepBtn extends StatelessWidget {
  const _CounterStepBtn({
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    const accent = _kInjectPrimary;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}

// ── Bucket label row ──────────────────────────────────────────────────────────

class _BucketLabelRow extends StatelessWidget {
  const _BucketLabelRow({required this.entry});

  final _BucketLabelEntry entry;

  static const _categoryColors = {
    'Furniture WIP': Color(0xFF0F766E),
    'Bonggolan': Color(0xFF92400E),
    'Reject': Color(0xFFB91C1C),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColors[entry.category] ?? _kInjectOutput;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              entry.code,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D23),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
