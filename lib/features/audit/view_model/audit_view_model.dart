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

  String? currentModule; // ← module key (e.g., "bongkar_susun")
  String? currentPrefix; // ← prefix (e.g., "BG")
  String? currentDocumentNo; // ← document number (e.g., "BG.0000002220")
  AuditModuleConfig? currentConfig; // ← config object

  // Selected session for detail view
  AuditSession? selectedSession;

  // =============================
  // 🎯 NEW: Getter untuk Display Name
  // =============================
  /// Get display name dari currentConfig (e.g., "Bongkar Susun")
  /// Returns null jika config tidak tersedia
  String? get currentModuleDisplayName => currentConfig?.displayName;

  /// Get display name dengan fallback ke module key uppercase
  /// Returns uppercase module key jika config tidak ada
  String get currentModuleDisplayNameWithFallback {
    return currentConfig?.displayName ??
        currentModule?.toUpperCase().replaceAll('_', ' ') ??
        '';
  }

  // =============================
  // 🎯 Fetch history dengan AUTO-DETECTION
  // =============================
  Future<bool> fetchHistory({required String documentNo}) async {
    try {
      isLoading = true;
      errorMessage = '';
      selectedSession = null;
      sessions = [];
      notifyListeners();

      // Call API - module akan auto-detect dari prefix
      final result = await _repository.fetchHistory(documentNo: documentNo);

      // Extract detected module info
      final detectedModule = result['module']?.toString() ?? '';
      final prefix = result['prefix']?.toString();
      final docNo = result['documentNo']?.toString() ?? documentNo;
      final sessionsRaw = result['sessions'] as List<dynamic>? ?? [];

      // Update current state
      currentModule = detectedModule;
      currentPrefix = prefix;
      currentDocumentNo = docNo;
      currentConfig = AuditModuleConfig.forModule(detectedModule);

      // Parse sessions
      sessions = sessionsRaw.map((e) {
        return AuditSession.fromJson(
          e as Map<String, dynamic>,
          fieldConfigs: currentConfig?.fields,
        );
      }).toList();

      debugPrint(
        '✅ [AuditVM] Auto-detected module: $detectedModule (prefix: $prefix)',
      );
      debugPrint(
        '✅ [AuditVM] Display name: ${currentConfig?.displayName ?? "N/A"}',
      );
      debugPrint('✅ [AuditVM] Fetched ${sessions.length} sessions for: $docNo');

      return true;
    } catch (e, st) {
      errorMessage = e.toString();
      sessions = [];
      currentModule = null;
      currentPrefix = null;
      currentDocumentNo = null;
      currentConfig = null;
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
    currentPrefix = null;
    currentDocumentNo = null;
    currentConfig = null;
    selectedSession = null;
    notifyListeners();
  }
}
