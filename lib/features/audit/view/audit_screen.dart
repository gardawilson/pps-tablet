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
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0052CC),
          elevation: 0,
          title: Row(
            children: const [
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
                if (vm.currentModule == null || vm.currentDocumentNo == null) {
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
                      Container(
                        width: 1,
                        color: const Color(0xFFDFE1E6),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFDFE1E6)),
        ),
      ),
      child: Row(
        children: [
          // Module dropdown
          SizedBox(
            width: 220,
            child: _AtlassianDropdown(
              value: _selectedModule,
              label: 'Module',
              hint: 'Select module',
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

          const SizedBox(width: 12),

          // Document number field
          Expanded(
            child: _AtlassianTextField(
              controller: _documentNoController,
              label: 'Document Number',
              hint: 'e.g., B.0000013193',
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),

          const SizedBox(width: 12),

          // Search button
          Consumer<AuditViewModel>(
            builder: (context, vm, _) {
              return _AtlassianButton(
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
    final module = _selectedModule;
    final documentNo = _documentNoController.text.trim();

    if (module == null || module.isEmpty) {
      _showSnackbar('Please select a module', isError: true);
      return;
    }

    if (documentNo.isEmpty) {
      _showSnackbar('Please enter document number', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    _viewModel.fetchHistory(
      module: module,
      documentNo: documentNo,
    );
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
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDE350B) : const Color(0xFF0052CC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSessionsList(AuditViewModel vm) {
    // Loading state
    if (vm.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0052CC)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading audit history...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF42526E),
                fontWeight: FontWeight.w500,
              ),
            ),
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Color(0xFFDE350B),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                vm.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B778C),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _AtlassianButton(
                onPressed: _search,
                label: 'Try Again',
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (vm.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.search,
                size: 50,
                color: Color(0xFFA5ADBA),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              vm.currentModule == null
                  ? 'Search Audit History'
                  : 'No Results Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              vm.currentModule == null
                  ? 'Select a module and enter a document number to begin'
                  : 'No audit sessions found for this document',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B778C),
                height: 1.5,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F5F7),
            border: Border(
              bottom: BorderSide(color: Color(0xFFDFE1E6)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.list_alt,
                size: 18,
                color: Color(0xFF42526E),
              ),
              const SizedBox(width: 8),
              Text(
                '${vm.sessions.length} ${vm.sessions.length == 1 ? 'Session' : 'Sessions'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172B4D),
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEBFF),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.currentModule?.toUpperCase() ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0747A6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0052CC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vm.currentDocumentNo ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0747A6),
                      ),
                    ),
                  ],
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

// =============================
// Atlassian TextField
// =============================
class _AtlassianTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _AtlassianTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF172B4D),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B778C),
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFA5ADBA),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: const Icon(
            Icons.clear,
            size: 18,
            color: Color(0xFF6B778C),
          ),
          onPressed: () {
            controller.clear();
            if (onChanged != null) onChanged!('');
          },
        )
            : null,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

// =============================
// Atlassian Dropdown
// =============================
class _AtlassianDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _AtlassianDropdown({
    required this.value,
    required this.label,
    required this.hint,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF172B4D),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B778C),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
        ),
      ),
      hint: Text(
        hint,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFA5ADBA),
        ),
      ),
      items: items,
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFF6B778C),
      ),
    );
  }
}

// =============================
// Atlassian Button
// =============================
class _AtlassianButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;

  const _AtlassianButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        disabledBackgroundColor: const Color(0xFFA5ADBA),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          else
            Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}