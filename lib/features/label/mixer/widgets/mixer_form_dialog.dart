// lib/features/labels/mixer/widgets/mixer_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/mixer_type/widgets/mixer_type_dropdown.dart';
import 'package:pps_tablet/features/mixer_type/model/mixer_type_model.dart';
import 'package:pps_tablet/features/production/mixer/widgets/mixer_production_dropdown.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/services/dialog_service.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

import '../../../shared/bongkar_susun/bongkar_susun_dropdown.dart';
import '../model/mixer_detail_model.dart';
import '../model/mixer_header_model.dart';
import 'mixer_text_field.dart';
import '../view_model/mixer_view_model.dart';
import '../../../shared/max_sak/max_sak_service.dart';

class MixerFormDialog extends StatefulWidget {
  final MixerHeader? header;
  final List<MixerDetail>? details;
  final Function(MixerHeader, List<MixerDetail>)? onSave; // optional callback

  const MixerFormDialog({
    super.key,
    this.header,
    this.details,
    this.onSave,
  });

  @override
  State<MixerFormDialog> createState() => _MixerFormDialogState();
}

enum InputMode { production, bongkar }

class _MixerFormDialogState extends State<MixerFormDialog> {
  late final TextEditingController noMixerCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController jenisCtrl;
  late final TextEditingController noProduksiCtrl;
  late final TextEditingController noBongkarSusunCtrl;

  late List<MixerDetail> detailList;

  MixerType? _selectedType; // mixer type
  InputMode? _selectedMode; // production vs bongkar

  DateTime _selectedDate = DateTime.now(); // single source of truth for date

  /// Kode label output yang akan dikirim ke BE (WAJIB untuk create):
  /// - "I.XXXX"  → dari produksi
  /// - "BG.XXXX" → dari bongkar susun
  String? _selectedOutputCode;

  @override
  void initState() {
    super.initState();

    noMixerCtrl = TextEditingController(text: widget.header?.noMixer ?? '');

    // Seed date from header if edit, else today
    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.dateCreate) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    jenisCtrl = TextEditingController(text: widget.header?.namaMixer ?? '');
    noProduksiCtrl = TextEditingController(text: widget.header?.noProduksi ?? '');
    noBongkarSusunCtrl =
        TextEditingController(text: widget.header?.noBongkarSusun ?? '');

    detailList = List.from(widget.details ?? []);

    // Auto-select mode based on existing header when editing
    if ((widget.header?.noProduksi ?? '').isNotEmpty) {
      _selectedMode = InputMode.production;
    } else if ((widget.header?.noBongkarSusun ?? '').isNotEmpty) {
      _selectedMode = InputMode.bongkar;
    } else {
      _selectedMode = InputMode.production; // default
    }

