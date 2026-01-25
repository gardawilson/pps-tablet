// lib/features/audit/screens/audit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/audit_view_model.dart';
import '../widgets/audit_detail_panel.dart';
import '../widgets/audit_session_card.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({Key? key}) : super(key: key);

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  late AuditViewModel _viewModel;
  final _documentNoController = TextEditingController();
  String? _selectedModule;

  @override
  void initState() {
    super.initState();
    _viewModel = AuditViewModel();
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
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.history, size: 28),
              SizedBox(width: 12),
              Text(
                'Audit History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            // Refresh button
            Consumer<AuditViewModel>(
              builder: (context, vm, _) {
                if (vm.currentModule == null || vm.currentDocumentNo == null) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: vm.isLoading
                      ? null
                      : () {
                    _search();
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search form
            _buildSearchBar(),

            const Divider(height: 1),

            // Main content
            Expanded(
              child: Consumer<AuditViewModel>(
                builder: (context, vm, _) {
                  return Row(
                    children: [
                      // Sessions list (40%)
                      Expanded(
                        flex: 4,
                        child: _buildSessionsList(vm),
                      ),

                      Container(
                        width: 1,
                        color: Colors.grey[300],
                      ),

                      // Detail panel (60%)
                      const Expanded(
                        flex: 6,
                        child: AuditDetailPanel(),
                      ),
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
      color: Colors.grey[50],
      child: Row(
        children: [
          // Module dropdown
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _selectedModule,
              decoration: const InputDecoration(
                labelText: 'Module',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _viewModel.availableModules.map((config) {
                return DropdownMenuItem(
                  value: config.module,
                  child: Text(config.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedModule = value);
              },
            ),
          ),

          const SizedBox(width: 16),

          // Document number field
          Expanded(
            child: TextField(
              controller: _documentNoController,
              decoration: InputDecoration(
                labelText: 'Document Number',
                hintText: 'Enter document number (e.g. B.0000013193)',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: _documentNoController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _documentNoController.clear();
                    setState(() {});
                  },
                )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),

          const SizedBox(width: 16),

          // Search button
          Consumer<AuditViewModel>(
            builder: (context, vm, _) {
              return ElevatedButton.icon(
                onPressed: vm.isLoading ? null : _search,
                icon: vm.isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _search() {
    final module = _selectedModule;
    final documentNo = _documentNoController.text.trim();

    if (module == null || module.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a module'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (documentNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter document number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Fetch history
    _viewModel.fetchHistory(
      module: module,
      documentNo: documentNo,
    );
  }

  Widget _buildSessionsList(AuditViewModel vm) {
    // Loading state
    if (vm.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading audit history...'),
          ],
        ),
      );
    }

    // Error state
    if (vm.errorMessage.isNotEmpty && vm.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state (no search yet or no results)
    if (vm.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              vm.currentModule == null
                  ? 'Search Audit History'
                  : 'No audit sessions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.currentModule == null
                  ? 'Select module and enter document number'
                  : 'Try another document number',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Success state - show list
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 20),
              const SizedBox(width: 8),
              Text(
                'Audit Sessions (${vm.sessions.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${vm.currentModule?.toUpperCase() ?? ''}: ${vm.currentDocumentNo ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vm.sessions.length,
            itemBuilder: (context, index) {
              final session = vm.sessions[index];
              final isSelected =
                  vm.selectedSession?.sessionKey == session.sessionKey;

              return AuditSessionCard(
                session: session,
                isSelected: isSelected,
                onTap: () => vm.selectSession(session),
              );
            },
          ),
        ),
      ],
    );
  }
}