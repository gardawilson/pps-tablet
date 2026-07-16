import 'package:flutter/material.dart';

import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view/widgets/jenis_pair_list_editor.dart';
import 'package:pps_tablet/core/network/api_client.dart';

const Color _primary = Color(0xFF0D47A1);

class EditLokasiDialog extends StatefulWidget {
  final String blok;
  final int idLokasi;
  final String lokasiLabel;
  final List<LokasiJenis> initialJenisList;

  const EditLokasiDialog({
    super.key,
    required this.blok,
    required this.idLokasi,
    required this.lokasiLabel,
    this.initialJenisList = const [],
  });

  @override
  State<EditLokasiDialog> createState() => _EditLokasiDialogState();
}

class _EditLokasiDialogState extends State<EditLokasiDialog> {
  final _repo = MappingRepository(api: ApiClient());
  final _editorKey = GlobalKey<JenisPairListEditorState>();

  bool _saving = false;
  String? _error;
  List<JenisPairValue> _pairs = [];

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateLokasi(widget.blok, widget.idLokasi, {
        'JenisList': _pairs.map((p) => p.toJson()).toList(),
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
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
              JenisPairListEditor(
                key: _editorKey,
                repository: _repo,
                initial: widget.initialJenisList,
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
          onPressed: (!_saving &&
                  (_editorKey.currentState?.isValid ?? false))
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
