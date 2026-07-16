import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view/widgets/jenis_pair_list_editor.dart';
import 'package:pps_tablet/core/network/api_client.dart';

const Color _primary = Color(0xFF0D47A1);

class AddLokasiDialog extends StatefulWidget {
  final String blok;
  final String? namaWarehouse;
  final Set<int> existingIds;

  const AddLokasiDialog({
    super.key,
    required this.blok,
    this.namaWarehouse,
    this.existingIds = const {},
  });

  @override
  State<AddLokasiDialog> createState() => _AddLokasiDialogState();
}

class _AddLokasiDialogState extends State<AddLokasiDialog> {
  final _repo = MappingRepository(api: ApiClient());
  late final TextEditingController _idCtrl;
  final _editorKey = GlobalKey<JenisPairListEditorState>();

  bool _saving = false;
  String? _error;
  List<JenisPairValue> _pairs = [];

  @override
  void initState() {
    super.initState();
    final nextId = widget.existingIds.isEmpty
        ? 1
        : widget.existingIds.reduce((a, b) => a > b ? a : b) + 1;
    _idCtrl = TextEditingController(text: '$nextId');
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  int? get _parsedId => int.tryParse(_idCtrl.text.trim());

  bool get _isDuplicate =>
      _parsedId != null && widget.existingIds.contains(_parsedId);

  String? get _idErrorText {
    if (_idCtrl.text.trim().isEmpty) return null;
    if (_parsedId == null || _parsedId! <= 0) return 'ID lokasi tidak valid';
    if (_isDuplicate) return 'ID $_parsedId sudah dipakai lokasi lain';
    return null;
  }

  bool get _isValid {
    final id = _parsedId;
    return id != null &&
        id > 0 &&
        !_isDuplicate &&
        (_editorKey.currentState?.isValid ?? false);
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.createLokasi(widget.blok, {
        'IdLokasi': _parsedId,
        'JenisList': _pairs.map((p) => p.toJson()).toList(),
        'Enable': true,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.friendlyMessage : e.toString();
        _saving = false;
      });
    }
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
              'Blok ${widget.blok}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tambah Lokasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (widget.namaWarehouse?.isNotEmpty == true)
                  Text(
                    widget.namaWarehouse!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
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
              // ID Lokasi
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ID Lokasi',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_idErrorText != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _idErrorText!,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                  ),
                ),
              ] else if (widget.existingIds.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ID disarankan otomatis, boleh diubah',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              JenisPairListEditor(
                key: _editorKey,
                repository: _repo,
                onChanged: (pairs) => setState(() => _pairs = pairs),
              ),
            ],
          ),
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
