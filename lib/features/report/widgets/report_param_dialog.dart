// lib/core/widgets/report_param_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportParamDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Future<void> Function(DateTime startDate, DateTime endDate) onGenerate;

  const ReportParamDialog({
    super.key,
    required this.title,
    required this.icon,
    this.initialStartDate,
    this.initialEndDate,
    required this.onGenerate,
  });

  @override
  State<ReportParamDialog> createState() => _ReportParamDialogState();
}

class _ReportParamDialogState extends State<ReportParamDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = widget.initialStartDate ?? DateTime(now.year, now.month, 1);
    _endDate = widget.initialEndDate ?? now;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(widget.icon, color: const Color(0xFF0D47A1), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DateField(
            label: 'Tanggal Mulai',
            value: _startDate,
            onPick: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0D47A1),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  if (_endDate != null && _endDate!.isBefore(picked)) {
                    _endDate = picked;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Tanggal Akhir',
            value: _endDate,
            onPick: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0D47A1),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
          label: const Text('Buka PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          onPressed: () async {
            if (_startDate == null || _endDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
              );
              return;
            }

            // Close dialog and execute callback
            Navigator.pop(context);
            await widget.onGenerate(_startDate!, _endDate!);
          },
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '-' : DateFormat('dd MMM yyyy').format(value!);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF0D47A1),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}