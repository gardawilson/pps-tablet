import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);

/// Dialog untuk memilih tanggal sebelum generate stock opname baru.
/// Pop `DateTime?` — null berarti dibatalkan.
class SoV2GenerateDateDialog extends StatefulWidget {
  final String categoryName;

  const SoV2GenerateDateDialog({super.key, required this.categoryName});

  @override
  State<SoV2GenerateDateDialog> createState() =>
      _SoV2GenerateDateDialogState();
}

class _SoV2GenerateDateDialogState extends State<SoV2GenerateDateDialog> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: _kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Generate Stock Opname',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.categoryName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _kPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(
                          _selectedDate,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_selectedDate),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 15),
                    label: const Text(
                      'Generate',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
