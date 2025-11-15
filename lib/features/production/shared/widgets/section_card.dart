import 'package:flutter/material.dart';


class SectionCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.count, required this.color, required this.child});


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
          ),
          child: Row(children: [
            Icon(Icons.folder_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Expanded(child: child),
      ]),
    );
  }
}