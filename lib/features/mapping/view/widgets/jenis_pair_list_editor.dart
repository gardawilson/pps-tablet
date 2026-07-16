import 'package:flutter/material.dart';

import 'package:pps_tablet/common/widgets/search_dropdown_field.dart';
import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';

const Color _primary = Color(0xFF0D47A1);

class JenisPairValue {
  final MasterKategori kategori;
  final MasterJenis jenis;

  const JenisPairValue({required this.kategori, required this.jenis});

  Map<String, dynamic> toJson() => {
        'IdKategori': kategori.idKategori,
        'IdJenis': jenis.idJenis,
      };
}

class _PairEntry {
  MasterKategori? kategori;
  MasterJenis? jenis;
  List<MasterJenis> jenisOptions;
  bool loadingJenis;

  _PairEntry({this.kategori})
      : jenisOptions = [],
        loadingJenis = false;
}

/// Editor untuk daftar pasangan kategori-jenis (multi kategori/jenis per lokasi).
class JenisPairListEditor extends StatefulWidget {
  final MappingRepository repository;
  final List<LokasiJenis> initial;
  final ValueChanged<List<JenisPairValue>> onChanged;

  const JenisPairListEditor({
    super.key,
    required this.repository,
    required this.onChanged,
    this.initial = const [],
  });

  @override
  State<JenisPairListEditor> createState() => JenisPairListEditorState();
}

class JenisPairListEditorState extends State<JenisPairListEditor> {
  bool _loadingKategori = true;
  String? _error;
  List<MasterKategori> _kategoriList = [];
  final List<_PairEntry> _entries = [];

  bool get isReady => !_loadingKategori;

  // Minimal 1 jenis wajib diisi — lokasi tidak boleh disimpan tanpa jenis.
  bool get isValid =>
      _entries.isNotEmpty &&
      _entries.every((e) => e.kategori != null && e.jenis != null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.repository.fetchKategori();
      setState(() {
        _kategoriList = list;
        _loadingKategori = false;
      });
      for (final j in widget.initial) {
        final kategori =
            list.where((k) => k.idKategori == j.idKategori).firstOrNull;
        if (kategori == null) continue;
        final entry = _PairEntry(kategori: kategori);
        _entries.add(entry);
        setState(() {});
        await _loadJenisFor(entry, preselectIdJenis: j.idJenis);
      }
      _emitChange();
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.friendlyMessage : e.toString();
        _loadingKategori = false;
      });
    }
  }

  Future<void> _loadJenisFor(_PairEntry entry, {int? preselectIdJenis}) async {
    setState(() {
      entry.loadingJenis = true;
      entry.jenisOptions = [];
      entry.jenis = null;
    });
    try {
      final list = await widget.repository.fetchJenis(entry.kategori!.idKategori);
      setState(() {
        entry.jenisOptions = list;
        entry.loadingJenis = false;
        if (preselectIdJenis != null) {
          entry.jenis =
              list.where((j) => j.idJenis == preselectIdJenis).firstOrNull;
        }
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.friendlyMessage : e.toString();
        entry.loadingJenis = false;
      });
    }
  }

  void _emitChange() {
    final values = _entries
        .where((e) => e.kategori != null && e.jenis != null)
        .map((e) => JenisPairValue(kategori: e.kategori!, jenis: e.jenis!))
        .toList();
    widget.onChanged(values);
  }

  void _addEntry() {
    setState(() => _entries.add(_PairEntry()));
    _emitChange();
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _emitChange();
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
    if (_loadingKategori) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
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
              style: TextStyle(fontSize: 11, color: Colors.red.shade700),
            ),
          ),
        Row(
          children: [
            const Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Kategori & Jenis ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _addEntry,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: _primary),
                    SizedBox(width: 2),
                    Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Minimal 1 kategori/jenis wajib diisi. Tekan "Tambah" untuk menambahkan.',
              style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            ),
          )
        else
          for (int i = 0; i < _entries.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Jenis ${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeEntry(i),
                        borderRadius: BorderRadius.circular(6),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildDropdown<MasterKategori>(
                    value: _entries[i].kategori,
                    hint: 'Pilih kategori',
                    items: _kategoriList,
                    itemLabel: (k) => k.namaKategori,
                    onChanged: (val) async {
                      setState(() {
                        _entries[i].kategori = val;
                        _entries[i].jenis = null;
                        _entries[i].jenisOptions = [];
                      });
                      if (val != null) {
                        await _loadJenisFor(_entries[i]);
                      }
                      _emitChange();
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_entries[i].loadingJenis)
                    const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    SearchDropdownField<MasterJenis>(
                      value: _entries[i].jenis,
                      items: _entries[i].jenisOptions,
                      itemAsString: (j) => j.namaJenis,
                      hint: _entries[i].kategori == null
                          ? 'Pilih kategori dahulu'
                          : 'Pilih jenis',
                      searchHint: 'Cari jenis...',
                      enabled: _entries[i].kategori != null,
                      fieldHeight: 40,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      onChanged: _entries[i].kategori == null
                          ? null
                          : (val) {
                              setState(() => _entries[i].jenis = val);
                              _emitChange();
                            },
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
