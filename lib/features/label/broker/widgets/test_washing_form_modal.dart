// lib/view/widgets/washing_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../shared/bongkar_susun/bongkar_susun_dropdown.dart';
import '../../../shared/washing_production/washing_production_dropdown.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';
import 'washing_text_field.dart';
import 'package:provider/provider.dart';
import '../view_model/washing_view_model.dart';
import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../shared/plastic_type/jenis_plastik_dropdown.dart';
import '../../../shared/max_sak/max_sak_service.dart';

class WashingFormDialog extends StatefulWidget {
  final WashingHeader? header;
  final List<WashingDetail>? details;
  final Function(WashingHeader, List<WashingDetail>)? onSave;

  const WashingFormDialog({
    super.key,
    this.header,
    this.details,
    this.onSave,
  });

  @override
  State<WashingFormDialog> createState() => _WashingFormDialogState();
}

enum InputMode { production, bongkar }

class _WashingFormDialogState extends State<WashingFormDialog> {
  late final TextEditingController noWashingCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController jenisCtrl;
  late final TextEditingController warehouseCtrl;
  late final TextEditingController noProduksiCtrl;
  late final TextEditingController noBongkarSusunCtrl;

  late List<WashingDetail> detailList;

  JenisPlastik? _selectedJenis;
  InputMode? _selectedMode;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    noWashingCtrl = TextEditingController(text: widget.header?.noWashing ?? '');
    dateCreatedCtrl = TextEditingController(
      text: formatDateToFullId(DateTime.now().toIso8601String()),
    );
    jenisCtrl = TextEditingController(text: widget.header?.namaJenisPlastik ?? '');
    warehouseCtrl = TextEditingController(text: widget.header?.namaWarehouse ?? '');
    noProduksiCtrl = TextEditingController(text: widget.header?.noProduksi ?? '');
    noBongkarSusunCtrl = TextEditingController(text: widget.header?.noBongkarSusun ?? '');
    detailList = List.from(widget.details ?? []);

