import 'package:flutter/material.dart';

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

class _CategoryEntry {
  MasterKategori? kategori;
  List<MasterJenis> jenisOptions;
  Set<int> selectedJenisIds;
  bool loadingJenis;

  _CategoryEntry({this.kategori})
    : jenisOptions = [],
      selectedJenisIds = {},
      loadingJenis = false;
}

/// Editor untuk daftar kategori, tiap kategori bisa memilih banyak jenis
/// sekaligus (checklist) tanpa perlu menambah kategori yang sama berulang.
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
  final List<_CategoryEntry> _entries = [];

  bool get isReady => !_loadingKategori;

  // Minimal 1 kategori dengan minimal 1 jenis wajib diisi.
  bool get isValid =>
      _entries.isNotEmpty &&
      _entries.every(
        (e) => e.kategori != null && e.selectedJenisIds.isNotEmpty,
      );

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

      // Kelompokkan data awal per kategori agar jenis yang sekategori
      // muncul sebagai satu entry dengan banyak jenis terpilih.
      final grouped = <int, List<LokasiJenis>>{};
      for (final j in widget.initial) {
        grouped.putIfAbsent(j.idKategori, () => []).add(j);
      }

      for (final entryList in grouped.values) {
        final idKategori = entryList.first.idKategori;
        final kategori = list
            .where((k) => k.idKategori == idKategori)
            .firstOrNull;
        if (kategori == null) continue;
        final entry = _CategoryEntry(kategori: kategori);
        _entries.add(entry);
        setState(() {});
        await _loadJenisFor(
          entry,
          preselectIds: entryList.map((j) => j.idJenis).toSet(),
        );
      }
      _emitChange();
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.friendlyMessage : e.toString();
        _loadingKategori = false;
      });
    }
  }

  Future<void> _loadJenisFor(
    _CategoryEntry entry, {
    Set<int>? preselectIds,
  }) async {
    setState(() {
      entry.loadingJenis = true;
      entry.jenisOptions = [];
      entry.selectedJenisIds = {};
    });
    try {
      final list = await widget.repository.fetchJenis(
        entry.kategori!.idKategori,
      );
      setState(() {
        entry.jenisOptions = list;
        entry.loadingJenis = false;
        if (preselectIds != null) {
          entry.selectedJenisIds = list
              .where((j) => preselectIds.contains(j.idJenis))
              .map((j) => j.idJenis)
              .toSet();
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
    final values = <JenisPairValue>[];
    for (final entry in _entries) {
      if (entry.kategori == null) continue;
      for (final jenis in entry.jenisOptions) {
        if (entry.selectedJenisIds.contains(jenis.idJenis)) {
          values.add(JenisPairValue(kategori: entry.kategori!, jenis: jenis));
        }
      }
    }
    widget.onChanged(values);
  }

  void _addEntry() {
    setState(() => _entries.add(_CategoryEntry()));
    _emitChange();
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _emitChange();
  }

  void _toggleJenis(_CategoryEntry entry, MasterJenis jenis, bool selected) {
    setState(() {
      if (selected) {
        entry.selectedJenisIds.add(jenis.idJenis);
      } else {
        entry.selectedJenisIds.remove(jenis.idJenis);
      }
    });
    _emitChange();
  }

  Widget _buildKategoriDropdown(_CategoryEntry entry) {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MasterKategori>(
          value: entry.kategori,
          isExpanded: true,
          hint: const Text('Pilih kategori', style: TextStyle(fontSize: 13)),
          items: _kategoriList
              .map(
                (item) => DropdownMenuItem<MasterKategori>(
                  value: item,
                  child: Text(
                    item.namaKategori,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) async {
            setState(() => entry.kategori = val);
            if (val != null) {
              await _loadJenisFor(entry);
            }
            _emitChange();
          },
        ),
      ),
    );
  }

  Future<void> _openJenisPicker(_CategoryEntry entry) async {
    var tempSelected = Set<int>.from(entry.selectedJenisIds);
    final searchCtrl = TextEditingController();
    var query = '';

    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final filtered = query.isEmpty
              ? entry.jenisOptions
              : entry.jenisOptions
                    .where(
                      (j) => j.namaJenis.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                    )
                    .toList();

          return AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Pilih Jenis${entry.kategori != null ? ' — ${entry.kategori!.namaKategori}' : ''}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 300,
              child: entry.jenisOptions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Tidak ada jenis untuk kategori ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          onChanged: (v) => setSt(() => query = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Cari jenis...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                            ),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setSt(() => query = '');
                                    },
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: _primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${tempSelected.length} dipilih',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: filtered.isEmpty
                                  ? null
                                  : () => setSt(() {
                                      tempSelected.addAll(
                                        filtered.map((j) => j.idJenis),
                                      );
                                    }),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Pilih Semua',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: filtered.isEmpty
                                  ? null
                                  : () => setSt(() {
                                      tempSelected.removeWhere(
                                        (id) => filtered.any(
                                          (j) => j.idJenis == id,
                                        ),
                                      );
                                    }),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.remove_done_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Hapus Semua',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.maxFinite,
                          height: 280,
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'Jenis tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                )
                              : ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final jenis in filtered)
                                      CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        activeColor: _primary,
                                        title: Text(
                                          jenis.namaJenis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        value: tempSelected.contains(
                                          jenis.idJenis,
                                        ),
                                        onChanged: (checked) {
                                          setSt(() {
                                            if (checked ?? false) {
                                              tempSelected.add(jenis.idJenis);
                                            } else {
                                              tempSelected.remove(
                                                jenis.idJenis,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, tempSelected),
                style: FilledButton.styleFrom(backgroundColor: _primary),
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() => entry.selectedJenisIds = result);
      _emitChange();
    }
  }

  Widget _buildJenisField(_CategoryEntry entry) {
    if (entry.loadingJenis) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final enabled = entry.kategori != null;
    final selectedJenis = entry.jenisOptions
        .where((j) => entry.selectedJenisIds.contains(j.idJenis))
        .toList();

    return InkWell(
      onTap: enabled ? () => _openJenisPicker(entry) : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          suffixIcon: Icon(
            Icons.arrow_drop_down_rounded,
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        child: !enabled
            ? Text(
                'Pilih kategori dahulu',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              )
            : selectedJenis.isEmpty
            ? Text(
                'Pilih jenis...',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              )
            : Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final jenis in selectedJenis)
                    Chip(
                      label: Text(
                        jenis.namaJenis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      labelStyle: const TextStyle(color: _primary),
                      backgroundColor: _primary.withValues(alpha: 0.10),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _toggleJenis(entry, jenis, false),
                    ),
                ],
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      'Tambah Kategori',
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
              'Minimal 1 kategori dengan 1 jenis wajib diisi. Tekan "Tambah Kategori" untuk menambahkan.',
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
                          'Kategori ${i + 1}',
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
                  _buildKategoriDropdown(_entries[i]),
                  const SizedBox(height: 8),
                  _buildJenisField(_entries[i]),
                ],
              ),
            ),
      ],
    );
  }
}
