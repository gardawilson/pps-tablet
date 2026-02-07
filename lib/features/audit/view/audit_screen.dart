// lib/features/audit/screens/audit_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/empty_state.dart';
import 'package:pps_tablet/common/widgets/error_state.dart';
import 'package:pps_tablet/common/widgets/loading_state.dart';
import 'package:pps_tablet/common/widgets/primary_button.dart';
import 'package:pps_tablet/common/widgets/search_text_field.dart';
import 'package:provider/provider.dart';
import '../view_model/audit_view_model.dart';
import '../widgets/audit_detail_panel.dart';
import '../widgets/audit_session_card.dart';

class AuditScreen extends StatefulWidget {
  final String? initialDocumentNo;

  const AuditScreen({super.key, this.initialDocumentNo});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  late AuditViewModel _viewModel;
  final _documentNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AuditViewModel();

    if (widget.initialDocumentNo != null &&
        widget.initialDocumentNo!.isNotEmpty) {
      _documentNoController.text = widget.initialDocumentNo!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.fetchHistory(documentNo: widget.initialDocumentNo!);
      });
    }
  }

  @override
  void dispose() {
    _documentNoController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0052CC),
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.history, size: 24, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Audit History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          actions: [
            Consumer<AuditViewModel>(
              builder: (context, vm, _) {
                if (vm.currentDocumentNo == null) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                  onPressed: vm.isLoading ? null : _search,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            const Divider(height: 1, color: Color(0xFFDFE1E6)),
            Expanded(
              child: Consumer<AuditViewModel>(
                builder: (context, vm, _) {
                  return Row(
                    children: [
                      // Sessions list (40%)
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: Colors.white,
                          child: _buildSessionsList(vm),
                        ),
                      ),

                      // Divider
                      Container(width: 1, color: const Color(0xFFDFE1E6)),

                      // Detail panel (60%)
                      const Expanded(flex: 6, child: AuditDetailPanel()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDFE1E6))),
      ),
      child: Row(
        children: [
          // Document number input
          Expanded(
            child: SearchTextField(
              controller: _documentNoController,
              label: 'Document Number',
              hint: 'e.g., BG.0000002220, S.0000029967, B.0000013196',
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),

          const SizedBox(width: 12),

          // Search button
          Consumer<AuditViewModel>(
            builder: (context, vm, _) {
              return PrimaryButton(
                onPressed: vm.isLoading ? null : _search,
                isLoading: vm.isLoading,
                label: 'Search',
                icon: Icons.search,
              );
            },
          ),
        ],
      ),
    );
  }

  void _search() {
    final documentNo = _documentNoController.text.trim();

    if (documentNo.isEmpty) {
      _showSnackbar('Please enter document number', isError: true);
      return;
    }

    if (!documentNo.contains('.')) {
      _showSnackbar(
        'Invalid format. Use PREFIX.NUMBER (e.g., BG.0000002220)',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _viewModel.fetchHistory(documentNo: documentNo);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDE350B)
            : const Color(0xFF0052CC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSessionsList(AuditViewModel vm) {
    // Loading state
    if (vm.isLoading) {
      return const LoadingState(message: 'Loading audit history...');
    }

    // Error state
    if (vm.errorMessage.isNotEmpty && vm.sessions.isEmpty) {
      return ErrorState(message: vm.errorMessage, onRetry: _search);
    }

    // Empty state
    if (vm.sessions.isEmpty) {
      final hasSearched = vm.currentModule != null;
      return EmptyState(
        icon: Icons.search,
        iconSize: 100,
        title: hasSearched ? 'No Results Found' : 'Search Audit History',
        subtitle: hasSearched
            ? 'No audit sessions found for this document'
            : 'Enter a document number to begin',
      );
    }

    // Success state - show list
    return _SessionsList(viewModel: vm);
  }
}

// =============================
// Sessions List
// =============================
class _SessionsList extends StatelessWidget {
  final AuditViewModel viewModel;

  const _SessionsList({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _SessionsListHeader(viewModel: viewModel),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: viewModel.sessions.length,
            itemBuilder: (context, index) {
              final session = viewModel.sessions[index];
              final isSelected =
                  viewModel.selectedSession?.sessionKey == session.sessionKey;

              return AuditSessionCard(
                session: session,
                isSelected: isSelected,
                onTap: () => viewModel.selectSession(session),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================
// Sessions List Header
// =============================
class _SessionsListHeader extends StatelessWidget {
  final AuditViewModel viewModel;

  const _SessionsListHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F5F7),
        border: Border(bottom: BorderSide(color: Color(0xFFDFE1E6))),
      ),
      child: Row(
        children: [
          const Icon(Icons.list_alt, size: 18, color: Color(0xFF42526E)),
          const SizedBox(width: 8),
          Text(
            '${viewModel.sessions.length} ${viewModel.sessions.length == 1 ? 'Session' : 'Sessions'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
              letterSpacing: -0.1,
            ),
          ),
          const Spacer(),
          _ModuleBadge(viewModel: viewModel),
        ],
      ),
    );
  }
}

// =============================
// Module Badge
// =============================
class _ModuleBadge extends StatelessWidget {
  final AuditViewModel viewModel;

  const _ModuleBadge({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDEEBFF),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Module display name
          Text(
            viewModel.currentModuleDisplayNameWithFallback,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0747A6),
              letterSpacing: 0.3,
            ),
          ),

          // Document number
          const SizedBox(width: 6),
          Text(
            viewModel.currentDocumentNo ?? '',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0747A6),
            ),
          ),
        ],
      ),
    );
  }
}
