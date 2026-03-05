import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/features/label/packing/widgets/bt_auto_print_dialog.dart';
import 'package:pps_tablet/features/label/packing/widgets/packing_auto_repeat_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

import '../../../bongkar_susun/widgets/bongkar_susun_dropdown.dart';
import '../../../bongkar_susun/model/bongkar_susun_model.dart';
import '../../../packing_type/model/packing_type_model.dart';
import '../../../packing_type/widgets/packing_type_dropdown.dart';

import '../../../production/inject/view_model/inject_production_view_model.dart';
import '../../../production/packing/model/packing_production_model.dart';
import '../../../production/packing/widgets/packing_production_dropdown.dart';

import '../../../production/inject/model/inject_production_model.dart';
import '../../../production/inject/widgets/inject_production_dropdown.dart';
import '../../../production/inject/widgets/packing_by_inject_section.dart';

import '../../../production/return/model/return_production_model.dart';
import '../../../production/return/widgets/return_production_dropdown.dart';

import '../../../../common/widgets/label_output_panel.dart';
import '../../../../core/network/api_client.dart';
import '../model/packing_header_model.dart';
import '../repository/packing_repository.dart';
import '../view_model/packing_view_model.dart';
import 'packing_text_field.dart';

enum _PrintMode { singleCreate, autoPrintManual, autoRepeat }

/// ✅ Draft untuk "Generate label baru dengan isi sama" (Auto mode)
class _PackingCreateDraft {
  final int? idBJ;
  final DateTime dateCreate;
  final double? pcs;
  final double? berat;

  final PackingInputMode mode;
  final String? packingCode;
  final String? injectCode;
  final String? bongkarSusunCode;
  final String? returCode;

  const _PackingCreateDraft({
    required this.idBJ,
    required this.dateCreate,
    required this.pcs,
    required this.berat,
    required this.mode,
    this.packingCode,
    this.injectCode,
    this.bongkarSusunCode,
    this.returCode,
  });
}

class PackingFormDialog extends StatefulWidget {
  final PackingHeader? header;

  const PackingFormDialog({super.key, this.header});

  @override
  State<PackingFormDialog> createState() => _PackingFormDialogState();
}

