import 'package:flutter/material.dart';

class ActionLozenge extends StatelessWidget {
  final String action;

  const ActionLozenge({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            action.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: config.textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _LozengeConfig _getConfig(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFE3FCEF),
          textColor: const Color(0xFF006644),
          dotColor: const Color(0xFF36B37E),
        );

      case 'UPDATE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFDEEBFF),
          textColor: const Color(0xFF0747A6),
          dotColor: const Color(0xFF0052CC),
        );

      case 'DELETE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFEBEB),
          textColor: const Color(0xFFBF2600),
          dotColor: const Color(0xFFDE350B),
        );

      case 'CONSUME':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFF0E5),
          textColor: const Color(0xFF974F0C),
          dotColor: const Color(0xFFFF991F),
        );

      case 'UNCONSUME':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFEAE6FF),
          textColor: const Color(0xFF403294),
          dotColor: const Color(0xFF6554C0),
        );

      case 'PRODUCE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFE6FCFF),
          textColor: const Color(0xFF008DA6),
          dotColor: const Color(0xFF00B8D9),
        );

      case 'UNPRODUCE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFF0F6),
          textColor: const Color(0xFF943D73),
          dotColor: const Color(0xFFC74590),
        );

      // 🔥 NEW — ADJUST
      case 'ADJUST':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFF7E6),
          textColor: const Color(0xFF8F5A00),
          dotColor: const Color(0xFFFFAB00),
        );

      default:
        return _LozengeConfig(
          backgroundColor: const Color(0xFFF4F5F7),
          textColor: const Color(0xFF42526E),
          dotColor: const Color(0xFF6B778C),
        );
    }
  }
}

class _LozengeConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  _LozengeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}
