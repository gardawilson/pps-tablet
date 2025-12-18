import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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

import '../model/packing_header_model.dart';
import '../view_model/packing_view_model.dart';
import 'packing_text_field.dart';

class PackingFormDialog extends StatefulWidget {
  final PackingHeader? header;

  const PackingFormDialog({
    super.key,
    this.header,
  });

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

  // Mode proses (BD / S / BG / L)
  PackingInputMode? _selectedMode;

  // Jenis Packing
  PackingType? _selectedType;

  // Selected source for each mode (hanya dipakai saat create)
  PackingProduction? _selectedPacking;
  InjectProduction? _selectedInject;
  BongkarSusun? _selectedBongkar;
  ReturnProduction? _selectedRetur;

  // Preselect untuk EDIT (synthetic item di dropdown)
  String? _prePackingNoPacking;
  String? _prePackingNamaMesin;

  String? _preInjectNoProduksi;
  String? _preInjectNamaMesin;

  String? _preBongkarNoBongkarSusun;

  String? _preReturNoRetur;
  String? _preReturNamaPembeli;

  // Inline error messages per dropdown
  String? _packingError;
  String? _injectError;
  String? _bongkarError;
  String? _returError;

  bool get isEdit => widget.header != null;

  @override
  void initState() {
    super.initState();

    // 🔹 Hanya untuk CREATE: pastikan cache packing dari inject di-reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isEdit) {
        // 🔹 EDIT mode inject: load data inject untuk auto-calc
        if (_selectedMode == PackingInputMode.inject && _preInjectNoProduksi != null) {
          _reloadInjectPackingAndRecalc();
        }
      } else {
        // 🔹 CREATE mode: reset cache
        context.read<InjectProductionViewModel>().clearPacking();
      }
    });

    noBJCtrl = TextEditingController(
      text: widget.header?.noBJ ?? '',
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

    // Listener untuk auto-hitungan berat saat PCS berubah (create + edit inject)
    pcsCtrl.addListener(_onPcsChanged);

    // 🔹 Untuk EDIT: preselect dropdown berdasarkan OutputCode / OutputType
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
    noBJCtrl.dispose();
    dateCreatedCtrl.dispose();
    pcsCtrl.dispose();
    beratCtrl.dispose();
    super.dispose();
  }


  Future<void> _reloadInjectPackingAndRecalc() async {
    if (!mounted) return;
    // 🔹 HAPUS pengecekan isEdit - biar auto-calc jalan untuk CREATE & EDIT
    if (_selectedMode != PackingInputMode.inject) return;

    final noProd = _selectedInject?.noProduksi ?? _preInjectNoProduksi;
    if (noProd == null || noProd.trim().isEmpty) return;

    final injectVm = context.read<InjectProductionViewModel>();

    try {
      // 🔹 Ambil ulang data packing (berat + list BJ) untuk Inject terpilih
      await injectVm.fetchPackingByInjectProduction(noProd);
    } catch (e) {
      // optional: bisa kasih log atau dialog kalau mau
      // print('Error fetch packing for inject: $e');
    }

    // 🔹 Setelah beratProdukHasilTimbang di VM update, hitung ulang berat
    _onPcsChanged();
  }

  /// Listener: kalau mode = Inject, berat = PCS / BeratProdukHasilTimbang (Inject)
  void _onPcsChanged() {
    if (!mounted) return;

    // 🔹 Aktif untuk CREATE DAN EDIT mode inject
    final bool isInjectMode = _selectedMode == PackingInputMode.inject;
    if (!isInjectMode) return;

    final injectVm = context.read<InjectProductionViewModel>();
    final totalBerat = injectVm.packingBeratProdukHasilTimbang;

    if (totalBerat == null || totalBerat <= 0) {
      // Tidak bisa hitung kalau berat total tidak ada / 0
      return;
    }

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

      // Kalau pindah ke mode Inject di CREATE, kosongkan jenis dropdown
      if (!isEdit && m == PackingInputMode.inject) {
        _selectedType = null;
      }

      // reset pesan error supaya bersih
      _packingError = null;
      _injectError = null;
      _bongkarError = null;
      _returError = null;
    });

    // Recalc berat kalau sudah ada PCS & data inject
    _onPcsChanged();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<PackingViewModel>();

    // Flag: sedang CREATE + mode INJECT?
    final bool isInjectCreate =
        !isEdit && _selectedMode == PackingInputMode.inject;

    // Ambil ID jenis dari dropdown
    // Untuk INJECT create → selalu null (biar backend auto-mapping multi-label)
    int? idBJVal = isInjectCreate ? null : _selectedType?.idBj;

    // EDIT → kalau user tidak ubah dropdown, biarkan null (service keep existing)
    if (isEdit && idBJVal == null) {
      // no-op; biar service pakai IdBJ lama
    }

    // PCS
    double? pcsVal;
    final pcsRaw = pcsCtrl.text.trim().replaceAll(',', '.');
    if (pcsRaw.isNotEmpty) {
      pcsVal = double.tryParse(pcsRaw);
    }

    // Berat (untuk mode non-inject, atau fallback)
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
          message: 'Menyimpan ${widget.header!.noBJ}...',
        );

        await vm.updateFromForm(
          noBJ: widget.header!.noBJ,
          dateCreate: _selectedDate,
          idBJ: idBJVal,
          pcs: pcsVal,
          berat: beratVal,
          // mapping sumber tidak diubah di mode edit
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
        // =======================
        // CREATE (POST)
        // =======================

        // Mode wajib
        if (_selectedMode == null) {
          await DialogService.instance.showError(
            title: 'PILIH PROSES',
            message:
            'Pilih sumber proses (Packing / Inject / Bongkar Susun / Retur).',
          );
          return;
        }

        // Jenis wajib, KECUALI untuk mode INJECT create (multi otomatis)
        if (idBJVal == null && !isInjectCreate) {
          await DialogService.instance.showError(
            title: 'JENIS PACKING',
            message: 'Pilih jenis Packing terlebih dahulu.',
          );
          return;
        }

        // Mapping berdasarkan mode + dropdown
        String? packingCode;
        String? injectCode;
        String? bongkarSusunCode;
        String? returCode;

        bool hasProcessError = false;

        switch (_selectedMode!) {
          case PackingInputMode.packing:
            if (_selectedPacking == null) {
              setState(() {
                _packingError = 'Pilih nomor Packing (BD.).';
              });
              hasProcessError = true;
            } else {
              packingCode = _selectedPacking!.noPacking;
            }
            break;

          case PackingInputMode.inject:
            if (_selectedInject == null) {
              setState(() {
                _injectError = 'Pilih nomor produksi Inject (S.).';
              });
              hasProcessError = true;
            } else {
              injectCode = _selectedInject!.noProduksi;
            }
            break;

          case PackingInputMode.bongkarSusun:
            if (_selectedBongkar == null) {
              setState(() {
                _bongkarError = 'Pilih nomor Bongkar Susun (BG.).';
              });
              hasProcessError = true;
            } else {
              bongkarSusunCode = _selectedBongkar!.noBongkarSusun;
            }
            break;

          case PackingInputMode.retur:
            if (_selectedRetur == null) {
              setState(() {
                _returError = 'Pilih nomor Retur BJ (L.).';
              });
              hasProcessError = true;
            } else {
              returCode = _selectedRetur!.noRetur;
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

        // 🔹 VALIDASI untuk mode INJECT (CREATE & EDIT)
        if (isInjectCreate || (isEdit && _selectedMode == PackingInputMode.inject)) {
          final injectVm = context.read<InjectProductionViewModel>();
          final totalBerat = injectVm.packingBeratProdukHasilTimbang;

          if (totalBerat == null || totalBerat <= 0) {
            DialogService.instance.showError(
              title: 'DATA INJECT TIDAK LENGKAP',
              message:
              'Berat produk hasil timbang dari Inject belum tersedia atau 0.\n'
                  'Pastikan data Inject sudah lengkap sebelum menyimpan Packing.',
            );
            return;
          }

          if (pcsVal == null || pcsVal <= 0) {
            DialogService.instance.showError(
              title: 'PCS TIDAK VALID',
              message:
              'PCS wajib diisi dan harus lebih besar dari 0 untuk perhitungan berat otomatis.',
            );
            return;
          }

          // 🔹 TIDAK PERLU HITUNG ULANG
          // beratVal sudah correct dari beratCtrl.text (hasil _onPcsChanged)
        }

        DialogService.instance.showLoading(message: 'Membuat label...');

        final res = await vm.createFromForm(
          // Inject create → null (multi), mode lain → IdBJ dari dropdown
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

        // =======================
        // Handle response baru: data.headers (array)
        // =======================
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final List headers = data['headers'] as List? ?? [];
        final output = data['output'] as Map<String, dynamic>? ?? {};
        final int count = (output['count'] as int?) ?? headers.length;

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
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                'Nomor Packing (${count} label):',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ? 'Label Packing berhasil dibuat (${count} label).'
              : 'Label Packing berhasil dibuat.',
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
          isEdit ? 'Edit Label Packing' : 'Tambah Label Packing',
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
    final isPackingEnabled =
        !isEdit && _selectedMode == PackingInputMode.packing;
    final isInjectEnabled =
        !isEdit && _selectedMode == PackingInputMode.inject;
    final isBongkarEnabled =
        !isEdit && _selectedMode == PackingInputMode.bongkarSusun;
    final isReturEnabled = !isEdit && _selectedMode == PackingInputMode.retur;

    final isInjectMode = _selectedMode == PackingInputMode.inject;
    final isCreateInjectMode = !isEdit && isInjectMode;

    // Field berat auto (disabled) hanya untuk CREATE + INJECT
    final bool isBeratAuto = _selectedMode == PackingInputMode.inject; // 🔹 Hapus pengecekan !isEdit

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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // No Packing (readonly text)
              PackingTextField(
                controller: noBJCtrl,
                label: 'No. Packing',
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
                      dateCreatedCtrl.text =
                          DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
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
                                // Setelah pilih inject, coba hitung ulang berat
                                // 🔹 Fetch packing baru untuk Inject terpilih + recalc berat
                                _reloadInjectPackingAndRecalc();                              }
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

              // ===== PACKING (BD.) =====
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

              // ===== BONGKAR SUSUN (BG.) =====
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
                                      PackingInputMode.bongkarSusun);
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
              // Jenis Packing
              // ==========================
              if (isCreateInjectMode) ...[
                // CREATE + mode INJECT → tampilkan section display dari Inject
                PackingByInjectSection(
                  noProduksi:
                  _selectedInject?.noProduksi ?? _preInjectNoProduksi,
                  title: 'Jenis Packing',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Mode lain / EDIT → tetap pakai dropdown jenis
                PackingTypeDropdown(
                  preselectId: widget.header?.idBJ,
                  hintText: 'Pilih jenis Packing',
                  validator: (v) {
                    // Di CREATE Inject, dropdown tidak dipakai (kita sudah di branch lain)
                    // Di EDIT Inject, boleh saja kosong, biar backend pakai yang lama.
                    if (_selectedMode == PackingInputMode.inject && !isEdit) {
                      return null;
                    }
                    if (_selectedMode == PackingInputMode.inject && isEdit) {
                      return null;
                    }
                    return v == null ? 'Wajib pilih jenis Packing' : null;
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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

                  // Berat
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        controller: beratCtrl,
                        enabled: !isBeratAuto, // 🔹 disable saat CREATE + INJECT
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*([.,]\d{0,3})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Berat (kg)',
                          hintText: isBeratAuto ? 'Auto dari PCS & Inject' : '0',
                          prefixIcon:
                          const Icon(Icons.monitor_weight_outlined),
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (isBeratAuto) {
                            // auto-calc, tidak perlu validasi manual
                            return null;
                          }
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
