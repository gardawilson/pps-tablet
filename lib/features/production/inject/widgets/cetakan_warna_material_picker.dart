import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../common/widgets/list_item_skeleton.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../cetakan/model/mst_cetakan_model.dart';
import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../furniture_material/model/furniture_material_lookup_model.dart';
import '../../../furniture_material/repository/furniture_material_lookup_repository.dart';
import '../../../warna/model/warna_model.dart';
import '../../../warna/repository/warna_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Output mapping model
// ─────────────────────────────────────────────────────────────────────────────

class OutputMappingItem {
  final String kategori;
  final int idOutput;
  final String namaOutput;

  const OutputMappingItem({
    required this.kategori,
    required this.idOutput,
    required this.namaOutput,
  });

  factory OutputMappingItem.fromJson(Map<String, dynamic> j) =>
      OutputMappingItem(
        kategori: j['kategori'] as String? ?? '',
        idOutput: (j['idOutput'] as num?)?.toInt() ?? 0,
        namaOutput: j['namaOutput'] as String? ?? '-',
      );
}

class OutputMappingResult {
  final String outputType;
  final List<OutputMappingItem> items;

  const OutputMappingResult({required this.outputType, required this.items});
}

// ─────────────────────────────────────────────────────────────────────────────
// Furniture WIP compositions model
// ─────────────────────────────────────────────────────────────────────────────

class _WipKomposisi {
  final int idCetakan;
  final String namaCetakan;
  final int idWarna;
  final String namaWarna;
  final int? idFurnitureMaterial;
  final String? namaFurnitureMaterial;

  const _WipKomposisi({
    required this.idCetakan,
    required this.namaCetakan,
    required this.idWarna,
    required this.namaWarna,
    this.idFurnitureMaterial,
    this.namaFurnitureMaterial,
  });

  factory _WipKomposisi.fromJson(Map<String, dynamic> j) => _WipKomposisi(
    idCetakan: (j['IdCetakan'] as num?)?.toInt() ?? 0,
    namaCetakan: j['NamaCetakan'] as String? ?? '-',
    idWarna: (j['IdWarna'] as num?)?.toInt() ?? 0,
    namaWarna: j['NamaWarna'] as String? ?? '-',
    idFurnitureMaterial: (j['IdFurnitureMaterial'] as num?)?.toInt(),
    namaFurnitureMaterial: j['NamaFurnitureMaterial'] as String?,
  );
}

class _WipComposition {
  final int idFurnitureWIP;
  final String namaFurnitureWIP;
  final List<_WipKomposisi> komposisi;

  const _WipComposition({
    required this.idFurnitureWIP,
    required this.namaFurnitureWIP,
    required this.komposisi,
  });