    if ((widget.header?.noProduksi ?? '').isNotEmpty) {
      _selectedMode = InputMode.production;
    } else if ((widget.header?.noBongkarSusun ?? '').isNotEmpty) {
      _selectedMode = InputMode.bongkar;
    } else {
      _selectedMode = InputMode.production;
    }
  }

  @override
  void dispose() {
    noWashingCtrl.dispose();
    dateCreatedCtrl.dispose();
    jenisCtrl.dispose();
    warehouseCtrl.dispose();
    noProduksiCtrl.dispose();
    noBongkarSusunCtrl.dispose();
    super.dispose();
  }

  bool get isEdit => widget.header != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      // Gunakan padding bottom dari MediaQuery untuk avoid keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95, // 95% tinggi layar
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar untuk indikator modal
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Layout responsif untuk mobile/tablet
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Jika lebar > 700, gunakan layout 2 kolom
                          if (constraints.maxWidth > 700) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: _buildLeftColumn()),
                                  const SizedBox(width: 24),
                                  Container(width: 1, color: Colors.grey.shade300),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: _buildRightColumn()),
                                ],
                              ),
                            );
                          }

                          // Jika lebar <= 700, gunakan layout vertikal
                          return Column(
                            children: [
                              _buildLeftColumn(),
                              const SizedBox(height: 24),
                              Container(
                                height: 1,
                                color: Colors.grey.shade300,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              SizedBox(
                                height: 400, // Tinggi tetap untuk detail list di mobile
                                child: _buildRightColumn(),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
          isEdit ? 'Edit Label' : 'Tambah Label Baru',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final bool isProductionEnabled = !isEdit && _selectedMode == InputMode.production;
    final bool isBongkarEnabled = !isEdit && _selectedMode == InputMode.bongkar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
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
          WashingTextField(
            controller: noWashingCtrl,
            label: 'No Washing',
            icon: Icons.label,
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
                  dateCreatedCtrl.text = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          JenisPlastikDropdown(
            preselectId: widget.header?.idJenisPlastik,
            hintText: 'Pilih jenis plastik',
            validator: (v) => v == null ? 'Wajib pilih jenis plastik' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (jp) {
              _selectedJenis = jp;
              jenisCtrl.text = jp?.jenis ?? '';
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<InputMode>(
                value: InputMode.production,
                groupValue: _selectedMode,
                onChanged: isEdit ? null : (val) => setState(() => _selectedMode = val!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IgnorePointer(
                  ignoring: !isProductionEnabled,
                  child: Opacity(
                    opacity: isProductionEnabled ? 1 : 0.6,
                    child: WashingProductionDropdown(
                      preselectNoProduksi: widget.header?.noProduksi,
                      preselectNamaMesin: widget.header?.namaMesin,
                      date: _selectedDate,
                      enabled: isProductionEnabled,
                      onChanged: isProductionEnabled
                          ? (wp) {
                        setState(() {
                          noProduksiCtrl.text = wp?.noProduksi ?? '';
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<InputMode>(
                value: InputMode.bongkar,
                groupValue: _selectedMode,
                onChanged: isEdit ? null : (val) => setState(() => _selectedMode = val!),
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
          WashingTextField(
            controller: warehouseCtrl,
            label: 'Warehouse',
            icon: Icons.warehouse,
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    final totalSak = detailList.length;
    final totalBerat = detailList.fold<double>(0, (a, b) => a + (b.berat ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                onPressed: () => _addNewDetail(idBagian: 7),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: detailList.isEmpty
                        ? _buildEmptyDetailState()
                        : _buildSimpleDetailList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                    Icon(Icons.inventory_2, size: 20, color: Colors.blue.shade700),
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
                    Icon(Icons.scale, size: 20, color: Colors.blue.shade700),
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
        ],
      ),
    );
  }

  Widget _buildSimpleDetailList() {
    return ListView.separated(
      itemCount: detailList.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final d = detailList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                      icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                      onPressed: () => _editDetail(d, index),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
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
    );
  }

  Widget _buildEmptyDetailState() {
    return Center(
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
    );
  }

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
      debugPrint("⚠️ Gagal fetch max-sak: $e (fallback)");
    }

    final remaining = (maxSak - currentCount).clamp(0, maxSak);
    if (remaining == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ErrorStatusDialog(
          title: 'Batas Tercapai',
          message: 'Maksimal SAK telah tercapai. Hapus sebagian jika ingin menambah lagi.',
        ),
      );
      return;
    }

    final beratCtrl = TextEditingController(text: defaultBerat.toString());
    final jumlahSakCtrl = TextEditingController();
    int previewStart = _getNextSakNumber();
    int previewJumlah = remaining;
    String? beratError;
    String? jumlahSakError;

    void setJumlah(StateSetter setDialogState, int v) {
      final clamped = v.clamp(1, remaining);
      setDialogState(() {
        jumlahSakCtrl.text = clamped.toString();
        jumlahSakCtrl.selection = TextSelection.collapsed(offset: jumlahSakCtrl.text.length);
        previewJumlah = clamped;
        jumlahSakError = null;
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(Icons.add_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text("Tambah Detail"),
              ],
            ),
            content: SizedBox(
              width: 380,
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
                              border: const OutlineInputBorder(),
                              errorText: beratError,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text("×"),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: jumlahSakCtrl,
                            decoration: InputDecoration(
                              labelText: "Jumlah (sak)",
                              prefixIcon: const Icon(Icons.inventory),
                              border: const OutlineInputBorder(),
                              errorText: jumlahSakError,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              final v = int.tryParse(value) ?? 0;
                              if (v <= 0) {
                                setDialogState(() {
                                  jumlahSakError = 'Minimal 1';
                                  previewJumlah = 0;
                                });
                              } else if (v > remaining) {
                                setJumlah(setDialogState, remaining);
                                setDialogState(() {
                                  jumlahSakError = 'Jumlah maks ($remaining sak)';
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
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Berat untuk setiap sak",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("BATAL"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                      setJumlah(setDialogState, remaining);
                      hasError = true;
                    }
                  });

                  if (!hasError) {
                    setState(() {
                      final startNoSak = _getNextSakNumber();
                      for (int i = 0; i < jumlahBaru!; i++) {
                        detailList.add(WashingDetail(
                          noWashing: noWashingCtrl.text,
                          noSak: startNoSak + i,
                          berat: berat,
                          dateUsage: DateTime.now().toString(),
                          idLokasi: '-',
                        ));
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("TAMBAH"),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getNextSakNumber() {
    if (detailList.isEmpty) return 1;
    final maxSak = detailList.map((d) => d.noSak).reduce((a, b) => a > b ? a : b);
    return maxSak + 1;
  }

  void _editDetail(WashingDetail detail, int index) {
    final noSakCtrl = TextEditingController(text: detail.noSak.toString());
    final beratCtrl = TextEditingController(text: detail.berat?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text("Edit Detail"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noSakCtrl,
              decoration: const InputDecoration(
                labelText: "No SAK",
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: beratCtrl,
              decoration: const InputDecoration(
                labelText: "Berat (kg)",
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final noSak = int.tryParse(noSakCtrl.text);
              final berat = double.tryParse(beratCtrl.text);

              if (noSak != null && berat != null) {
                setState(() {
                  detailList[index] = WashingDetail(
                    noWashing: detail.noWashing,
                    noSak: noSak,
                    berat: berat,
                    dateUsage: detail.dateUsage,
                    idLokasi: detail.idLokasi,
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("SIMPAN"),
          ),
        ],
      ),
    );
  }

  void _deleteDetail(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
          'Yakin hapus detail SAK ${detailList[index].noSak}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                detailList.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('HAPUS'),
          ),
        ],
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
          onPressed: () async {
            final vm = context.read<WashingViewModel>();

            final selected = _selectedJenis;
            if (selected == null) {
              await DialogService.instance.showError(
                title: 'Validasi',
                message: 'Pilih Jenis Plastik dulu.',
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

            final headerToSave = widget.header == null
                ? WashingHeader(
              noWashing: noWashingCtrl.text,
              idJenisPlastik: selected.idJenisPlastik,
              namaJenisPlastik: selected.jenis,
              idWarehouse: 0,
              namaWarehouse: warehouseCtrl.text,
              dateCreate: dateCreatedCtrl.text,
              idStatus: null,
              createBy: '',
              dateTimeCreate: '',
              noProduksi: _selectedMode == InputMode.production
                  ? (noProduksiCtrl.text.trim().isEmpty ? null : noProduksiCtrl.text.trim())
                  : null,
              noBongkarSusun: _selectedMode == InputMode.bongkar
                  ? (noBongkarSusunCtrl.text.trim().isEmpty ? null : noBongkarSusunCtrl.text.trim())
                  : null,
            )
                : widget.header!.copyWith(
              idJenisPlastik: selected.idJenisPlastik,
              namaJenisPlastik: selected.jenis,
              namaWarehouse: warehouseCtrl.text,
              dateCreate: dateCreatedCtrl.text,
              noProduksi: noProduksiCtrl.text.trim().isEmpty ? null : noProduksiCtrl.text.trim(),
              noBongkarSusun: noBongkarSusunCtrl.text.trim().isEmpty ? null : noBongkarSusunCtrl.text.trim(),
            );

            final hasNoProduksi = (headerToSave.noProduksi ?? '').trim().isNotEmpty;
            final hasNoBongkar = (headerToSave.noBongkarSusun ?? '').trim().isNotEmpty;
            if (!hasNoProduksi && !hasNoBongkar) {
              await DialogService.instance.showError(
                title: 'Validasi',
                message: 'Isi NoProduksi atau NoBongkarSusun (minimal salah satu).',
              );
              return;
            }

            debugPrint('===== HEADER TO SAVE =====');
            debugPrint(headerToSave.toJson().toString());
            debugPrint('===== DETAIL LIST =====');
            for (var i = 0; i < detailList.length; i++) {
              debugPrint('Detail #${i + 1}: ${detailList[i].toJson()}');
            }
            debugPrint('==========================');

            try {
              DialogService.instance.showLoading(
                message: widget.header == null ? 'Membuat label...' : 'Menyimpan perubahan...',
              );

              if (widget.header == null) {
                final res = await vm.createWashing(headerToSave, detailList);
                DialogService.instance.hideLoading();

                final noWashing = res?['data']?['header']?['NoWashing']?.toString() ??
                    vm.lastCreatedNoWashing ??
                    '-';

                await DialogService.instance.showSuccess(
                  title: 'Berhasil!',
                  message: 'Label Washing berhasil dibuat.',
                  extra: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      const Text('Nomor Washing:', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(.35)),
                        ),
                        child: Text(
                          noWashing,
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
                        // _printLabel(noWashing);
                      },
                    ),
                  ],
                );

                if (context.mounted) Navigator.pop(context);
              } else {
                await widget.onSave?.call(headerToSave, detailList);
                DialogService.instance.hideLoading();

                await DialogService.instance.showSuccess(
                  title: 'Berhasil',
                  message: 'Perubahan berhasil disimpan.',
                );

                if (context.mounted) Navigator.pop(context);
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
            backgroundColor: isEdit ? Colors.orange : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            isEdit ? 'SIMPAN' : 'TAMBAH',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}