import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../furniture_wip_type/model/furniture_wip_type_model.dart';
import '../../../furniture_wip_type/repository/furniture_wip_type_repository.dart';
import '../../../furniture_wip_type/view_model/furniture_wip_type_view_model.dart';
import '../../../furniture_wip_type/widgets/furniture_wip_type_dropdown.dart';
import '../../../label/furniture_wip/repository/furniture_wip_repository.dart';
import '../../../label/furniture_wip/view_model/furniture_wip_view_model.dart';

const _kBorder = Color(0xFFE2E6EA);

class ProductionFwipOutputFormDialog extends StatelessWidget {
  const ProductionFwipOutputFormDialog({
    super.key,
    required this.noProduksi,
    this.tglProduksi,
    this.accentColor = const Color(0xFF00796B),
    this.mode = FurnitureWipInputMode.inject,
    this.lockedIdJenis,
    this.lockedNamaJenis,
  });

  final String noProduksi;
  final DateTime? tglProduksi;
  final Color accentColor;
  final FurnitureWipInputMode mode;
  /// Jika diisi, jenis dikunci (tidak tampil dropdown)
  final int? lockedIdJenis;
  final String? lockedNamaJenis;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FurnitureWipViewModel(
              repository: FurnitureWipRepository()),
        ),
        if (lockedIdJenis == null)
          ChangeNotifierProvider(
            create: (_) => FurnitureWipTypeViewModel(
                repository: FurnitureWipTypeRepository(api: ApiClient())),
          ),
      ],
      child: _FwipOutputFormBody(
        noProduksi: noProduksi,
        tglProduksi: tglProduksi,
        accentColor: accentColor,
        mode: mode,
        lockedIdJenis: lockedIdJenis,
        lockedNamaJenis: lockedNamaJenis,
      ),
    );
  }
}

class _FwipOutputFormBody extends StatefulWidget {
  const _FwipOutputFormBody({
    required this.noProduksi,
    required this.accentColor,
    required this.mode,
    this.tglProduksi,
    this.lockedIdJenis,
    this.lockedNamaJenis,
  });

  final String noProduksi;
  final DateTime? tglProduksi;
  final Color accentColor;
  final FurnitureWipInputMode mode;
  final int? lockedIdJenis;
  final String? lockedNamaJenis;

  @override
  State<_FwipOutputFormBody> createState() => _FwipOutputFormBodyState();
}

class _FwipOutputFormBodyState extends State<_FwipOutputFormBody> {
  final _pcsCtrl = TextEditingController();

  FurnitureWipType? _selectedJenis;
  String? _jenisErr;
  String? _pcsErr;
  String? _saveError;
  bool _isSaving = false;

  bool get _isLocked => widget.lockedIdJenis != null;

  @override
  void dispose() {
    _pcsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pcsRaw = _pcsCtrl.text.trim().replaceAll(',', '.');
    final pcs = double.tryParse(pcsRaw);
    final idJenis = _isLocked ? widget.lockedIdJenis! : _selectedJenis?.idCabinetWip;

    setState(() {
      _jenisErr = idJenis == null ? 'Pilih jenis Furniture WIP' : null;
      _pcsErr = (pcs == null || pcs <= 0) ? 'PCS harus > 0' : null;
      _saveError = null;
    });
    if (_jenisErr != null || _pcsErr != null) return;

    setState(() => _isSaving = true);
    try {
      final vm = context.read<FurnitureWipViewModel>();
      await vm.createFromForm(
        idFurnitureWip: idJenis!,
        dateCreate: widget.tglProduksi ?? DateTime.now(),
        pcs: pcs,
        berat: null,
        isPartial: false,
        idWarna: null,
        blok: null,
        idLokasi: null,
        mode: widget.mode,
        injectCode: widget.noProduksi,
        toDbDateString: toDbDateString,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final tglText = widget.tglProduksi == null
        ? '-'
        : DateFormat('dd MMM yyyy', 'id_ID')
            .format(widget.tglProduksi!.toLocal());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: accent, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tambah Output Furniture WIP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        size: 18, color: Color(0xFF9CA3AF)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Info bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'No Produksi',
                    value: widget.noProduksi,
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: tglText,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLocked)
                    _LockedJenisField(
                      namaJenis: widget.lockedNamaJenis ?? '-',
                      accentColor: widget.accentColor,
                    )
                  else
                    FurnitureWipTypeDropdown(
                      onChanged: (jenis) => setState(() {
                        _selectedJenis = jenis;
                        _jenisErr = null;
                      }),
                      validator: (_) => _jenisErr,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pcsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autofocus: true,
                    onChanged: (_) => setState(() => _pcsErr = null),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'PCS',
                      prefixIcon: const Icon(Icons.filter_1_outlined, size: 16),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      errorText: _pcsErr,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(color: accent, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_saveError != null)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 15, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_saveError!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, color: _kBorder),
            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 15),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedJenisField extends StatelessWidget {
  const _LockedJenisField({required this.namaJenis, required this.accentColor});
  final String namaJenis;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              namaJenis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text('$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937))),
      ],
    );
  }
}
