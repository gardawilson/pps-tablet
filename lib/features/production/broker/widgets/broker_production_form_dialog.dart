// lib/view/widgets/broker_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pps_tablet/features/mesin/widgets/mesin_dropdown.dart';

import '../../../mesin/model/mesin_model.dart';
import '../model/broker_production_model.dart';
import 'broker_text_field.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../common/widgets/app_date_field.dart';



class BrokerProductionFormDialog extends StatefulWidget {
  final BrokerProduction? header;
  final Function(BrokerProduction)? onSave;

  const BrokerProductionFormDialog({
    super.key,
    this.header,
    this.onSave,
  });

  @override
  State<BrokerProductionFormDialog> createState() => _BrokerProductionFormDialogState();
}

class _BrokerProductionFormDialogState extends State<BrokerProductionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController noCrusherCtrl;
  late final TextEditingController dateCreatedCtrl;
  late final TextEditingController mesinCtrl;

  // State
  MstMesin? _selectedMesin;
  DateTime _selectedDate = DateTime.now();

  // Inline error text under process dropdowns
  String? _crusherProductionError;
  String? _bongkarSusunError;

  @override
  void initState() {
    super.initState();
    noCrusherCtrl = TextEditingController(text: widget.header?.noProduksi ?? '');

    final DateTime seededDate = widget.header != null
        ? (parseAnyToDateTime(widget.header!.tglProduksi) ?? DateTime.now())
        : DateTime.now();

    _selectedDate = seededDate;
    dateCreatedCtrl = TextEditingController(
      text: DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(seededDate),
    );

    mesinCtrl = TextEditingController(text: widget.header?.namaMesin ?? '');


  }

  @override
  void dispose() {
    noCrusherCtrl.dispose();
    dateCreatedCtrl.dispose();

    super.dispose();
  }

  bool get isEdit => widget.header != null;




  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildLeftColumn()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEdit ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEdit ? Icons.edit : Icons.add,
            color: isEdit ? Colors.orange.shade700 : Colors.green.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'Edit Label' : 'Tambah Label Baru',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Header', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            BrokerTextField(
              controller: noCrusherCtrl,
              label: 'No. Produksi',
              icon: Icons.label,
              asText: true, // readonly text
            ),

            const SizedBox(height: 16),

            AppDateField(
              controller: dateCreatedCtrl,
              label: 'Date Created',
              format: DateFormat('EEEE, dd MMM yyyy', 'id_ID'),
              initialDate: _selectedDate,
              // Date picker is always valid here; you can add extra rules if needed.
              onChanged: (d) {
                if (d != null) {
                  setState(() {
                    _selectedDate = d;
                    dateCreatedCtrl.text = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Jenis Mesin (Required)
            MesinDropdown(
              bagian: 'washing', // or 'WASHING' as required by your API
              preselectId: widget.header?.idMesin,
              hintText: 'Pilih jenis mesin',
              validator: (v) => v == null ? 'Wajib pilih jenis crusher' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (ct) {
                _selectedMesin = ct;
                setState(() {}); // if you show nama in UI
              },
            ),

            const SizedBox(height: 16),

          ]),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        // ElevatedButton(
        //   onPressed: _submit,
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: isEdit ? const Color(0xFFF57C00) : const Color(0xFF00897B),
        //     foregroundColor: Colors.white,
        //     padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        //   ),
        //   child: const Text('SIMPAN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        // ),
      ],
    );
  }
}
