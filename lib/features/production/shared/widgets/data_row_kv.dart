import 'package:flutter/material.dart';


class DataRowKV extends StatelessWidget {
  final String label;
  final String value;
  const DataRowKV(this.label, this.value, {super.key});


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ),
        const Text(': ', style: TextStyle(fontSize: 11)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}