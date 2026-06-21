import 'package:flutter/material.dart';

import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/core/network/api_client.dart';

const Color _primary = Color(0xFF0D47A1);

class EditLokasiDialog extends StatefulWidget {
  final String blok;
  final int idLokasi;
  final String lokasiLabel;
  final int initialIdKategori;
  final int initialIdJenis;
  const EditLokasiDialog({
    super.key,
    required this.blok,
    required this.idLokasi,
    required this.lokasiLabel,
    this.initialIdKategori = 0,
    this.initialIdJenis = 0,
  });

  @override
  State<EditLokasiDialog> createState() => _EditLokasiDialogState();
}

class _EditLokasiDialogState extends State<EditLokasiDialog> {
  final _repo = MappingRepository(api: ApiClient());

  bool _loadingKategori = true;
  bool _loadingJenis = false;
  bool _saving = false;
  String? _error;

  List<MasterKategori> _kategoriList = [];
  List<MasterJenis> _jenisList = [];

  MasterKategori? _selectedKategori;
  MasterJenis? _selectedJenis;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    try {
      final list = await _repo.fetchKategori();
      setState(() {
        _kategoriList = list;
        _loadingKategori = false;
        if (widget.initialIdKategori != 0) {
          _selectedKategori = list
              .where((k) => k.idKategori == widget.initialIdKategori)
              .firstOrNull;
          if (_selectedKategori != null) {
            _loadJenis(_selectedKategori!.idKategori);
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingKategori = false;
      });
    }
  }

  Future<void> _loadJenis(int idKategori) async {
    setState(() {
      _loadingJenis = true;
      _jenisList = [];
      _selectedJenis = null;
    });
    try {
      final list = await _repo.fetchJenis(idKategori);
      setState(() {
        _jenisList = list;
        _loadingJenis = false;
        if (widget.initialIdJenis != 0) {
          _selectedJenis = list
              .where((j) => j.idJenis == widget.initialIdJenis)
              .firstOrNull;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingJenis = false;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedKategori == null || _selectedJenis == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateLokasi(widget.blok, widget.idLokasi, {
        'IdKategori': _selectedKategori!.idKategori,
        'IdJenis': _selectedJenis!.idJenis,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?)? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.lokasiLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Edit Lokasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: _loadingKategori
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style:
                            TextStyle(fontSize: 11, color: Colors.red.shade700),
                      ),
                    ),
                  // Kategori dropdown
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _buildDropdown<MasterKategori>(
                    value: _selectedKategori,
                    hint: 'Pilih kategori',
                    items: _kategoriList,
                    itemLabel: (k) => k.namaKategori,
                    onChanged: (val) {
                      setState(() {
                        _selectedKategori = val;
                        _selectedJenis = null;
                        _jenisList = [];
                      });
                      if (val != null) _loadJenis(val.idKategori);
                    },
                  ),
                  const SizedBox(height: 14),
                  // Jenis dropdown
                  const Text(
                    'Jenis',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (_loadingJenis)
                    const SizedBox(
                      height: 48,
                      child: Center(
                          child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )),
                    )
                  else
                    _buildDropdown<MasterJenis>(
                      value: _selectedJenis,
                      hint: _selectedKategori == null
                          ? 'Pilih kategori dahulu'
                          : 'Pilih jenis',
                      items: _jenisList,
                      itemLabel: (j) => j.namaJenis,
                      onChanged: _selectedKategori == null
                          ? null
                          : (val) => setState(() => _selectedJenis = val),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: (_selectedKategori != null &&
                  _selectedJenis != null &&
                  !_saving)
              ? _save
              : null,
          style: FilledButton.styleFrom(backgroundColor: _primary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
