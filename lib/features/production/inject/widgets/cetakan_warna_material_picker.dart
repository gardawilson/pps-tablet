import 'package:flutter/material.dart';

import '../../../cetakan/model/mst_cetakan_model.dart';
import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../furniture_material/model/furniture_material_lookup_model.dart';
import '../../../furniture_material/repository/furniture_material_lookup_repository.dart';
import '../../../warna/model/warna_model.dart';
import '../../../warna/repository/warna_repository.dart';

typedef CetakanWarnaMaterialResult = ({
  MstCetakan cetakan,
  MstWarna warna,
  FurnitureMaterialLookupResult? material,
});

// ─────────────────────────────────────────────────────────────────────────────
// Field: container tappable dengan 3 kolom berlabel + floating label
// ─────────────────────────────────────────────────────────────────────────────
class CetakanWarnaMaterialPickerField extends StatelessWidget {
  const CetakanWarnaMaterialPickerField({
    super.key,
    required this.selectedCetakan,
    required this.selectedWarna,
    required this.selectedMaterial,
    required this.isLoading,
    required this.onTap,
  });

  final MstCetakan? selectedCetakan;
  final MstWarna? selectedWarna;
  final FurnitureMaterialLookupResult? selectedMaterial;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCetakan = selectedCetakan != null;
    final hasWarna = selectedWarna != null;
    final hasMaterial = selectedMaterial != null &&
        selectedMaterial!.idFurnitureMaterial != 0;

