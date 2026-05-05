import 'package:flutter/material.dart';
import 'package:pps_tablet/core/services/user_session_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primaryColor = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor.withValues(alpha: 0.04), Colors.white],
          ),
        ),
        child: Center(
          child: FutureBuilder<String>(
            future: UserSessionStorage.getUsername(fallback: '-'),
            builder: (context, snapshot) {
              final username = snapshot.data ?? '-';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selamat datang, $username',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PPS Tablet',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
