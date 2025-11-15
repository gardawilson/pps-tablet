import 'package:flutter/material.dart';

/// Dialog reusable untuk input manual kode label
class ManualLabelInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String hintText;
  final String? initialValue;

  const ManualLabelInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.hintText,
    this.initialValue,
  });

  /// Helper static untuk memanggil dialog dan langsung dapat hasilnya
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String labelText,
    required String hintText,
    String? initialValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ManualLabelInputDialog(
        title: title,
        labelText: labelText,
        hintText: hintText,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<ManualLabelInputDialog> createState() =>
      _ManualLabelInputDialogState();
}

class _ManualLabelInputDialogState extends State<ManualLabelInputDialog> {
  late final TextEditingController _ctl;
  String? _errorText;
  bool _hasTriedSubmit = false;

  // Regex:
  // A.1234567890-1  => A. + 10 digit + '-' + 1+ digit
  static final RegExp _regexA =
  RegExp(r'^A\.[0-9]{10}-[0-9]+$');

  // B.1234567890 atau BF.1234567890, dll
  static final RegExp _regexOther =
  RegExp(r'^(?:D|B|F|V|H|BF)\.[0-9]{10}$');

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final v = value.trim().toUpperCase();

    if (v.isEmpty) {
      return 'Kode tidak boleh kosong';
    }

    if (v.startsWith('A.')) {
      if (!_regexA.hasMatch(v)) {
        return 'Format tidak valid';
      }
      return null;
    }

    // prefix lain: D, B, F, V, H, BF
    if (!_regexOther.hasMatch(v)) {
      return 'Format tidak valid';
    }

    return null;
  }

  void _submit() {
    final raw = _ctl.text;
    final v = raw.trim().toUpperCase();

    final err = _validate(v);

    setState(() {
      _hasTriedSubmit = true;
      _errorText = err;
    });

    if (err != null) {
      // Jangan tutup dialog kalau masih error
      return;
    }

    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masukkan kode label secara manual.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctl,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onChanged: (value) {
              // Hanya re-validate kalau user sudah pernah klik "Pakai"
              if (_hasTriedSubmit) {
                setState(() {
                  _errorText = _validate(value);
                });
              }
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              hintMaxLines: 2, // ⬅ hint bisa 2 baris, tidak mudah ter-ellipsis
              prefixIcon: const Icon(Icons.qr_code_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              errorText: _hasTriedSubmit ? _errorText : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Contoh:\n• A.1234567890-1\n• B.1234567890 / BF.1234567890',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Pakai'),
        ),
      ],
    );
  }
}