    // Saat EDIT, kita biarkan _selectedOutputCode = null
    // supaya update tidak menyentuh mapping outputCode di BE.
  }

  @override
  void dispose() {
    noMixerCtrl.dispose();
    dateCreatedCtrl.dispose();
    jenisCtrl.dispose();
    noProduksiCtrl.dispose();
    noBongkarSusunCtrl.dispose();
    super.dispose();
  }

  bool get isEdit => widget.header != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
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
                  // LEFT: Header form
                  Expanded(
                    flex: 4,
                    child: _buildLeftColumn(),
                  ),
                  const SizedBox(width: 24),
                  Container(width: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 24),
                  // RIGHT: Detail list
                  Expanded(
                    flex: 2,
                    child: _buildRightColumn(),
                  ),
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

  // ===== HEADER TITLE =====
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
          isEdit ? 'Edit Label Mixer' : 'Tambah Label Mixer',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===== LEFT COLUMN: HEADER FORM =====
  Widget _buildLeftColumn() {
    final bool isProductionEnabled =
        !isEdit && _selectedMode == InputMode.production;
    final bool isBongkarEnabled = !isEdit && _selectedMode == InputMode.bongkar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Header",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // No Mixer (readonly display)
            MixerTextField(
              controller: noMixerCtrl,
              label: 'No Mixer',
              icon: Icons.label,
              asText: true,
            ),
            const SizedBox(height: 16),

            // Date
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

            // Mixer type
            MixerTypeDropdown(
              preselectId: widget.header?.idMixer,
              hintText: 'Pilih jenis mixer',
              validator: (v) => v == null ? 'Wajib pilih jenis mixer' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (jp) {
                _selectedType = jp;
                jenisCtrl.text = jp?.jenis ?? '';
              },
            ),

            const SizedBox(height: 16),

            // ================== OUTPUT CODE SOURCE ==================
            // Mode: Production (I.* → MixerProduksiOutput)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<InputMode>(
                  value: InputMode.production,
                  groupValue: _selectedMode,
                  onChanged: isEdit
                      ? null
                      : (val) {
                    setState(() {
                      _selectedMode = val!;
                      // ganti mode → clear output code & bongkar
                      _selectedOutputCode = null;
                      noBongkarSusunCtrl.clear();
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isProductionEnabled,
                    child: Opacity(
                      opacity: isProductionEnabled ? 1 : 0.6,
                      child: MixerProductionDropdown(
                        preselectNoProduksi: widget.header?.noProduksi,
                        preselectNamaMesin: widget.header?.namaMesin,
                        date: _selectedDate,
                        enabled: isProductionEnabled,
                        onChanged: isProductionEnabled
                            ? (wp) {
                          setState(() {
                            noProduksiCtrl.text = wp?.noProduksi ?? '';

                            // ASUMSI: wp.noProduksi SUDAH termasuk prefix (mis. "I.0000000123")
                            _selectedOutputCode = (wp?.noProduksi?.trim().isEmpty ?? true)
                                ? null
                                : wp!.noProduksi!.trim();
                          });
                        }
                            : null,

                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode: Bongkar Susun (BG.* → BongkarSusunOutputMixer)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<InputMode>(
                  value: InputMode.bongkar,
                  groupValue: _selectedMode,
                  onChanged: isEdit
                      ? null
                      : (val) {
                    setState(() {
                      _selectedMode = val!;
                      // ganti mode → clear output code & produksi
                      _selectedOutputCode = null;
                      noProduksiCtrl.clear();
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isBongkarEnabled,
                    child: Opacity(
                      opacity: isBongkarEnabled ? 1 : 0.6,
                      child: BongkarSusunDropdown(
                        preselectNoBongkarSusun: widget.header?.noBongkarSusun,
                        date: _selectedDate,
                        enabled: isBongkarEnabled,
                        onChanged: isBongkarEnabled
                            ? (bs) {
                          setState(() {
                            noBongkarSusunCtrl.text = bs?.noBongkarSusun ?? '';

                            // ASUMSI: bs.noBongkarSusun SUDAH "BG.0000000X"
                            _selectedOutputCode = (bs?.noBongkarSusun?.trim().isEmpty ?? true)
                                ? null
                                : bs!.noBongkarSusun!.trim();
                          });
                        }
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== RIGHT COLUMN: DETAIL LIST =====
  Widget _buildRightColumn() {
    final totalSak = detailList.length;
    final totalBerat =
    detailList.fold<double>(0, (a, b) => a + (b.berat ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Detail",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addNewDetail(idBagian: 2),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Total bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2,
                          size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '$totalSak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Row(
                    children: [
                      Icon(Icons.scale,
                          size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${totalBerat.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Table
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header table
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Sak',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Berat (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Aksi',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                  if (detailList.isEmpty)
                    _buildEmptyDetailState()
                  else
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detailList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final d = detailList[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${d.noSak}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (d.berat ?? 0).toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                      onPressed: () => _editDetail(d, index),
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteDetail(index),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Belum ada detail",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              "Klik tombol 'Tambah' untuk menambah detail",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ADD DETAIL (multi-add with max SAK) =====
  void _addNewDetail({required int idBagian}) async {
    final currentCount = detailList.length;

    int maxSak = 1;
    double defaultBerat = 1.0;

    try {
      final svc = context.read<MaxSakService>();
      final def = await svc.get(idBagian);
      maxSak = (def.jlhSak <= 0) ? 1 : def.jlhSak;
      defaultBerat = (def.defaultKg <= 0) ? 1.0 : def.defaultKg;
    } catch (e) {
      debugPrint("⚠️ Failed to fetch max-sak: $e (fallback used)");
    }

    final remaining = (maxSak - currentCount).clamp(0, maxSak);
    if (remaining == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ErrorStatusDialog(
          title: 'Batas Tercapai',
          message:
          'Maksimal jumlah Sak telah tercapai. Hapus sebagian jika ingin menambah lagi.',
        ),
      );
      return;
    }

    final beratCtrl = TextEditingController(text: defaultBerat.toString());
    final jumlahSakCtrl = TextEditingController();

    int previewJumlah = remaining;
    String? beratError;
    String? jumlahSakError;

    void _setJumlah(StateSetter setDialogState, int v) {
      final clamped = v.clamp(1, remaining);
      setDialogState(() {
        jumlahSakCtrl.text = clamped.toString();
        jumlahSakCtrl.selection =
            TextSelection.collapsed(offset: jumlahSakCtrl.text.length);
        previewJumlah = clamped;
        jumlahSakError = null;
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final screenWidth = MediaQuery.of(ctx).size.width;
          final dialogWidth = screenWidth > 500 ? 420.0 : screenWidth * 0.9;

          return AlertDialog(
            backgroundColor: Colors.white,
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB2DFDB),
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(Icons.add_circle, color: Color(0xFF00897B)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Tambah Detail",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: beratCtrl,
                            decoration: InputDecoration(
                              labelText: "Berat (kg)",
                              prefixIcon: const Icon(Icons.scale),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorText: beratError,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text("×",
                            style:
                            TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: jumlahSakCtrl,
                            decoration: InputDecoration(
                              labelText: "Jumlah (sak)",
                              prefixIcon:
                              const Icon(Icons.inventory_2_rounded),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorText: jumlahSakError,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              final v = int.tryParse(value) ?? 0;
                              if (v <= 0) {
                                setDialogState(() {
                                  jumlahSakError = 'Minimal 1';
                                  previewJumlah = 0;
                                });
                              } else if (v > remaining) {
                                _setJumlah(setDialogState, remaining);
                                setDialogState(() {
                                  jumlahSakError =
                                  'Mencapai batas ($remaining sak)';
                                });
                              } else {
                                setDialogState(() {
                                  jumlahSakError = null;
                                  previewJumlah = v;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Berat untuk setiap sak",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("BATAL"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("TAMBAH"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  final berat = double.tryParse(beratCtrl.text);
                  final jumlahBaru = int.tryParse(jumlahSakCtrl.text);

                  bool hasError = false;
                  setDialogState(() {
                    beratError = null;
                    jumlahSakError = null;

                    if (berat == null || berat <= 0) {
                      beratError = 'Berat harus diisi dan > 0';
                      hasError = true;
                    }
                    if (jumlahBaru == null || jumlahBaru <= 0) {
                      jumlahSakError = 'Minimal 1';
                      hasError = true;
                    } else if (jumlahBaru > remaining) {
                      jumlahSakError = 'Tidak boleh > $remaining';
                      _setJumlah(setDialogState, remaining);
                      hasError = true;
                    }
                  });

                  if (!hasError) {
                    setState(() {
                      final startNoSak = _getNextSakNumber();
                      for (int i = 0; i < jumlahBaru!; i++) {
                        detailList.add(
                          MixerDetail(
                            noMixer: noMixerCtrl.text,
                            noSak: startNoSak + i,
                            berat: berat,
                            dateUsage: null,
                            isPartial: false,
                          ),
                        );
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  int _getNextSakNumber() {
    if (detailList.isEmpty) return 1;
    final maxSak =
    detailList.map((d) => d.noSak).reduce((a, b) => a > b ? a : b);
    return maxSak + 1;
  }

  // ===== EDIT DETAIL =====
  void _editDetail(MixerDetail detail, int index) {
    final noSakCtrl = TextEditingController(text: detail.noSak.toString());
    final beratCtrl = TextEditingController(text: detail.berat?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogWidth = screenWidth > 500 ? 420.0 : screenWidth * 0.9;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.orange.shade700),
              ),
              const SizedBox(width: 12),
              const Text(
                "Edit Detail",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: noSakCtrl,
                        decoration: InputDecoration(
                          labelText: "No SAK",
                          prefixIcon: const Icon(Icons.tag),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: beratCtrl,
                        decoration: InputDecoration(
                          labelText: "Berat (kg)",
                          prefixIcon: const Icon(Icons.scale),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pastikan data sudah benar sebelum menyimpan.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("BATAL"),
              style: OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("SIMPAN"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: () {
                final noSak = int.tryParse(noSakCtrl.text);
                final berat = double.tryParse(beratCtrl.text);

                if (noSak != null && berat != null) {
                  setState(() {
                    detailList[index] = MixerDetail(
                      noMixer: detail.noMixer,
                      noSak: noSak,
                      berat: berat,
                      dateUsage: detail.dateUsage,
                      isPartial: detail.isPartial,
                    );
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text("Mohon isi No SAK dan Berat dengan benar."),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteDetail(int index) {
    setState(() {
      detailList.removeAt(index);
    });
  }

  // ===== ACTION BUTTONS (SAVE / CANCEL) =====
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
          onPressed: () async {
            final vm = context.read<MixerViewModel>();

            // == VALIDATION ==
            final selected = _selectedType;
            if (selected == null) {
              await DialogService.instance.showError(
                title: 'Validasi',
                message: 'Pilih jenis mixer dulu.',
              );
              return;
            }
            if (detailList.isEmpty) {
              await DialogService.instance.showError(
                title: 'Validasi',
                message: 'Tambah minimal 1 detail SAK.',
              );
              return;
            }

            // Build header
            final headerToSave = widget.header == null
                ? MixerHeader(
              noMixer: noMixerCtrl.text.trim(),
              idMixer: selected.idMixer,
              namaMixer: selected.jenis,
              dateCreate: dateCreatedCtrl.text.trim(),
              statusText: '',
              idStatus: null,
              // output source:
              noProduksi: _selectedMode == InputMode.production
                  ? (noProduksiCtrl.text.trim().isEmpty
                  ? null
                  : noProduksiCtrl.text.trim())
                  : null,
              noBongkarSusun: _selectedMode == InputMode.bongkar
                  ? (noBongkarSusunCtrl.text.trim().isEmpty
                  ? null
                  : noBongkarSusunCtrl.text.trim())
                  : null,
              createBy: '',
              dateTimeCreate: '',
            )
                : widget.header!.copyWith(
              idMixer: selected.idMixer,
              namaMixer: selected.jenis,
              dateCreate: dateCreatedCtrl.text.trim(),
              noProduksi: _selectedMode == InputMode.production
                  ? (noProduksiCtrl.text.trim().isEmpty
                  ? null
                  : noProduksiCtrl.text.trim())
                  : null,
              noBongkarSusun: _selectedMode == InputMode.bongkar
                  ? (noBongkarSusunCtrl.text.trim().isEmpty
                  ? null
                  : noBongkarSusunCtrl.text.trim())
                  : null,
            );

            // at least one reference must be filled
            final hasNoProduksi =
                (headerToSave.noProduksi ?? '').trim().isNotEmpty;
            final hasNoBongkar =
                (headerToSave.noBongkarSusun ?? '').trim().isNotEmpty;

            if (!hasNoProduksi && !hasNoBongkar) {
              await DialogService.instance.showError(
                title: 'Lengkapi Data!',
                message:
                'Wajib pilih Proses Produksi atau Bongkar Susun',
              );
              return;
            }

            // ==== VALIDASI outputCode TIDAK BOLEH KOSONG (CREATE MODE) ====
            String? outputCodeToSend = _selectedOutputCode?.trim();

            if (!isEdit) {
              if (outputCodeToSend == null || outputCodeToSend.isEmpty) {
                await DialogService.instance.showError(
                  title: 'Validasi',
                  message:
                  'Output code belum terbentuk.\nPilih NoProduksi / Bongkar yang valid.',
                );
                return;
              }
            }

            try {
              DialogService.instance.showLoading(
                message: widget.header == null
                    ? 'Membuat label mixer...'
                    : 'Menyimpan perubahan...',
              );

              if (widget.header == null) {
                // CREATE
                final res = await vm.createMixer(
                  headerToSave,
                  detailList,
                  outputCode: outputCodeToSend!, // sudah dipastikan tidak null
                );
                DialogService.instance.hideLoading();

                final noMixer =
                    res?['data']?['header']?['NoMixer']?.toString() ??
                        vm.lastCreatedNoMixer ??
                        '-';

                await DialogService.instance.showSuccess(
                  title: 'Berhasil!',
                  message: 'Label Mixer berhasil dibuat.',
                  extra: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Nomor Mixer:',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(.35),
                          ),
                        ),
                        child: Text(
                          noMixer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    StatusAction(
                      label: 'Nanti',
                      isPrimary: false,
                      onPressed: () {
                        Navigator.of(AppNav.key.currentContext!).pop();
                      },
                    ),
                    StatusAction(
                      label: 'Print',
                      isPrimary: true,
                      onPressed: () {
                        Navigator.of(AppNav.key.currentContext!).pop();
                        // TODO: call print function
                      },
                    ),
                  ],
                );

                if (context.mounted) Navigator.pop(context);
              } else {
                // EDIT (tidak ubah mapping outputCode)
                final res = await vm.updateMixer(headerToSave, detailList);
                DialogService.instance.hideLoading();

                if (res != null) {
                  await DialogService.instance.showSuccess(
                    title: 'Berhasil',
                    message: 'Perubahan berhasil disimpan.',
                  );
                  if (context.mounted) Navigator.pop(context);
                } else {
                  await DialogService.instance.showError(
                    title: 'Gagal',
                    message: vm.errorMessage.isEmpty
                        ? 'Gagal menyimpan perubahan mixer.'
                        : vm.errorMessage,
                  );
                }
              }
            } catch (e) {
              DialogService.instance.hideLoading();
              await DialogService.instance.showError(
                title: 'Error',
                message: e.toString(),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            isEdit ? 'SIMPAN' : 'SIMPAN',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