    return _PickerContainer(
      hasValue: hasCetakan,
      isLoading: isLoading,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Col(
              icon: Icons.view_in_ar_outlined,
              label: 'CETAKAN',
              value: hasCetakan ? selectedCetakan!.namaCetakan : null,
              hint: 'Pilih cetakan',
            ),
            _VerticalDivider(),
            _Col(
              icon: Icons.palette_outlined,
              label: 'WARNA',
              value: hasWarna ? selectedWarna!.warna : null,
              hint: 'Pilih warna',
            ),
            _VerticalDivider(),
            _Col(
              icon: Icons.inventory_2_outlined,
              label: 'MATERIAL',
              value: hasMaterial ? (selectedMaterial!.nama ?? '-') : null,
              hint: 'Opsional',
              optional: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerContainer extends StatelessWidget {
  const _PickerContainer({
    required this.hasValue,
    required this.isLoading,
    required this.onTap,
    required this.child,
  });

  final bool hasValue;
  final bool isLoading;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: hasValue ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? const Color(0xFF6B7280)
                  : const Color(0xFFD1D5DB),
              width: hasValue ? 1.0 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: child),
              const SizedBox(width: 8),
              isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Icon(
                      hasValue
                          ? Icons.edit_outlined
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: hasValue
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF9CA3AF),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.optional = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String hint;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 10,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty ? hint : value!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
              color: isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE5E7EB),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: load cetakan then open dialog
// ─────────────────────────────────────────────────────────────────────────────
Future<CetakanWarnaMaterialResult?> showCetakanWarnaMaterialPicker(
  BuildContext context, {
  MstCetakan? initialCetakan,
  MstWarna? initialWarna,
  FurnitureMaterialLookupResult? initialMaterial,
}) async {
  List<MstCetakan> cetakanList = [];
  try {
    cetakanList = await CetakanRepository().fetchAll();
  } catch (_) {}

  if (!context.mounted) return null;

  return showDialog<CetakanWarnaMaterialResult>(
    context: context,
    builder: (_) => CetakanWarnaMaterialPickerDialog(
      cetakanList: cetakanList,
      initialCetakan: initialCetakan,
      initialWarna: initialWarna,
      initialMaterial: initialMaterial,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: 3-kolom — cetakan | warna | material
// ─────────────────────────────────────────────────────────────────────────────
class CetakanWarnaMaterialPickerDialog extends StatefulWidget {
  const CetakanWarnaMaterialPickerDialog({
    super.key,
    required this.cetakanList,
    this.initialCetakan,
    this.initialWarna,
    this.initialMaterial,
  });

  final List<MstCetakan> cetakanList;
  final MstCetakan? initialCetakan;
  final MstWarna? initialWarna;
  final FurnitureMaterialLookupResult? initialMaterial;

  @override
  State<CetakanWarnaMaterialPickerDialog> createState() =>
      _CetakanWarnaMaterialPickerDialogState();
}

class _CetakanWarnaMaterialPickerDialogState
    extends State<CetakanWarnaMaterialPickerDialog> {
  MstCetakan? _selectedCetakan;
  MstWarna? _selectedWarna;
  FurnitureMaterialLookupResult? _selectedMaterial;

  List<MstWarna> _warnaList = [];
  List<FurnitureMaterialLookupResult> _materialList = [];

  bool _loadingWarna = false;
  bool _loadingMaterial = false;

  @override
  void initState() {
    super.initState();
    _selectedCetakan = widget.initialCetakan;
    _selectedWarna = widget.initialWarna;
    _selectedMaterial = widget.initialMaterial;

    if (_selectedCetakan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadWarna(_selectedCetakan!.idCetakan);
        if (_selectedWarna != null) {
          await _loadMaterial(
            _selectedCetakan!.idCetakan,
            _selectedWarna!.idWarna,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadWarna(int idCetakan) async {
    setState(() {
      _loadingWarna = true;
      _warnaList = [];
      _selectedWarna = null;
      _materialList = [];
      _selectedMaterial = null;
    });
    try {
      final list = await WarnaRepository().fetchByCetakan(idCetakan);
      if (!mounted) return;
      setState(() => _warnaList = list);
    } catch (_) {
      if (mounted) setState(() => _warnaList = []);
    } finally {
      if (mounted) setState(() => _loadingWarna = false);
    }
  }

  Future<void> _loadMaterial(int idCetakan, int idWarna) async {
    setState(() {
      _loadingMaterial = true;
      _materialList = [];
      _selectedMaterial = null;
    });
    try {
      final list = await FurnitureMaterialLookupRepository()
          .fetchByCetakanWarna(idCetakan: idCetakan, idWarna: idWarna);
      if (!mounted) return;
      setState(() {
        _materialList = list;
        if (list.length == 1) _selectedMaterial = list.first;
      });
    } catch (_) {
      if (mounted) setState(() => _materialList = []);
    } finally {
      if (mounted) setState(() => _loadingMaterial = false);
    }
  }

  bool get _canConfirm =>
      _selectedCetakan != null && _selectedWarna != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: 780,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.layers_rounded,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Cetakan, Warna & Material',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(null),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body: 3 kolom ────────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Kolom 1: Cetakan ─────────────────────────────
                    SizedBox(
                      width: 240,
                      child: Column(
                        children: [
                          _ColHeader(
                            label: 'CETAKAN',
                            icon: Icons.view_in_ar_outlined,
                            color: const Color(0xFF2563EB),
                          ),
                          Expanded(
                            child: widget.cetakanList.isEmpty
                                ? const _EmptyMsg('Tidak ada cetakan')
                                : ListView.builder(
                                    itemCount: widget.cetakanList.length,
                                    itemBuilder: (_, i) {
                                      final c = widget.cetakanList[i];
                                      final active =
                                          _selectedCetakan?.idCetakan ==
                                              c.idCetakan;
                                      return _ListItem(
                                        label: c.namaCetakan,
                                        isActive: active,
                                        activeColor: const Color(0xFF2563EB),
                                        onTap: () async {
                                          setState(
                                              () => _selectedCetakan = c);
                                          await _loadWarna(c.idCetakan);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(
                        width: 1, color: Color(0xFFE5E7EB)),

                    // ── Kolom 2: Warna ────────────────────────────────
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          _ColHeader(
                            label: 'WARNA',
                            icon: Icons.palette_outlined,
                            color: const Color(0xFF7C3AED),
                          ),
                          Expanded(
                            child: _selectedCetakan == null
                                ? const _EmptyMsg(
                                    'Pilih cetakan\nterlebih dahulu')
                                : _loadingWarna
                                    ? const _Loading()
                                    : _warnaList.isEmpty
                                        ? const _EmptyMsg(
                                            'Tidak ada warna\nuntuk cetakan ini')
                                        : ListView.builder(
                                            itemCount: _warnaList.length,
                                            itemBuilder: (_, i) {
                                              final w = _warnaList[i];
                                              final active =
                                                  _selectedWarna?.idWarna ==
                                                      w.idWarna;
                                              return _ListItem(
                                                label: w.warna,
                                                isActive: active,
                                                activeColor:
                                                    const Color(0xFF7C3AED),
                                                onTap: () async {
                                                  setState(
                                                      () => _selectedWarna = w);
                                                  await _loadMaterial(
                                                    _selectedCetakan!
                                                        .idCetakan,
                                                    w.idWarna,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(
                        width: 1, color: Color(0xFFE5E7EB)),

                    // ── Kolom 3: Furniture Material ───────────────────
                    Expanded(
                      child: Column(
                        children: [
                          _ColHeader(
                            label: 'FURNITURE MATERIAL',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF059669),
                          ),
                          Expanded(
                            child: _selectedWarna == null
                                ? const _EmptyMsg(
                                    'Pilih warna\nterlebih dahulu')
                                : _loadingMaterial
                                    ? const _Loading()
                                    : _materialList.isEmpty
                                        ? _NoMaterialItem(
                                            isSelected:
                                                _selectedMaterial == null,
                                            onTap: () => setState(
                                                () => _selectedMaterial =
                                                    null),
                                          )
                                        : ListView.builder(
                                            itemCount:
                                                _materialList.length + 1,
                                            itemBuilder: (_, i) {
                                              if (i == 0) {
                                                return _NoMaterialItem(
                                                  isSelected:
                                                      _selectedMaterial ==
                                                          null,
                                                  onTap: () => setState(
                                                      () =>
                                                          _selectedMaterial =
                                                              null),
                                                );
                                              }
                                              final m =
                                                  _materialList[i - 1];
                                              final active =
                                                  _selectedMaterial
                                                          ?.idFurnitureMaterial ==
                                                      m.idFurnitureMaterial;
                                              return _ListItem(
                                                label: m.displayText,
                                                sublabel: m.itemCode,
                                                isActive: active,
                                                activeColor:
                                                    const Color(0xFF059669),
                                                onTap: () => setState(
                                                    () =>
                                                        _selectedMaterial =
                                                            m),
                                              );
                                            },
                                          ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer ──────────────────────────────────────────────
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    // preview pilihan
                    Expanded(
                      child: _selectedCetakan == null
                          ? const Text(
                              'Belum ada yang dipilih',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF)),
                            )
                          : Wrap(
                              spacing: 6,
                              children: [
                                _FooterChip(
                                    _selectedCetakan!.namaCetakan,
                                    const Color(0xFF2563EB)),
                                if (_selectedWarna != null)
                                  _FooterChip(_selectedWarna!.warna,
                                      const Color(0xFF7C3AED)),
                                if (_selectedMaterial != null)
                                  _FooterChip(
                                      _selectedMaterial!.nama ?? '-',
                                      const Color(0xFF059669)),
                              ],
                            ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _canConfirm
                          ? () => Navigator.of(context).pop((
                                cetakan: _selectedCetakan!,
                                warna: _selectedWarna!,
                                material: _selectedMaterial,
                              ))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pilih'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  const _ColHeader({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    required this.label,
    this.sublabel,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });
  final String label;
  final String? sublabel;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isActive
            ? activeColor.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? activeColor
                          : const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sublabel != null && sublabel!.isNotEmpty)
                    Text(
                      sublabel!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, size: 14, color: activeColor),
          ],
        ),
      ),
    );
  }
}

class _NoMaterialItem extends StatelessWidget {
  const _NoMaterialItem({
    required this.isSelected,
    required this.onTap,
  });
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6B7280);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected
            ? const Color(0xFFF3F4F6)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tidak ada material',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: color,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _EmptyMsg extends StatelessWidget {
  const _EmptyMsg(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