class _PackingFormDialogState extends State<PackingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noBJCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController pcsCtrl;
  late final TextEditingController beratCtrl;

  // State
  DateTime _selectedDate = DateTime.now();

  // Mode cetak
  _PrintMode _printMode = _PrintMode.singleCreate;

  // Jumlah pengulangan (hanya aktif saat mode autoRepeat)
  late final TextEditingController _repeatCountCtrl;
  int get _repeatCount =>
      (int.tryParse(_repeatCountCtrl.text.trim()) ?? 1).clamp(1, 99);

  // Mode proses (BD / S / BG / L)
  PackingInputMode? _selectedMode;

  // Jenis Packing
  PackingType? _selectedType;

  // Selected source for each mode
  PackingProduction? _selectedPacking;
  InjectProduction? _selectedInject;
  BongkarSusun? _selectedBongkar;
  ReturnProduction? _selectedRetur;

  // Preselect untuk EDIT
  String? _prePackingNoPacking;
  String? _prePackingNamaMesin;
  String? _preInjectNoProduksi;
  String? _preInjectNamaMesin;
  String? _preBongkarNoBongkarSusun;
  String? _preReturNoRetur;
  String? _preReturNamaPembeli;

  // Inline error messages
  String? _packingError;
  String? _injectError;
  String? _bongkarError;
  String? _returError;

  // Output panel
  List<PackingOutputItem> _packingOutputs = [];
  bool _loadingOutputs = false;

  // ✅ simpan payload terakhir untuk "buat label baru (isi sama)"
  _PackingCreateDraft? _lastDraft;

  bool get isEdit => widget.header != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isEdit) {
        if (_selectedMode == PackingInputMode.inject &&
            _preInjectNoProduksi != null) {
          _reloadInjectPackingAndRecalc();
        }
        // Auto-fetch outputs untuk edit mode
        final code = (widget.header!.outputCode ?? '').trim();
        if (code.isNotEmpty) {
          _fetchOutputs(code);
        }
      } else {
        context.read<InjectProductionViewModel>().clearPacking();
      }
    });

    _repeatCountCtrl = TextEditingController(text: '1');
    noBJCtrl = TextEditingController(text: widget.header?.noBJ ?? '');

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.dateCreate) ?? DateTime.now())
        : DateTime.now();
    _selectedDate = seededDate;

    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    pcsCtrl = TextEditingController(
      text: (widget.header?.pcs != null)
          ? widget.header!.pcs!.toStringAsFixed(
              widget.header!.pcs! % 1 == 0 ? 0 : 3,
            )
          : '',
    );

    beratCtrl = TextEditingController(
      text: (widget.header?.berat != null)
          ? widget.header!.berat!.toStringAsFixed(
              widget.header!.berat! % 1 == 0 ? 0 : 3,
            )
          : '',
    );

    pcsCtrl.addListener(_onPcsChanged);

    if (isEdit && widget.header != null) {
      final code = (widget.header!.outputCode ?? '').trim();
      final type = (widget.header!.outputType ?? '').trim().toUpperCase();
      final nama = (widget.header!.outputNamaMesin ?? '').trim();

      if (code.isNotEmpty) {
        if (type == 'PACKING' || code.startsWith('BD.')) {
          _selectedMode = PackingInputMode.packing;
          _prePackingNoPacking = code;
          _prePackingNamaMesin = nama;
        } else if (type == 'INJECT' || code.startsWith('S.')) {
          _selectedMode = PackingInputMode.inject;
          _preInjectNoProduksi = code;
          _preInjectNamaMesin = nama;
        } else if (type == 'BONGKAR_SUSUN' || code.startsWith('BG.')) {
          _selectedMode = PackingInputMode.bongkarSusun;
          _preBongkarNoBongkarSusun = code;
        } else if (type == 'RETUR' || code.startsWith('L.')) {
          _selectedMode = PackingInputMode.retur;
          _preReturNoRetur = code;
          _preReturNamaPembeli = nama;
        }
      }
    }
  }

  @override
  void dispose() {
    pcsCtrl.removeListener(_onPcsChanged);
    _repeatCountCtrl.dispose();
    noBJCtrl.dispose();
    dateCreatedCtrl.dispose();
    pcsCtrl.dispose();
    beratCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadInjectPackingAndRecalc() async {
    if (!mounted) return;
    if (_selectedMode != PackingInputMode.inject) return;

    final noProd = _selectedInject?.noProduksi ?? _preInjectNoProduksi;
    if (noProd == null || noProd.trim().isEmpty) return;

    final injectVm = context.read<InjectProductionViewModel>();

    try {
      await injectVm.fetchPackingByInjectProduction(noProd);
    } catch (e) {
      // optional log
    }

    _onPcsChanged();
  }

  void _onPcsChanged() {
    if (!mounted) return;

    final bool isInjectMode = _selectedMode == PackingInputMode.inject;
    if (!isInjectMode) return;

    final injectVm = context.read<InjectProductionViewModel>();
    final totalBerat = injectVm.packingBeratProdukHasilTimbang;

    if (totalBerat == null || totalBerat <= 0) return;

    final raw = pcsCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      if (beratCtrl.text.isNotEmpty) {
        beratCtrl.text = '';
      }
      return;
    }

    final pcs = double.tryParse(raw);
    if (pcs == null) return;

    final berat = (pcs / 1000) * totalBerat;
    final text = berat.toStringAsFixed(2);

    if (beratCtrl.text != text) {
      beratCtrl.text = text;
    }
  }

  void _selectMode(PackingInputMode m) {
    setState(() {
      _selectedMode = m;
      _packingOutputs = [];

      if (!isEdit && m == PackingInputMode.inject) {
        _selectedType = null;
      }

      _packingError = null;
      _injectError = null;
      _bongkarError = null;
      _returError = null;
    });

    _onPcsChanged();
  }

  Future<void> _fetchOutputs(String code) async {
    if (!mounted || code.isEmpty) return;
    setState(() => _loadingOutputs = true);
    try {
      final repo = PackingRepository(api: ApiClient());
      List<PackingOutputItem> outputs;
      switch (_selectedMode) {
        case PackingInputMode.inject:
          outputs = await repo.fetchOutputsByInjectNoProduksi(code);
          break;
        case PackingInputMode.packing:
          outputs = await repo.fetchOutputsByPackingNoPacking(code);
          break;
        case PackingInputMode.bongkarSusun:
          outputs = await repo.fetchOutputsByNoBongkarSusun(code);
          break;
        case PackingInputMode.retur:
          outputs = await repo.fetchOutputsByNoRetur(code);
          break;
        case null:
          outputs = [];
      }
      if (mounted) setState(() => _packingOutputs = outputs);
    } catch (_) {
      if (mounted) setState(() => _packingOutputs = []);
    } finally {
      if (mounted) setState(() => _loadingOutputs = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<PackingViewModel>();

    final bool isInjectCreate =
        !isEdit && _selectedMode == PackingInputMode.inject;

    int? idBJVal = isInjectCreate ? null : _selectedType?.idBj;

    if (isEdit && idBJVal == null) {
      // keep existing
    }

    double? pcsVal;
    final pcsRaw = pcsCtrl.text.trim().replaceAll(',', '.');
    if (pcsRaw.isNotEmpty) {
      pcsVal = double.tryParse(pcsRaw);
    }

    double? beratVal;
    final beratRaw = beratCtrl.text.trim().replaceAll(',', '.');
    if (beratRaw.isNotEmpty) {
      beratVal = double.tryParse(beratRaw);
    }

    try {
      if (isEdit) {
        // UPDATE
        DialogService.instance.showLoading(
          message: 'Menyimpan ${widget.header!.noBJ}...',
        );

        await vm.updateFromForm(
          noBJ: widget.header!.noBJ,
          dateCreate: _selectedDate,
          idBJ: idBJVal,
          pcs: pcsVal,
          berat: beratVal,
          outputCode: null,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();
        await DialogService.instance.showSuccess(
          title: 'Tersimpan',
          message: 'Label ${widget.header!.noBJ} berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        // CREATE
        if (_selectedMode == null) {
          await DialogService.instance.showError(
            title: 'PILIH PROSES',
            message:
                'Pilih sumber proses (Packing / Inject / Bongkar Susun / Retur).',
          );
          return;
        }

        if (idBJVal == null && !isInjectCreate) {
          await DialogService.instance.showError(
            title: 'JENIS PACKING',
            message: 'Pilih jenis Packing terlebih dahulu.',
          );
          return;
        }

        String? packingCode;
        String? injectCode;
        String? bongkarSusunCode;
        String? returCode;

        bool hasProcessError = false;

        switch (_selectedMode!) {
          case PackingInputMode.packing:
            if (_selectedPacking == null) {
              setState(() => _packingError = 'Pilih nomor Packing (BD.).');
              hasProcessError = true;
            } else {
              packingCode = _selectedPacking!.noPacking;
            }
            break;

          case PackingInputMode.inject:
            if (_selectedInject == null) {
              setState(
                () => _injectError = 'Pilih nomor produksi Inject (S.).',
              );
              hasProcessError = true;
            } else {
              injectCode = _selectedInject!.noProduksi;
            }
            break;

          case PackingInputMode.bongkarSusun:
            if (_selectedBongkar == null) {
              setState(
                () => _bongkarError = 'Pilih nomor Bongkar Susun (BG.).',
              );
              hasProcessError = true;
            } else {
              bongkarSusunCode = _selectedBongkar!.noBongkarSusun;
            }
            break;

          case PackingInputMode.retur:
            if (_selectedRetur == null) {
              setState(() => _returError = 'Pilih nomor Retur BJ (L.).');
              hasProcessError = true;
            } else {
              returCode = _selectedRetur!.noRetur;
            }
            break;
        }

        if (hasProcessError) {
          await DialogService.instance.showError(
            title: 'NOMOR LABEL SUMBER',
            message: 'Lengkapi pilihan nomor sumber untuk proses yang dipilih.',
          );
          return;
        }

        if (isInjectCreate || (_selectedMode == PackingInputMode.inject)) {
          final injectVm = context.read<InjectProductionViewModel>();
          final totalBerat = injectVm.packingBeratProdukHasilTimbang;

          if (totalBerat == null || totalBerat <= 0) {
            await DialogService.instance.showError(
              title: 'DATA INJECT TIDAK LENGKAP',
              message:
                  'Berat produk hasil timbang dari Inject belum tersedia atau 0.\n'
                  'Pastikan data Inject sudah lengkap sebelum menyimpan Packing.',
            );
            return;
          }

          if (pcsVal == null || pcsVal <= 0) {
            await DialogService.instance.showError(
              title: 'PCS TIDAK VALID',
              message:
                  'PCS wajib diisi dan harus lebih besar dari 0 untuk perhitungan berat otomatis.',
            );
            return;
          }
        }

        // ✅ simpan draft untuk "generate label baru isi sama"
        _lastDraft = _PackingCreateDraft(
          idBJ: idBJVal,
          dateCreate: _selectedDate,
          pcs: pcsVal,
          berat: beratVal,
          mode: _selectedMode!,
          packingCode: packingCode,
          injectCode: injectCode,
          bongkarSusunCode: bongkarSusunCode,
          returCode: returCode,
        );

        DialogService.instance.showLoading(message: 'Membuat label...');

        final res = await vm.createFromForm(
          idBJ: idBJVal,
          dateCreate: _selectedDate,
          pcs: pcsVal,
          berat: beratVal,
          isPartial: false,
          idWarehouse: null,
          blok: null,
          idLokasi: null,
          mode: _selectedMode,
          packingCode: packingCode,
          injectCode: injectCode,
          bongkarSusunCode: bongkarSusunCode,
          returCode: returCode,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();

        final data = res['data'] as Map<String, dynamic>? ?? {};
        final List headers = data['headers'] as List? ?? [];
        final output = data['output'] as Map<String, dynamic>? ?? {};
        final int count = (output['count'] as int?) ?? headers.length;

        // 🟢 CEK MODE: singleCreate / autoPrintManual / autoRepeat
        if (_printMode == _PrintMode.autoRepeat && headers.isNotEmpty) {
          if (mounted) {
            final firstNoBJ = headers.first['NoBJ']?.toString() ?? '';
            if (firstNoBJ.isNotEmpty) {
              await _showAutoRepeatDialog(firstNoBJ);
            }
          }
        } else if (_printMode == _PrintMode.autoPrintManual &&
            headers.isNotEmpty) {
          if (mounted) {
            await _showAutoPrintDialog(headers, count);
          }
        } else {
          // MODE NORMAL - Success Dialog
          Widget extraWidget;

          if (headers.isEmpty) {
            extraWidget = const SizedBox.shrink();
          } else if (headers.length == 1) {
            final no = headers.first['NoBJ']?.toString() ?? '-';
            extraWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Nomor Packing:',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(.35)),
                  ),
                  child: Text(
                    no,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ],
            );
          } else {
            extraWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Nomor Packing ($count label):',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: headers.map((h) {
                      final no = h['NoBJ']?.toString() ?? '-';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $no',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }

          await DialogService.instance.showSuccess(
            title: 'Berhasil',
            message: count > 1
                ? 'Label Barang Jadi berhasil dibuat ($count label).'
                : 'Label Barang Jadi berhasil dibuat.',
            extra: extraWidget,
          );
        }

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      DialogService.instance.hideLoading();
      await DialogService.instance.showError(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  Future<void> _showAutoPrintDialog(List headers, int count) async {
    final draft = _lastDraft;
    if (draft == null) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BtAutoPrintDialog(
        headers: headers,
        count: count,
        reportName: 'CrLabelBarangJadi',
        baseUrl: 'http://192.168.10.100:3000',
        onGenerateSame: () async {
          final vm = context.read<PackingViewModel>();

          final res = await vm.createFromForm(
            idBJ: draft.idBJ,
            dateCreate: draft.dateCreate,
            pcs: draft.pcs,
            berat: draft.berat,
            isPartial: false,
            idWarehouse: null,
            blok: null,
            idLokasi: null,
            mode: draft.mode,
            packingCode: draft.packingCode,
            injectCode: draft.injectCode,
            bongkarSusunCode: draft.bongkarSusunCode,
            returCode: draft.returCode,
            toDbDateString: toDbDateString,
          );

          final data = res['data'] as Map<String, dynamic>? ?? {};
          final List<dynamic> newHeaders =
              (data['headers'] as List?)?.cast<dynamic>() ?? [];
          return newHeaders;
        },
      ),
    );
  }

  /// Buka dialog auto-repeat: create+print sebanyak [_repeatCount] kali.
  /// [firstNoBJ] adalah label yang sudah dibuat oleh form submit (round 1).
  Future<void> _showAutoRepeatDialog(String firstNoBJ) async {
    final draft = _lastDraft;
    if (draft == null) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PackingAutoRepeatDialog(
        totalRounds: _repeatCount,
        firstNoBJ: firstNoBJ,
        reportName: 'CrLabelBarangJadi',
        baseUrl: 'http://192.168.10.100:3000',
        onCreate: () async {
          final vm = context.read<PackingViewModel>();
          final res = await vm.createFromForm(
            idBJ: draft.idBJ,
            dateCreate: draft.dateCreate,
            pcs: draft.pcs,
            berat: draft.berat,
            isPartial: false,
            idWarehouse: null,
            blok: null,
            idLokasi: null,
            mode: draft.mode,
            packingCode: draft.packingCode,
            injectCode: draft.injectCode,
            bongkarSusunCode: draft.bongkarSusunCode,
            returCode: draft.returCode,
            toDbDateString: toDbDateString,
          );
          final data = res['data'] as Map<String, dynamic>? ?? {};
          final headers = (data['headers'] as List?)?.cast<dynamic>() ?? [];
          if (headers.isEmpty) return null;
          return headers.first['NoBJ']?.toString();
        },
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required _PrintMode mode,
    required IconData icon,
  }) {
    final selected = _printMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _printMode = mode;
          if (mode != _PrintMode.autoRepeat) _repeatCountCtrl.text = '1';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.blue.shade700 : Colors.blue.shade300,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.blue.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildLeftColumn()),
                  const SizedBox(width: 24),
                  Container(width: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildOutputPanel()),
                ],
              ),
            ),
            if (!isEdit) ...[const SizedBox(height: 12), _buildModeCetak()],
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEdit ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEdit ? Icons.edit : Icons.add,
            color: isEdit ? Colors.orange.shade700 : Colors.green.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'Edit Label Barang Jadi' : 'Buat Label Barang Jadi',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModeCetak() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.print, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'Mode Cetak',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildModeChip(
                label: 'Single',
                mode: _PrintMode.singleCreate,
                icon: Icons.add_circle_outline,
              ),
              const SizedBox(width: 6),
              _buildModeChip(
                label: 'Multiple',
                mode: _PrintMode.autoPrintManual,
                icon: Icons.touch_app_outlined,
              ),
              const SizedBox(width: 6),
              _buildModeChip(
                label: 'Quick',
                mode: _PrintMode.autoRepeat,
                icon: Icons.repeat,
              ),
            ],
          ),
          if (_printMode == _PrintMode.autoRepeat) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Jumlah label:',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _repeatCountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    final errorStyle = TextStyle(
      color: Theme.of(context).colorScheme.error,
      fontSize: 12,
    );

    final isPackingEnabled =
        !isEdit && _selectedMode == PackingInputMode.packing;
    final isInjectEnabled = !isEdit && _selectedMode == PackingInputMode.inject;
    final isBongkarEnabled =
        !isEdit && _selectedMode == PackingInputMode.bongkarSusun;
    final isReturEnabled = !isEdit && _selectedMode == PackingInputMode.retur;

    final isInjectMode = _selectedMode == PackingInputMode.inject;
    final isCreateInjectMode = !isEdit && isInjectMode;

    final bool isBeratAuto = _selectedMode == PackingInputMode.inject;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Header',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              PackingTextField(
                controller: noBJCtrl,
                label: 'No. Packing',
                icon: Icons.label_important_outline,
                asText: true,
              ),

              const SizedBox(height: 16),

              AppDateField(
                controller: dateCreatedCtrl,
                label: 'Date Created',
                format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                initialDate: _selectedDate,
                onChanged: (d) {
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      dateCreatedCtrl.text = DateFormat(
                        'EEEE, dd MMM yyyy',
                        'id_ID',
                      ).format(d);
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Proses',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // INJECT
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<PackingInputMode>(
                    value: PackingInputMode.inject,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isInjectEnabled,
                      child: Opacity(
                        opacity: isInjectEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InjectProductionDropdown(
                              preselectNoProduksi: _preInjectNoProduksi,
                              preselectNamaMesin: _preInjectNamaMesin,
                              date: _selectedDate,
                              enabled: isInjectEnabled,
                              onChanged: isInjectEnabled
                                  ? (ip) {
                                      if (_selectedMode !=
                                          PackingInputMode.inject) {
                                        _selectMode(PackingInputMode.inject);
                                      }
                                      setState(() {
                                        _selectedInject = ip;
                                        _injectError = null;
                                      });
                                      _reloadInjectPackingAndRecalc();
                                      _fetchOutputs(ip?.noProduksi ?? '');
                                    }
                                  : null,
                            ),
                            if (_injectError != null) ...[
                              const SizedBox(height: 4),
                              Text(_injectError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // PACKING
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<PackingInputMode>(
                    value: PackingInputMode.packing,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isPackingEnabled,
                      child: Opacity(
                        opacity: isPackingEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PackingProductionDropdown(
                              preselectNoPacking: _prePackingNoPacking,
                              preselectNamaMesin: _prePackingNamaMesin,
                              date: _selectedDate,
                              enabled: isPackingEnabled,
                              onChanged: isPackingEnabled
                                  ? (pp) {
                                      if (_selectedMode !=
                                          PackingInputMode.packing) {
                                        _selectMode(PackingInputMode.packing);
                                      }
                                      setState(() {
                                        _selectedPacking = pp;
                                        _packingError = null;
                                      });
                                      _fetchOutputs(pp?.noPacking ?? '');
                                    }
                                  : null,
                            ),
                            if (_packingError != null) ...[
                              const SizedBox(height: 4),
                              Text(_packingError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // BONGKAR SUSUN
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<PackingInputMode>(
                    value: PackingInputMode.bongkarSusun,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isBongkarEnabled,
                      child: Opacity(
                        opacity: isBongkarEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BongkarSusunDropdown(
                              preselectNoBongkarSusun:
                                  _preBongkarNoBongkarSusun,
                              date: _selectedDate,
                              enabled: isBongkarEnabled,
                              onChanged: isBongkarEnabled
                                  ? (bs) {
                                      if (_selectedMode !=
                                          PackingInputMode.bongkarSusun) {
                                        _selectMode(
                                          PackingInputMode.bongkarSusun,
                                        );
                                      }
                                      setState(() {
                                        _selectedBongkar = bs;
                                        _bongkarError = null;
                                      });
                                      _fetchOutputs(bs?.noBongkarSusun ?? '');
                                    }
                                  : null,
                            ),
                            if (_bongkarError != null) ...[
                              const SizedBox(height: 4),
                              Text(_bongkarError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // RETUR
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<PackingInputMode>(
                    value: PackingInputMode.retur,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isReturEnabled,
                      child: Opacity(
                        opacity: isReturEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReturnProductionDropdown(
                              preselectNoRetur: _preReturNoRetur,
                              preselectNamaPembeli: _preReturNamaPembeli,
                              date: _selectedDate,
                              enabled: isReturEnabled,
                              onChanged: isReturEnabled
                                  ? (ret) {
                                      if (_selectedMode !=
                                          PackingInputMode.retur) {
                                        _selectMode(PackingInputMode.retur);
                                      }
                                      setState(() {
                                        _selectedRetur = ret;
                                        _returError = null;
                                      });
                                      _fetchOutputs(ret?.noRetur ?? '');
                                    }
                                  : null,
                            ),
                            if (_returError != null) ...[
                              const SizedBox(height: 4),
                              Text(_returError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (isCreateInjectMode) ...[
                PackingByInjectSection(
                  noProduksi:
                      _selectedInject?.noProduksi ?? _preInjectNoProduksi,
                  title: 'Jenis Packing',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
              ] else ...[
                PackingTypeDropdown(
                  preselectId: widget.header?.idBJ,
                  hintText: 'Pilih jenis Packing',
                  validator: (v) {
                    if (_selectedMode == PackingInputMode.inject && !isEdit)
                      return null;
                    if (_selectedMode == PackingInputMode.inject && isEdit)
                      return null;
                    return v == null ? 'Wajib pilih jenis Packing' : null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (fw) {
                    _selectedType = fw;
                  },
                ),
                const SizedBox(height: 16),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        controller: pcsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*([.,]\d{0,3})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'PCS',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.filter_1_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        validator: (val) {
                          final raw = (val ?? '').trim();
                          if (raw.isEmpty) return 'PCS wajib diisi.';
                          final s = raw.replaceAll(',', '.');
                          final d = double.tryParse(s);
                          if (d == null) return 'Format PCS tidak valid.';
                          if (d <= 0) return 'PCS harus > 0.';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        controller: beratCtrl,
                        enabled: !isBeratAuto,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*([.,]\d{0,3})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Berat (kg)',
                          hintText: isBeratAuto
                              ? 'Auto dari PCS & Inject'
                              : '0',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (isBeratAuto) return null;
                          final raw = (val ?? '').trim();
                          if (raw.isEmpty) return null;
                          final s = raw.replaceAll(',', '.');
                          final d = double.tryParse(s);
                          if (d == null) return 'Format berat tidak valid.';
                          if (d <= 0) return 'Berat harus > 0.';
                          return null;
                        },
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

  Widget _buildOutputPanel() {
    String noSourceMessage;
    String sourceCode;

    switch (_selectedMode) {
      case PackingInputMode.inject:
        noSourceMessage = 'Pilih No Inject\nuntuk melihat output';
        sourceCode = _selectedInject?.noProduksi ?? _preInjectNoProduksi ?? '';
        break;
      case PackingInputMode.packing:
        noSourceMessage = 'Pilih No Packing\nuntuk melihat output';
        sourceCode = _selectedPacking?.noPacking ?? _prePackingNoPacking ?? '';
        break;
      case PackingInputMode.bongkarSusun:
        noSourceMessage = 'Pilih No Bongkar Susun\nuntuk melihat output';
        sourceCode =
            _selectedBongkar?.noBongkarSusun ?? _preBongkarNoBongkarSusun ?? '';
        break;
      case PackingInputMode.retur:
        noSourceMessage = 'Pilih No Retur\nuntuk melihat output';
        sourceCode = _selectedRetur?.noRetur ?? _preReturNoRetur ?? '';
        break;
      case null:
        noSourceMessage = 'Pilih sumber proses\nuntuk melihat output';
        sourceCode = '';
    }

    return LabelOutputPanel(
      title: 'Output Barang Jadi',
      items: _packingOutputs
          .map((o) => LabelOutputItem(code: o.noBJ, isPrinted: o.isPrinted))
          .toList(),
      isLoading: _loadingOutputs,
      hasSource: sourceCode.isNotEmpty,
      noSourceMessage: noSourceMessage,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit
                ? const Color(0xFFF57C00)
                : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text(
            'SIMPAN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
