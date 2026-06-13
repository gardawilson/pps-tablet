import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/inject_hourly_model.dart';

const _kPrimary = Color(0xFF0277BD);
const _kBorder = Color(0xFFE2E6EA);

class InjectHourlyDialog extends StatefulWidget {
  final String noProduksi;

  const InjectHourlyDialog({super.key, required this.noProduksi});

  @override
  State<InjectHourlyDialog> createState() => _InjectHourlyDialogState();
}

class _InjectHourlyDialogState extends State<InjectHourlyDialog> {
  // TODO: ganti dengan data dari API
  final List<InjectHourlyEntry> _entries = [];
  bool _showForm = false;

  // form controllers
  String? _selectedJam;
  final _beratCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _counterCtrl = TextEditingController();

  static List<String> get _jamOptions {
    return List.generate(24, (i) {
      final h = i.toString().padLeft(2, '0');
      return '$h:00';
    });
  }

  @override
  void initState() {
    super.initState();
    _initDefaultJam();
    // TODO: _loadFromApi();
  }

  void _initDefaultJam() {
    final now = TimeOfDay.now();
    _selectedJam = '${now.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  void dispose() {
    _beratCtrl.dispose();
    _cycleCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  bool get _formValid {
    if (_selectedJam == null) return false;
    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final cycle = double.tryParse(_cycleCtrl.text.replaceAll(',', '.'));
    final counter = int.tryParse(_counterCtrl.text);
    return berat != null && berat > 0 && cycle != null && cycle > 0 && counter != null && counter > 0;
  }

  void _submitForm() {
    if (!_formValid) return;
    final entry = InjectHourlyEntry(
      noProduksi: widget.noProduksi,
      jam: _selectedJam!,
      berat: double.tryParse(_beratCtrl.text.replaceAll(',', '.')),
      cycleTime: double.tryParse(_cycleCtrl.text.replaceAll(',', '.')),
      counter: int.tryParse(_counterCtrl.text),
    );

    // TODO: kirim ke API, lalu refresh list
    setState(() {
      final existing = _entries.indexWhere((e) => e.jam == entry.jam);
      if (existing >= 0) {
        _entries[existing] = entry;
      } else {
        _entries.add(entry);
        _entries.sort((a, b) => a.jam.compareTo(b.jam));
      }
      _showForm = false;
    });
  }

  void _openFormForJam(String jam) {
    final existing = _entries.where((e) => e.jam == jam).firstOrNull;
    setState(() {
      _selectedJam = jam;
      _beratCtrl.text = existing?.berat?.toString() ?? '';
      _cycleCtrl.text = existing?.cycleTime?.toString() ?? '';
      _counterCtrl.text = existing?.counter?.toString() ?? '';
      _showForm = true;
    });
  }

  void _openFormNew() {
    _initDefaultJam();
    _beratCtrl.clear();
    _cycleCtrl.clear();
    _counterCtrl.clear();
    setState(() => _showForm = true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _kBorder),
            if (_showForm) _buildForm() else _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.timer_outlined, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Per Jam',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  widget.noProduksi,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (_showForm)
            TextButton(
              onPressed: () => setState(() => _showForm = false),
              child: const Text('Batal'),
            )
          else ...[
            TextButton.icon(
              onPressed: _openFormNew,
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Tambah', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada data per jam.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Tambah" untuk mulai input.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // table header
          Container(
            color: const Color(0xFFF8F9FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _headerCell('Jam', flex: 2),
                _headerCell('Berat (kg)', flex: 3),
                _headerCell('Cycle (dtk)', flex: 3),
                _headerCell('Counter', flex: 3),
                const SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
              itemBuilder: (_, i) {
                final e = _entries[i];
                return InkWell(
                  onTap: () => _openFormForJam(e.jam),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        _dataCell(e.jam, flex: 2, bold: true, color: _kPrimary),
                        _dataCell(e.berat != null ? '${e.berat}' : '-', flex: 3),
                        _dataCell(e.cycleTime != null ? '${e.cycleTime}' : '-', flex: 3),
                        _dataCell(e.counter != null ? '${e.counter}' : '-', flex: 3),
                        SizedBox(
                          width: 32,
                          child: Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          // summary footer
          if (_entries.isNotEmpty) _buildSummaryFooter(),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter() {
    final totalBerat = _entries.fold<double>(0, (s, e) => s + (e.berat ?? 0));
    final avgCycle = _entries.where((e) => e.cycleTime != null).isEmpty
        ? null
        : _entries.where((e) => e.cycleTime != null).fold<double>(0, (s, e) => s + e.cycleTime!) /
            _entries.where((e) => e.cycleTime != null).length;
    final totalCounter = _entries.fold<int>(0, (s, e) => s + (e.counter ?? 0));

    return Container(
      color: _kPrimary.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _dataCell('Total', flex: 2, bold: true),
          _dataCell('${totalBerat.toStringAsFixed(1)} kg', flex: 3, bold: true),
          _dataCell(
            avgCycle != null ? 'avg ${avgCycle.toStringAsFixed(1)}' : '-',
            flex: 3,
            bold: true,
          ),
          _dataCell('$totalCounter', flex: 3, bold: true),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jam picker
          Text(
            'Jam',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedJam,
            decoration: _inputDecoration('Pilih jam'),
            items: _jamOptions
                .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                .toList(),
            onChanged: (v) => setState(() => _selectedJam = v),
          ),
          const SizedBox(height: 14),

          // 3 fields baris
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Berat (kg)',
                  controller: _beratCtrl,
                  hint: '0.0',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  label: 'Cycle Time (detik)',
                  controller: _cycleCtrl,
                  hint: '0.0',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  label: 'Counter',
                  controller: _counterCtrl,
                  hint: '0',
                  decimal: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showForm = false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _formValid ? _submitForm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool decimal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'^\d*[,.]?\d*') : RegExp(r'\d+'),
            ),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: _inputDecoration(hint),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    required int flex,
    bool bold = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: color ?? const Color(0xFF1F2937),
        ),
      ),
    );
  }
}