  factory _WipComposition.fromJson(Map<String, dynamic> j) => _WipComposition(
    idFurnitureWIP: (j['IdFurnitureWIP'] as num?)?.toInt() ?? 0,
    namaFurnitureWIP: j['NamaFurnitureWIP'] as String? ?? '-',
    komposisi: (j['Komposisi'] as List? ?? [])
        .map((e) => _WipKomposisi.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

Future<List<_WipComposition>> _fetchWipCompositions() async {
  try {
    final token = await TokenStorage.getToken();
    final resp = await http
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}/api/mst/material/furniture-wip-compositions',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return [];
    final body =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map(
          (e) => _WipComposition.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  } catch (_) {
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barang Jadi compositions model
// ─────────────────────────────────────────────────────────────────────────────

class _BarangJadiComposition {
  final int idBarangJadi;
  final String namaBarangJadi;
  final List<_WipKomposisi> komposisi;

  const _BarangJadiComposition({
    required this.idBarangJadi,
    required this.namaBarangJadi,
    required this.komposisi,
  });

  factory _BarangJadiComposition.fromJson(Map<String, dynamic> j) =>
      _BarangJadiComposition(
        idBarangJadi: (j['IdBarangJadi'] as num?)?.toInt() ?? 0,
        namaBarangJadi: j['NamaBarangJadi'] as String? ?? '-',
        komposisi: (j['Komposisi'] as List? ?? [])
            .map(
              (e) =>
                  _WipKomposisi.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
}

Future<List<_BarangJadiComposition>> _fetchBarangJadiCompositions() async {
  try {
    final token = await TokenStorage.getToken();
    final resp = await http
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}/api/mst/material/barang-jadi-compositions',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return [];
    final body =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map(
          (e) => _BarangJadiComposition.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  } catch (_) {
    return [];
  }
}

Future<OutputMappingResult?> _fetchOutputMapping({
  required int idCetakan,
  required int idWarna,
  int? idFurnitureMaterial,
}) async {
  try {
    final token = await TokenStorage.getToken();
    var url =
        '${ApiConstants.baseUrl}/api/mst/material/output?idCetakan=$idCetakan&idWarna=$idWarna';
    if (idFurnitureMaterial != null && idFurnitureMaterial != 0) {
      url += '&idFurnitureMaterial=$idFurnitureMaterial';
    }
    final resp = await http
        .get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final body =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    final outputType = data['outputType'] as String? ?? '';
    final items = (data['items'] as List? ?? [])
        .map(
          (e) =>
              OutputMappingItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    return OutputMappingResult(outputType: outputType, items: items);
  } catch (_) {
    return null;
  }
}

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
    final hasMaterial =
        selectedMaterial != null && selectedMaterial!.idFurnitureMaterial != 0;

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
              Icon(icon, size: 10, color: const Color(0xFF9CA3AF)),
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
              color: isEmpty
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF374151),
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

  OutputMappingResult? _outputResult;
  bool _loadingOutput = false;

  @override
  void initState() {
    super.initState();
    _selectedCetakan = widget.initialCetakan;
    _selectedWarna = widget.initialWarna;
    _selectedMaterial = widget.initialMaterial;

    if (_selectedCetakan != null) {
      final savedWarna = widget.initialWarna;
      final savedMaterial = widget.initialMaterial;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadWarna(_selectedCetakan!.idCetakan);
        if (savedWarna != null && mounted) {
          setState(() => _selectedWarna = savedWarna);
          await _loadMaterial(_selectedCetakan!.idCetakan, savedWarna.idWarna);
          if (savedMaterial != null && mounted) {
            setState(() => _selectedMaterial = savedMaterial);
          }
          await _refreshOutput();
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
      _outputResult = null;
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
      _outputResult = null;
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

  Future<void> _refreshOutput() async {
    final cetakan = _selectedCetakan;
    final warna = _selectedWarna;
    if (cetakan == null || warna == null) {
      if (mounted) setState(() => _outputResult = null);
      return;
    }
    if (mounted) setState(() => _loadingOutput = true);
    final result = await _fetchOutputMapping(
      idCetakan: cetakan.idCetakan,
      idWarna: warna.idWarna,
      idFurnitureMaterial: _selectedMaterial?.idFurnitureMaterial,
    );
    if (!mounted) return;
    setState(() {
      _outputResult = result;
      _loadingOutput = false;
    });
  }

  bool get _canConfirm => _selectedCetakan != null && _selectedWarna != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
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
                      child: const Icon(
                        Icons.layers_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
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
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
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
                                          setState(() => _selectedCetakan = c);
                                          await _loadWarna(c.idCetakan);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

                    // ── Kolom 2: Warna ────────────────────────────────
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          _ColHeader(
                            label: 'WARNA',
                            icon: Icons.palette_outlined,
                            color: const Color(0xFF475569),
                          ),
                          Expanded(
                            child: _selectedCetakan == null
                                ? const _EmptyMsg(
                                    'Pilih cetakan\nterlebih dahulu',
                                  )
                                : _loadingWarna
                                ? const ListItemSkeleton()
                                : _warnaList.isEmpty
                                ? const _EmptyMsg(
                                    'Tidak ada warna\nuntuk cetakan ini',
                                  )
                                : ListView.builder(
                                    itemCount: _warnaList.length,
                                    itemBuilder: (_, i) {
                                      final w = _warnaList[i];
                                      final active =
                                          _selectedWarna?.idWarna == w.idWarna;
                                      return _ListItem(
                                        label: w.warna,
                                        isActive: active,
                                        activeColor: const Color(0xFF2563EB),
                                        onTap: () async {
                                          setState(() => _selectedWarna = w);
                                          await _loadMaterial(
                                            _selectedCetakan!.idCetakan,
                                            w.idWarna,
                                          );
                                          await _refreshOutput();
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

                    // ── Kolom 3:  Material ───────────────────
                    Expanded(
                      child: Column(
                        children: [
                          _ColHeader(
                            label: 'MATERIAL',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF475569),
                          ),
                          Expanded(
                            child: _selectedWarna == null
                                ? const _EmptyMsg(
                                    'Pilih warna\nterlebih dahulu',
                                  )
                                : _loadingMaterial
                                ? const ListItemSkeleton()
                                : _materialList.isEmpty
                                ? _NoMaterialItem(
                                    isSelected: _selectedMaterial == null,
                                    onTap: () async {
                                      setState(() => _selectedMaterial = null);
                                      await _refreshOutput();
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: _materialList.length + 1,
                                    itemBuilder: (_, i) {
                                      if (i == 0) {
                                        return _NoMaterialItem(
                                          isSelected: _selectedMaterial == null,
                                          onTap: () async {
                                            setState(
                                              () => _selectedMaterial = null,
                                            );
                                            await _refreshOutput();
                                          },
                                        );
                                      }
                                      final m = _materialList[i - 1];
                                      final active =
                                          _selectedMaterial
                                              ?.idFurnitureMaterial ==
                                          m.idFurnitureMaterial;
                                      return _ListItem(
                                        label: m.displayText,
                                        sublabel: m.itemCode,
                                        isActive: active,
                                        activeColor: const Color(0xFF2563EB),
                                        onTap: () async {
                                          setState(() => _selectedMaterial = m);
                                          await _refreshOutput();
                                        },
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

              // ── Output mapping strip ─────────────────────────────────
              if (_loadingOutput ||
                  (_outputResult != null && _selectedWarna != null))
                _OutputMappingStrip(
                  loading: _loadingOutput,
                  result: _outputResult,
                ),

              // ── Footer ──────────────────────────────────────────────
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _PanduanDialog(),
                      ),
                      icon: const Icon(Icons.menu_book_outlined, size: 15),
                      label: const Text('Panduan'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                    ),
                    const Spacer(),
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
                        backgroundColor: const Color(0xFF2563EB),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      color: isActive ? activeColor : const Color(0xFF374151),
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
  const _NoMaterialItem({required this.isSelected, required this.onTap});
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2563EB);
    const inactiveColor = Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected
            ? activeColor.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tidak ada material',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 14, color: activeColor),
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

class _OutputMappingStrip extends StatelessWidget {
  const _OutputMappingStrip({required this.loading, required this.result});
  final bool loading;
  final OutputMappingResult? result;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 8),
            Text(
              'Mengecek output...',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    final r = result;
    if (r == null || r.items.isEmpty) return const SizedBox.shrink();

    final isBarangJadi = r.outputType == 'barangjadi';
    const badgeColor = Color(0xFF16A34A);
    final badgeLabel = isBarangJadi ? 'Barang Jadi' : 'Furniture WIP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: badgeColor.withValues(alpha: 0.2)),
          bottom: BorderSide(color: badgeColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.output_rounded, size: 13, color: badgeColor),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: r.items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        item.namaOutput,
                        style: TextStyle(
                          fontSize: 10,
                          color: badgeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panduan dialog: daftar Furniture WIP beserta komposisi cetakan+warna+material
// ─────────────────────────────────────────────────────────────────────────────

class _PanduanDialog extends StatefulWidget {
  const _PanduanDialog();

  @override
  State<_PanduanDialog> createState() => _PanduanDialogState();
}

class _PanduanDialogState extends State<_PanduanDialog>
    with SingleTickerProviderStateMixin {
  // Furniture WIP
  List<_WipComposition> _allWip = [];
  List<_WipComposition> _filteredWip = [];
  bool _loadingWip = true;

  // Barang Jadi
  List<_BarangJadiComposition> _allBj = [];
  List<_BarangJadiComposition> _filteredBj = [];
  bool _loadingBj = true;

  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      _searchCtrl.clear();
      setState(() {});
    });
    _loadWip();
    _loadBj();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWip() async {
    final data = await _fetchWipCompositions();
    if (!mounted) return;
    setState(() {
      _allWip = data;
      _filteredWip = data;
      _loadingWip = false;
    });
  }

  Future<void> _loadBj() async {
    final data = await _fetchBarangJadiCompositions();
    if (!mounted) return;
    setState(() {
      _allBj = data;
      _filteredBj = data;
      _loadingBj = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (_tabCtrl.index == 0) {
        _filteredWip = q.isEmpty
            ? _allWip
            : _allWip
                  .where((w) => w.namaFurnitureWIP.toLowerCase().contains(q))
                  .toList();
      } else {
        _filteredBj = q.isEmpty
            ? _allBj
            : _allBj
                  .where((b) => b.namaBarangJadi.toLowerCase().contains(q))
                  .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 640,
        height: 620,
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
              // header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Panduan Cetakan, Warna & Material',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabCtrl,
                      indicatorColor: Colors.white,
                      indicatorWeight: 2.5,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: const [
                        Tab(text: 'Furniture WIP'),
                        Tab(text: 'Barang Jadi'),
                      ],
                    ),
                  ],
                ),
              ),

              // search
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: _tabCtrl.index == 0
                        ? 'Cari jenis Furniture WIP...'
                        : 'Cari jenis Barang Jadi...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              // list
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // ── Tab 0: Furniture WIP ────────────────────────
                    _buildList(
                      loading: _loadingWip,
                      isEmpty: _filteredWip.isEmpty,
                      child: Column(
                        children: [
                          const _PanduanTableHeader(
                            jenisLabel: 'JENIS FURNITURE WIP',
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredWip.length,
                              itemBuilder: (_, i) => _PanduanItem(
                                nama: _filteredWip[i].namaFurnitureWIP,
                                komposisi: _filteredWip[i].komposisi,
                                isEven: i.isEven,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Tab 1: Barang Jadi ──────────────────────────
                    _buildList(
                      loading: _loadingBj,
                      isEmpty: _filteredBj.isEmpty,
                      child: Column(
                        children: [
                          const _PanduanTableHeader(
                            jenisLabel: 'JENIS BARANG JADI',
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredBj.length,
                              itemBuilder: (_, i) => _PanduanItem(
                                nama: _filteredBj[i].namaBarangJadi,
                                komposisi: _filteredBj[i].komposisi,
                                isEven: i.isEven,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildList({
    required bool loading,
    required bool isEmpty,
    required Widget child,
  }) {
    if (loading) return const TableRowSkeleton();
    if (isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return child;
  }
}

// ── Table header (rendered once above the list) ───────────────────────────────

class _PanduanTableHeader extends StatelessWidget {
  const _PanduanTableHeader({this.jenisLabel = 'JENIS FURNITURE WIP'});
  final String jenisLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              jenisLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: Text(
              'CETAKAN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Text(
              'WARNA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: Text(
              'MATERIAL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── One row per komposisi entry ───────────────────────────────────────────────

class _PanduanItem extends StatelessWidget {
  const _PanduanItem({
    required this.nama,
    required this.komposisi,
    required this.isEven,
  });
  final String nama;
  final List<_WipKomposisi> komposisi;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final rows = komposisi;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: List.generate(rows.length, (i) {
                final k = rows[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: i == 0
                            ? Text(
                                nama,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          k.namaCetakan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          k.namaWarna,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          k.namaFurnitureMaterial ?? '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: k.namaFurnitureMaterial != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF9CA3AF),
                            fontStyle: k.namaFurnitureMaterial == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}
