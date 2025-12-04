// lib/features/furniture_wip/widgets/furniture_wip_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/features/production/spanner/model/spanner_production_model.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';

import '../../../production/hot_stamp/model/hot_stamp_production_model.dart';
import '../../../production/hot_stamp/widgets/hot_stamp_production_dropdown.dart';
import '../../../production/inject/model/inject_production_model.dart';
import '../../../production/inject/widgets/furniture_wip_by_inject_section.dart';
import '../../../production/inject/widgets/inject_production_dropdown.dart';

import '../../../production/key_fitting/model/key_fitting_production_model.dart';
import '../../../production/key_fitting/widgets/key_fitting_production_dropdown.dart';
import '../../../production/return/model/return_production_model.dart';
import '../../../production/return/widgets/return_production_dropdown.dart';

import '../../../production/spanner/widgets/spanner_production_dropdown.dart';
import '../../../shared/bongkar_susun/bongkar_susun_model.dart';
import '../../../shared/bongkar_susun/bongkar_susun_dropdown.dart';

import '../model/furniture_wip_header_model.dart';
import '../view_model/furniture_wip_view_model.dart';
import 'furniture_wip_text_field.dart';

// Jenis Furniture WIP
import '../../../furniture_wip_type/model/furniture_wip_type_model.dart';
import '../../../furniture_wip_type/widgets/furniture_wip_type_dropdown.dart';

// Section display Furniture WIP by Inject

class FurnitureWipFormDialog extends StatefulWidget {
  final FurnitureWipHeader? header;

  const FurnitureWipFormDialog({
    super.key,
    this.header,
  });

  @override
  State<FurnitureWipFormDialog> createState() =>
      _FurnitureWipFormDialogState();
}

