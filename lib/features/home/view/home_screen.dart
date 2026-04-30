import 'package:flutter/material.dart';

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
        child: const Center(
          child: Text(
            'Hello World',
            style: TextStyle(fontSize: 24, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
