import 'package:flutter/material.dart';

class MappingScreen extends StatelessWidget {
  const MappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 52,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Under Construction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur Mapping sedang dalam pengembangan.\nSilahkan cek kembali nanti.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
