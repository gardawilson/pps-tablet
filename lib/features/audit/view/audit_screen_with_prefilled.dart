// lib/features/audit/screens/audit_screen_with_prefilled.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/audit_view_model.dart';
import 'audit_screen.dart';

/// Wrapper widget untuk AuditScreen dengan document number yang sudah terisi
class AuditScreenWithPrefilledDoc extends StatefulWidget {
  final String documentNo;

  const AuditScreenWithPrefilledDoc({super.key, required this.documentNo});

  @override
  State<AuditScreenWithPrefilledDoc> createState() =>
      _AuditScreenWithPrefilledDocState();
}

class _AuditScreenWithPrefilledDocState
    extends State<AuditScreenWithPrefilledDoc> {
  late AuditViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuditViewModel();

    // 🎯 Auto-fetch history saat screen dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchHistory(documentNo: widget.documentNo);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: AuditScreen(initialDocumentNo: widget.documentNo),
    );
  }
}
