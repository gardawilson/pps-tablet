// lib/features/audit/view_model/audit_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/audit_session_model.dart';
import '../model/audit_config.dart';
import '../repository/audit_repository.dart';

class AuditViewModel extends ChangeNotifier {
  final AuditRepository _repository = AuditRepository();

  // =============================
  // State
  // =============================
  List<AuditSession> sessions = [];
  bool isLoading = false;
  String errorMessage = '';

  String? currentModule;
  String? currentDocumentNo;
  AuditModuleConfig? currentConfig;

  // Selected session for detail view
  AuditSession? selectedSession;

  // =============================
  // Available modules
  // =============================
  List<AuditModuleConfig> get availableModules => [
    AuditModuleConfig.washing,
    AuditModuleConfig.broker,
    AuditModuleConfig.crusher,
    AuditModuleConfig.bonggolan,
    AuditModuleConfig.gilingan,
    AuditModuleConfig.mixer,
    AuditModuleConfig.furniturewip,
    AuditModuleConfig.barangjadi,
    // Add more as needed
  ];

  // =============================
  // Fetch history for specific document
  // =============================
  Future<bool> fetchHistory({
    required String module,
    required String documentNo,
  }) async {
    try {
      isLoading = true;
      errorMessage = '';
      currentModule = module;
      currentDocumentNo = documentNo;
      currentConfig = AuditModuleConfig.forModule(module);
      selectedSession = null;
      notifyListeners();

      sessions = await _repository.fetchHistory(
        module: module,
        documentNo: documentNo,
        config: currentConfig,
      );

      debugPrint(
        '✅ [AuditVM] Fetched ${sessions.length} sessions for $module: $documentNo',
      );
      return true;
    } catch (e, st) {
      errorMessage = e.toString();
      sessions = [];
      debugPrint('❌ [AuditVM] fetchHistory error: $e');
      debugPrint('$st');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Select session for detail view
  // =============================
  void selectSession(AuditSession? session) {
    selectedSession = session;
    notifyListeners();
  }

  // =============================
  // Clear state
  // =============================
  void clear() {
    sessions = [];
    errorMessage = '';
    currentModule = null;
    currentDocumentNo = null;
    currentConfig = null;
    selectedSession = null;
    notifyListeners();
  }
}