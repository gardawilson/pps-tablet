import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/core/network/api_client.dart';

const Color _primary = Color(0xFF0D47A1);

class AddLokasiDialog extends StatefulWidget {
  final String blok;

  const AddLokasiDialog({super.key, required this.blok});

  @override
  State<AddLokasiDialog> createState() => _AddLokasiDialogState();
}

class _AddLokasiDialogState extends State<AddLokasiDialog> {
  final _repo = MappingRepository(api: ApiClient());
  final _idCtrl = TextEditingController();

  bool _loadingKategori = true;
  bool _loadingJenis = false;
  bool _saving = false;
  String? _error;

  List<MasterKategori> _kategoriList = [];
  List<MasterJenis> _jenisList = [];

  MasterKategori? _selectedKategori;
  MasterJenis? _selectedJenis;
  bool _enable = true;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    try {
      final list = await _repo.fetchKategori();
      setState(() {
        _kategoriList = list;
        _loadingKategori = false;
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
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingJenis = false;
      });
    }
  }

  bool get _isValid {
    final id = int.tryParse(_idCtrl.text.trim());
    return id != null && id > 0 && _selectedKategori != null && _selectedJenis != null;
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.createLokasi(widget.blok, {
        'IdLokasi': int.parse(_idCtrl.text.trim()),
        'IdKategori': _selectedKategori!.idKategori,
        'IdJenis': _selectedJenis!.idJenis,
        'Enable': _enable,
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
      title: const Text(
        'Tambah Lokasi',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                        style: TextStyle(
                            fontSize: 11, color: Colors.red.shade700),
                      ),
                    ),
                  // ID Lokasi
                  const Text(
                    'ID Lokasi',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _idCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Masukkan ID lokasi...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: _primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Kategori
                  const Text(
                    'Kategori',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                  // Jenis
                  const Text(
                    'Jenis',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                        ),
                      ),
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
                  const SizedBox(height: 14),
                  // Enable toggle
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Aktif',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _enable,
                        activeThumbColor: _primary,
                        onChanged: (val) => setState(() => _enable = val),
                      ),
                    ],
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
          onPressed: (_isValid && !_saving) ? _save : null,
          style: FilledButton.styleFrom(backgroundColor: _primary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Tambah'),
        ),
      ],
    );
  }
}
