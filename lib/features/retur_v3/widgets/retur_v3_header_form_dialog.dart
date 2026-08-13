import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/app_date_field.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../core/network/api_error.dart';
import '../../pembeli/model/pembeli_model.dart';
import '../../pembeli/widgets/pembeli_dropdown.dart';
import '../model/retur_v3_header.dart';
import '../repository/retur_v3_repository.dart';
import 'retur_v3_item_input_dialog.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kText = Color(0xFF1A1D23);

/// Dialog create/edit Retur v3 — untuk create, satu dialog ini sekaligus
/// mengurus pembuatan header DAN pengisian item (jenis+pcs+kondisi) awal,
/// jadi user tidak perlu keluar dialog lalu buka section PENDING terpisah
/// untuk menambah item pertama. Edit mode tetap header-only (item hanya
/// bisa diisi/diubah saat header masih PENDING, lewat layar detail).
///
/// Mengikuti pola visual `ReturnProductionFormDialog`
/// (lib/features/production/return/widgets/return_production_form_dialog.dart).
class ReturV3HeaderFormDialog extends StatefulWidget {
  final ReturV3Header? header;
  final ReturV3Repository? repository;

  const ReturV3HeaderFormDialog({super.key, this.header, this.repository});

  @override
  State<ReturV3HeaderFormDialog> createState() =>
      _ReturV3HeaderFormDialogState();
}

class _ReturV3HeaderFormDialogState extends State<ReturV3HeaderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ReturV3Repository _repo;

  late final TextEditingController _tanggalCtrl;
  late final TextEditingController _keteranganCtrl;

  DateTime _selectedDate = DateTime.now();
  MstPembeli? _selectedPembeli;
  final List<ReturV3ItemInput> _pendingItems = [];

  bool get isEdit => widget.header != null;

  bool _saving = false;
  String? _error;

  /// Diisi begitu header berhasil dibuat di percobaan submit sebelumnya —
  /// kalau addItems gagal, retry submit berikutnya tidak akan membuat
  /// header duplikat, cukup lanjut mencoba menambahkan sisa item saja.
  ReturV3Header? _createdHeader;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ReturV3Repository();

    final seededDate = widget.header?.tanggal ?? DateTime.now();
    _selectedDate = seededDate;
    _tanggalCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );
    _keteranganCtrl = TextEditingController(
      text: widget.header?.keterangan ?? '',
    );
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddItemDialog() async {
    final result = await showDialog<ReturV3ItemInput>(
      context: context,
      builder: (_) => const ReturV3ItemInputDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _pendingItems.add(result));
  }

  void _removeItem(int index) {
    setState(() => _pendingItems.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final pembeliId = _selectedPembeli?.idPembeli ?? widget.header?.idPembeli;
    if (pembeliId == null) {
      setState(() => _error = 'Pembeli wajib dipilih');
      return;
    }
    if (!isEdit && _pendingItems.isEmpty) {
      setState(() => _error = 'Item retur wajib diisi minimal 1 (jenis + pcs)');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (isEdit) {
        final result = await _repo.update(
          widget.header!.noRetur,
          tanggal: _selectedDate,
          idPembeli: pembeliId,
          keterangan: _keteranganCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop(result);
        return;
      }

      // Create mode: header dibuat sekali saja (skip kalau sudah berhasil
      // di percobaan submit sebelumnya, tinggal lanjut addItems).
      var header = _createdHeader;
      header ??= await _repo.create(
        tanggal: _selectedDate,
        idPembeli: pembeliId,
        keterangan: _keteranganCtrl.text.trim(),
      );
      _createdHeader = header;

      if (_pendingItems.isNotEmpty) {
        await _repo.addItems(
          header.noRetur,
          _pendingItems
              .map(
                (it) => {
                  'kodeKategori': it.kodeKategori,
                  'idJenis': it.idJenis,
                  'pcs': it.pcs,
                  'kategoriInput': it.kategoriInput,
                },
              )
              .toList(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(header);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerAlreadyCreated = _createdHeader != null;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEdit
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit : Icons.add,
                    color: isEdit
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Retur' : 'Tambah Retur',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderFormBody(headerAlreadyCreated),
                    if (!isEdit) ...[
                      const SizedBox(height: 16),
                      _buildItemSection(headerAlreadyCreated),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('BATAL'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                  child: Text(_saving ? 'MENYIMPAN...' : 'SIMPAN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFormBody(bool headerAlreadyCreated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEdit) ...[
              AppTextField(
                controller: TextEditingController(
                  text: widget.header!.noRetur,
                ),
                label: 'No. Retur',
                icon: Icons.label,
                readOnly: true,
              ),
              const SizedBox(height: 16),
            ],
            if (headerAlreadyCreated) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Header ${_createdHeader!.noRetur} sudah dibuat. Lengkapi item lalu Simpan.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            IgnorePointer(
              ignoring: headerAlreadyCreated,
              child: Opacity(
                opacity: headerAlreadyCreated ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDateField(
                      controller: _tanggalCtrl,
                      label: 'Tanggal',
                      format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
                      initialDate: _selectedDate,
                      onChanged: (d) {
                        if (d == null) return;
                        setState(() {
                          _selectedDate = d;
                          _tanggalCtrl.text = DateFormat(
                            'EEEE, dd MMM yyyy',
                            'id_ID',
                          ).format(d);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    PembeliDropdown(
                      preselectId: widget.header?.idPembeli,
                      label: 'Pembeli',
                      hint: 'Pilih pembeli',
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) =>
                          v == null && widget.header?.idPembeli == null
                          ? 'Wajib pilih pembeli'
                          : null,
                      onChanged: (p) => setState(() => _selectedPembeli = p),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _keteranganCtrl,
                      label: 'Keterangan',
                      icon: Icons.notes_outlined,
                      hintText: 'Keterangan retur (opsional)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSection(bool headerAlreadyCreated) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Item Retur (wajib diisi minimal 1)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : _openAddItemDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Item'),
                ),
              ],
            ),
          ),
          if (_pendingItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Belum ada item — tambahkan minimal 1 sebelum menyimpan',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _pendingItems.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _kBorder),
              itemBuilder: (context, i) {
                final it = _pendingItems[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          it.namaJenis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${it.pcs} pcs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: it.kategoriInput == 'REJECT'
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          it.kategoriInput,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: it.kategoriInput == 'REJECT'
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red.shade400,
                        onPressed: _saving ? null : () => _removeItem(i),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