class _FurnitureWipFormDialogState extends State<FurnitureWipFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noFurnitureWipCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController pcsCtrl;
  late final TextEditingController beratCtrl;

  // State
  DateTime _selectedDate = DateTime.now();

  // Mode proses (BH / BI / BG / L / BJ / S)
  FurnitureWipInputMode? _selectedMode;

  // Jenis Furniture WIP
  FurnitureWipType? _selectedType;

  // Selected source for each mode (hanya dipakai saat create)
  HotStampProduction? _selectedHotStamp;
  KeyFittingProduction? _selectedKeyFitting;
  BongkarSusun? _selectedBongkar;
  ReturnProduction? _selectedReturBj;
  SpannerProduction? _selectedSpanner;
  InjectProduction? _selectedInject;

  // Preselect untuk EDIT (synthetic item di dropdown)
  String? _preHotStampNoProduksi;
  String? _preHotStampNamaMesin;

  String? _preKeyFittingNoProduksi;
  String? _preKeyFittingNamaMesin;

  String? _preBongkarNoBongkarSusun;

  String? _preReturNoRetur;
  String? _preReturNamaPembeli;

  String? _preSpannerNoProduksi;
  String? _preSpannerNamaMesin;

  String? _preInjectNoProduksi;
  String? _preInjectNamaMesin;

  // Inline error messages per dropdown
  String? _hotStampError;
  String? _keyFittingError;
  String? _bongkarError;
  String? _returError;
  String? _spannerError;
  String? _injectError;

  @override
  void initState() {
    super.initState();

    noFurnitureWipCtrl = TextEditingController(
      text: widget.header?.noFurnitureWip ?? '',
    );

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

    // 🔹 Untuk EDIT: preselect dropdown berdasarkan OutputCode / OutputType
    if (isEdit && widget.header != null) {
      final code = (widget.header!.outputCode ?? '').trim();
      final type = (widget.header!.outputType ?? '').trim().toUpperCase();
      final nama = (widget.header!.outputNamaMesin ?? '').trim();

      if (code.isNotEmpty) {
        if (type == 'HOTSTAMPING' || code.startsWith('BH.')) {
          _selectedMode = FurnitureWipInputMode.hotStamping;
          _preHotStampNoProduksi = code;
          _preHotStampNamaMesin = nama;
        } else if (type == 'PASANG_KUNCI' || code.startsWith('BI.')) {
          _selectedMode = FurnitureWipInputMode.pasangKunci;
          _preKeyFittingNoProduksi = code;
          _preKeyFittingNamaMesin = nama;
        } else if (type == 'BONGKAR_SUSUN' || code.startsWith('BG.')) {
          _selectedMode = FurnitureWipInputMode.bongkarSusun;
          _preBongkarNoBongkarSusun = code;
        } else if (type == 'RETUR' || code.startsWith('L.')) {
          _selectedMode = FurnitureWipInputMode.retur;
          _preReturNoRetur = code;
          _preReturNamaPembeli = nama; // NamaPembeli
        } else if (type == 'SPANNER' || code.startsWith('BJ.')) {
          _selectedMode = FurnitureWipInputMode.spanner;
          _preSpannerNoProduksi = code;
          _preSpannerNamaMesin = nama;
        } else if (type == 'INJECT' || code.startsWith('S.')) {
          _selectedMode = FurnitureWipInputMode.inject;
          _preInjectNoProduksi = code;
          _preInjectNamaMesin = nama;
        }
      }
    }
  }

  @override
  void dispose() {
    noFurnitureWipCtrl.dispose();
    dateCreatedCtrl.dispose();
    pcsCtrl.dispose();
    beratCtrl.dispose();
    super.dispose();
  }

  bool get isEdit => widget.header != null;

  void _selectMode(FurnitureWipInputMode m) {
    setState(() {
      _selectedMode = m;

      // Kalau pindah ke mode Inject di CREATE, kosongkan jenis dropdown
      if (!isEdit && m == FurnitureWipInputMode.inject) {
        _selectedType = null;
      }

      // reset pesan error supaya bersih
      _hotStampError = null;
      _keyFittingError = null;
      _bongkarError = null;
      _returError = null;
      _spannerError = null;
      _injectError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<FurnitureWipViewModel>();

    // Flag: sedang CREATE + mode INJECT?
    final bool isInjectCreate =
        !isEdit && _selectedMode == FurnitureWipInputMode.inject;

    // Ambil ID jenis dari dropdown
    // Untuk INJECT create → selalu null (biar backend auto-mapping multi-label)
    int? idFurnitureVal =
    isInjectCreate ? null : _selectedType?.idCabinetWip;

    // EDIT → kalau user tidak ubah dropdown, biarkan null (service keep existing)
    if (isEdit && idFurnitureVal == null) {
      // no-op; biar service pakai IdFurnitureWIP lama
    }

    // PCS
    double? pcsVal;
    final pcsRaw = pcsCtrl.text.trim().replaceAll(',', '.');
    if (pcsRaw.isNotEmpty) {
      pcsVal = double.tryParse(pcsRaw);
    }

    // Berat
    double? beratVal;
    final beratRaw = beratCtrl.text.trim().replaceAll(',', '.');
    if (beratRaw.isNotEmpty) {
      beratVal = double.tryParse(beratRaw);
    }

    try {
      if (isEdit) {
        // =======================
        // UPDATE (PUT)
        // =======================
        DialogService.instance.showLoading(
          message: 'Menyimpan ${widget.header!.noFurnitureWip}...',
        );

        await vm.updateFromForm(
          noFurnitureWip: widget.header!.noFurnitureWip,
          dateCreate: _selectedDate,
          idFurnitureWip: idFurnitureVal,
          pcs: pcsVal,
          berat: beratVal,
          // mapping sumber tidak diubah di mode edit
          outputCode: null,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();
        await DialogService.instance.showSuccess(
          title: 'Tersimpan',
          message:
          'Label ${widget.header!.noFurnitureWip} berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context);
      } else {
        // =======================
        // CREATE (POST)
        // =======================

        // Mode wajib
        if (_selectedMode == null) {
          await DialogService.instance.showError(
            title: 'PILIH PROSES',
            message:
            'Pilih sumber proses (Hot Stamping / Pasang Kunci / Bongkar Susun / Retur / Spanner / Inject).',
          );
          return;
        }

        // Jenis wajib, KECUALI untuk mode INJECT create (multi otomatis)
        if (idFurnitureVal == null && !isInjectCreate) {
          await DialogService.instance.showError(
            title: 'JENIS FURNITURE WIP',
            message: 'Pilih jenis Furniture WIP terlebih dahulu.',
          );
          return;
        }

        // Mapping berdasarkan mode + dropdown
        String? hotStampCode;
        String? pasangKunciCode;
        String? bongkarSusunCode;
        String? returCode;
        String? spannerCode;
        String? injectCode;

        bool hasProcessError = false;

        switch (_selectedMode!) {
          case FurnitureWipInputMode.hotStamping:
            if (_selectedHotStamp == null) {
              setState(() {
                _hotStampError = 'Pilih nomor produksi Hot Stamp (BH.).';
              });
              hasProcessError = true;
            } else {
              hotStampCode = _selectedHotStamp!.noProduksi;
            }
            break;

          case FurnitureWipInputMode.pasangKunci:
            if (_selectedKeyFitting == null) {
              setState(() {
                _keyFittingError =
                'Pilih nomor produksi Key Fitting (BI.).';
              });
              hasProcessError = true;
            } else {
              pasangKunciCode = _selectedKeyFitting!.noProduksi;
            }
            break;

          case FurnitureWipInputMode.bongkarSusun:
            if (_selectedBongkar == null) {
              setState(() {
                _bongkarError = 'Pilih nomor Bongkar Susun (BG.).';
              });
              hasProcessError = true;
            } else {
              bongkarSusunCode = _selectedBongkar!.noBongkarSusun;
            }
            break;

          case FurnitureWipInputMode.retur:
            if (_selectedReturBj == null) {
              setState(() {
                _returError = 'Pilih nomor Retur BJ (L.).';
              });
              hasProcessError = true;
            } else {
              returCode = _selectedReturBj!.noRetur;
            }
            break;

          case FurnitureWipInputMode.spanner:
            if (_selectedSpanner == null) {
              setState(() {
                _spannerError =
                'Pilih nomor BJ Sortir (Spanner / BJ.).';
              });
              hasProcessError = true;
            } else {
              spannerCode = _selectedSpanner!.noProduksi;
            }
            break;

          case FurnitureWipInputMode.inject:
            if (_selectedInject == null) {
              setState(() {
                _injectError = 'Pilih nomor produksi Inject (S.).';
              });
              hasProcessError = true;
            } else {
              injectCode = _selectedInject!.noProduksi;
            }
            break;
        }

        if (hasProcessError) {
          // Inline error sudah muncul di bawah dropdown yang bermasalah
          await DialogService.instance.showError(
            title: 'NOMOR LABEL SUMBER',
            message:
            'Lengkapi pilihan nomor sumber untuk proses yang dipilih.',
          );
          return;
        }

        DialogService.instance.showLoading(message: 'Membuat label...');

        final res = await vm.createFromForm(
          // Inject create → null (multi), mode lain → IdFurnitureWIP dari dropdown
          idFurnitureWip: idFurnitureVal,
          dateCreate: _selectedDate,
          pcs: pcsVal,
          berat: beratVal,
          isPartial: false,
          idWarna: null,
          blok: null,
          idLokasi: null,
          mode: _selectedMode,
          hotStampCode: hotStampCode,
          pasangKunciCode: pasangKunciCode,
          bongkarSusunCode: bongkarSusunCode,
          returCode: returCode,
          spannerCode: spannerCode,
          injectCode: injectCode,
          toDbDateString: toDbDateString,
        );

        DialogService.instance.hideLoading();

        // =======================
        // Handle response baru: data.headers (array)
        // =======================
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final List headers = data['headers'] as List? ?? [];
        final output = data['output'] as Map<String, dynamic>? ?? {};
        final int count =
            (output['count'] as int?) ?? headers.length;

        Widget extraWidget;

        if (headers.isEmpty) {
          extraWidget = const SizedBox.shrink();
        } else if (headers.length == 1) {
          final no =
              headers.first['NoFurnitureWIP']?.toString() ?? '-';
          extraWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Nomor Furniture WIP:',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(.35),
                  ),
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
          // Multi-label (Inject multi, dsb.)
          extraWidget = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                'Nomor Furniture WIP (${count} label):',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headers.map((h) {
                    final no =
                        h['NoFurnitureWIP']?.toString() ?? '-';
                    return Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 2),
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
              ? 'Label Furniture WIP berhasil dibuat (${count} label).'
              : 'Label Furniture WIP berhasil dibuat.',
          extra: extraWidget,
        );

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      DialogService.instance.hideLoading();
      await DialogService.instance
          .showError(title: 'Error', message: e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                  Expanded(flex: 4, child: _buildLeftColumn()),
                ],
              ),
            ),
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
          isEdit ? 'Edit Label Furniture WIP' : 'Tambah Label Furniture WIP',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final errorStyle = TextStyle(
      color: Theme.of(context).colorScheme.error,
      fontSize: 12,
    );

    // Mode aktif → dropdown mana yang bisa di-interact saat CREATE.
    // Saat EDIT, semua dropdown tetap dibangun, tapi non-interaktif (enabled=false),
    // hanya yang sesuai _selectedMode yang punya preselect value.
    final isHotStampEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.hotStamping;
    final isKeyFittingEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.pasangKunci;
    final isBongkarEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.bongkarSusun;
    final isReturEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.retur;
    final isSpannerEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.spanner;
    final isInjectEnabled =
        !isEdit && _selectedMode == FurnitureWipInputMode.inject;

    final isInjectMode = _selectedMode == FurnitureWipInputMode.inject;
    final isCreateInjectMode = !isEdit && isInjectMode;

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
                  Icon(Icons.description,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Header',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // No Furniture WIP (readonly text)
              FurnitureWipTextField(
                controller: noFurnitureWipCtrl,
                label: 'No Furniture WIP',
                icon: Icons.label_important_outline,
                asText: true,
              ),

              const SizedBox(height: 16),

              // Tanggal
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
                          'EEEE, dd MMM yyyy', 'id_ID')
                          .format(d);
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // ==========================
              // Sumber Proses
              // ==========================
              const Text(
                'Proses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // ===== INJECT (S.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.inject,
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
                                    FurnitureWipInputMode.inject) {
                                  _selectMode(
                                      FurnitureWipInputMode.inject);
                                }
                                setState(() {
                                  _selectedInject = ip;
                                  _injectError = null;
                                });
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

              // ===== HOT STAMPING (BH.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.hotStamping,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isHotStampEnabled,
                      child: Opacity(
                        opacity: isHotStampEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HotStampProductionDropdown(
                              preselectNoProduksi: _preHotStampNoProduksi,
                              preselectNamaMesin: _preHotStampNamaMesin,
                              date: _selectedDate,
                              enabled: isHotStampEnabled,
                              onChanged: isHotStampEnabled
                                  ? (hs) {
                                if (_selectedMode !=
                                    FurnitureWipInputMode
                                        .hotStamping) {
                                  _selectMode(FurnitureWipInputMode
                                      .hotStamping);
                                }
                                setState(() {
                                  _selectedHotStamp = hs;
                                  _hotStampError = null;
                                });
                              }
                                  : null,
                            ),
                            if (_hotStampError != null) ...[
                              const SizedBox(height: 4),
                              Text(_hotStampError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== PASANG KUNCI (BI.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.pasangKunci,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isKeyFittingEnabled,
                      child: Opacity(
                        opacity: isKeyFittingEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyFittingProductionDropdown(
                              preselectNoProduksi:
                              _preKeyFittingNoProduksi,
                              preselectNamaMesin:
                              _preKeyFittingNamaMesin,
                              date: _selectedDate,
                              enabled: isKeyFittingEnabled,
                              onChanged: isKeyFittingEnabled
                                  ? (kf) {
                                if (_selectedMode !=
                                    FurnitureWipInputMode
                                        .pasangKunci) {
                                  _selectMode(FurnitureWipInputMode
                                      .pasangKunci);
                                }
                                setState(() {
                                  _selectedKeyFitting = kf;
                                  _keyFittingError = null;
                                });
                              }
                                  : null,
                            ),
                            if (_keyFittingError != null) ...[
                              const SizedBox(height: 4),
                              Text(_keyFittingError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== SPANNER (BJ.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.spanner,
                    groupValue: _selectedMode,
                    onChanged: isEdit ? null : (val) => _selectMode(val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: !isSpannerEnabled,
                      child: Opacity(
                        opacity: isSpannerEnabled ? 1 : 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SpannerProductionDropdown(
                              preselectNoProduksi: _preSpannerNoProduksi,
                              preselectNamaMesin: _preSpannerNamaMesin,
                              date: _selectedDate,
                              enabled: isSpannerEnabled,
                              onChanged: isSpannerEnabled
                                  ? (sp) {
                                if (_selectedMode !=
                                    FurnitureWipInputMode.spanner) {
                                  _selectMode(
                                      FurnitureWipInputMode.spanner);
                                }
                                setState(() {
                                  _selectedSpanner = sp;
                                  _spannerError = null;
                                });
                              }
                                  : null,
                            ),
                            if (_spannerError != null) ...[
                              const SizedBox(height: 4),
                              Text(_spannerError!, style: errorStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== BONGKAR SUSUN (BG.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.bongkarSusun,
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
                                    FurnitureWipInputMode
                                        .bongkarSusun) {
                                  _selectMode(FurnitureWipInputMode
                                      .bongkarSusun);
                                }
                                setState(() {
                                  _selectedBongkar = bs;
                                  _bongkarError = null;
                                });
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

              // ===== RETUR BJ (L.) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<FurnitureWipInputMode>(
                    value: FurnitureWipInputMode.retur,
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
                                    FurnitureWipInputMode.retur) {
                                  _selectMode(
                                      FurnitureWipInputMode.retur);
                                }
                                setState(() {
                                  _selectedReturBj = ret;
                                  _returError = null;
                                });
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

              // ==========================
              // Jenis Furniture WIP
              // ==========================

              if (isCreateInjectMode) ...[
                // CREATE + mode INJECT → tampilkan section display dari Inject
                FurnitureWipByInjectSection(
                  noProduksi:
                  _selectedInject?.noProduksi ?? _preInjectNoProduksi,
                  title: 'Jenis Furniture WIP',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Mode lain / EDIT → tetap pakai dropdown jenis
                FurnitureWipTypeDropdown(
                  preselectId: widget.header?.idFurnitureWip,
                  hintText: 'Pilih jenis Furniture WIP',
                  validator: (v) {
                    // Di CREATE Inject, dropdown tidak dipakai (kita sudah di branch lain)
                    // Di EDIT Inject, boleh saja kosong, biar backend pakai yang lama.
                    if (_selectedMode == FurnitureWipInputMode.inject &&
                        !isEdit) {
                      return null;
                    }
                    if (_selectedMode == FurnitureWipInputMode.inject &&
                        isEdit) {
                      return null;
                    }
                    return v == null
                        ? 'Wajib pilih jenis Furniture WIP'
                        : null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (fw) {
                    _selectedType = fw;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // PCS & Berat dalam 1 baris
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PCS
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        controller: pcsCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*([.,]\d{0,3})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'PCS',
                          hintText: '0',
                          prefixIcon:
                          const Icon(Icons.filter_1_outlined),
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

                  // Berat
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        controller: beratCtrl,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*([.,]\d{0,3})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Berat (kg)',
                          hintText: '0',
                          prefixIcon:
                          const Icon(Icons.monitor_weight_outlined),
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        validator: (val) {
                          final raw = (val ?? '').trim();
                          if (raw.isEmpty) return null; // optional
                          final s = raw.replaceAll(',', '.');
                          final d = double.tryParse(s);
                          if (d == null) {
                            return 'Format berat tidak valid.';
                          }
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

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
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
