import 'package:flutter/foundation.dart';

import '../repository/overlap_repository.dart';

class OverlapViewModel extends ChangeNotifier {
  final OverlapRepository _repo;

  OverlapViewModel({OverlapRepository? repository}) : _repo = repository ?? OverlapRepository();

  bool _isChecking = false;
  String? _errorMessage;
  List<OverlapConflict> _conflicts = const [];

  bool get isChecking => _isChecking;
  String? get errorMessage => _errorMessage;
  List<OverlapConflict> get conflicts => _conflicts;

  bool get hasOverlap => _conflicts.isNotEmpty;
  String? get overlapMessage =>
      hasOverlap ? 'Rentang jam ini telah di gunakan' : null;

  Future<void> check({
    required String kind,          // 'broker' | 'crusher' | 'washing' | 'gilingan'
    required DateTime date,
    required int idMesin,
    required String hourStart,     // "HH:mm"
    required String hourEnd,       // "HH:mm"
    String? excludeNo,
  }) async {
    // Basic guard
    if (hourStart.isEmpty || hourEnd.isEmpty) {
      _conflicts = const [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isChecking = true;
    _errorMessage = null;
    _conflicts = const [];
    notifyListeners();

    try {
      final res = await _repo.check(
        kind: kind,
        date: date,
        idMesin: idMesin,
        hourStart: hourStart,
        hourEnd: hourEnd,
        excludeNo: excludeNo,
      );
      _isChecking = false;
      _conflicts = res.conflicts;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isChecking = false;
      _conflicts = const [];
      _errorMessage = 'Gagal cek overlap: $e';
      notifyListeners();
    }
  }

  void clear() {
    _isChecking = false;
    _errorMessage = null;
    _conflicts = const [];
    notifyListeners();
  }
}
