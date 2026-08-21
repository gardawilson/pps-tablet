import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../model/retur_v3_header.dart';
import '../model/retur_v3_item.dart';
import '../model/retur_v3_output.dart';
import '../model/retur_v3_turnover.dart';
import '../repository/retur_v3_repository.dart';

class ReturV3DetailViewModel extends ChangeNotifier {
  final String noRetur;
  final ReturV3Repository repository;

  ReturV3DetailViewModel({required this.noRetur, ReturV3Repository? repository})
    : repository = repository ?? ReturV3Repository();

  bool isLoading = false;
  String? error;

  ReturV3Header? header;
  List<ReturV3Item> items = [];
  List<ReturV3Turnover> turnover = [];
  List<ReturV3Output> outputs = [];

  // Per-action busy/error state so the UI can show inline spinners without
  // blocking the whole screen.
  bool isSavingItem = false;
  String? itemError;

  bool isDeciding = false;
  String? decisionError;

  final Set<int> generatingItemIds = {};
  String? generateError;

  bool isCompleting = false;
  String? completeError;

  // ── Derived ──────────────────────────────────────────────────────────

  ReturV3Turnover? turnoverFor(int idItem) {
    for (final t in turnover) {
      if (t.idItem == idItem) return t;
    }
    return null;
  }

  /// Langkah 1 (Generate Label) dianggap selesai bukan cuma kalau semua
  /// item sudah punya label yang digenerate, tapi label-labelnya juga
  /// sudah dicetak minimal 1x (`HasBeenPrinted > 0`) — generate saja belum
  /// cukup untuk lanjut ke langkah 2 (Progress Turnover).
  bool get step1Complete =>
      items.isNotEmpty &&
      items.every((it) => it.hasGeneratedLabel) &&
      outputs.isNotEmpty &&
      outputs.every((o) => o.hasBeenPrinted);

  /// Setiap item retur harus punya minimal 1 target pengganti sebelum scan
  /// bisa dimulai — target bukan lagi otomatis diturunkan dari item itu
  /// sendiri (barang pengganti bisa beda kategori/jenis dari yang kembali).
  bool get allTargetsDefined {
    if (items.isEmpty) return false;
    for (final item in items) {
      final t = turnoverFor(item.idItem);
      if (t == null || !t.hasTargets) return false;
    }
    return true;
  }

  bool get allItemsFulfilled {
    if (items.isEmpty) return false;
    for (final item in items) {
      final t = turnoverFor(item.idItem);
      if (t == null || !t.isFulfilled) return false;
    }
    return true;
  }

  bool get canComplete =>
      header != null &&
      header!.isDiganti &&
      !header!.isComplete &&
      allItemsFulfilled;

  // ── Load ─────────────────────────────────────────────────────────────

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await repository.fetchDetail(noRetur);
      header = res['header'] as ReturV3Header;
      items = res['items'] as List<ReturV3Item>;
      turnover = res['turnover'] as List<ReturV3Turnover>;
      outputs = res['outputs'] as List<ReturV3Output>;

      // Kalau detail belum menyertakan turnover/outputs (opsional di
      // kontrak), ambil terpisah sesuai status. Outputs (label yang sudah
      // digenerate) relevan untuk DIGANTI juga sekarang (langkah 1 alur
      // DIGANTI = generate label, sama seperti TIDAK_DIGANTI) — bukan cuma
      // TIDAK_DIGANTI seperti sebelum ada alur 2-langkah.
      if (header != null) {
        if (header!.isDiganti && turnover.isEmpty) {
          await _loadTurnover();
        }
        if (!header!.isPending && outputs.isEmpty) {
          await _loadOutputs();
        }
      }
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTurnover() async {
    try {
      turnover = await repository.fetchTurnover(noRetur);
    } catch (_) {
      // biarkan silent — halaman detail tetap tampil dengan progress kosong
    }
  }

  Future<void> _loadOutputs() async {
    try {
      outputs = await repository.fetchOutputs(noRetur);
    } catch (_) {
      // biarkan silent
    }
  }

  Future<void> refreshOutputs() async {
    await _loadOutputs();
    notifyListeners();
  }

  Future<void> refreshTurnover() async {
    await _loadTurnover();
    notifyListeners();
  }

  // ── Items (PENDING) ─────────────────────────────────────────────────

  Future<bool> addItem({
    required String kodeKategori,
    required int idJenis,
    required int pcs,
    required String kategoriInput,
  }) async {
    isSavingItem = true;
    itemError = null;
    notifyListeners();
    try {
      final newItems = await repository.addItems(noRetur, [
        {
          'kodeKategori': kodeKategori,
          'idJenis': idJenis,
          'pcs': pcs,
          'kategoriInput': kategoriInput,
        },
      ]);
      items = [...items, ...newItems];
      return true;
    } catch (e) {
      itemError = apiErrorMessage(e);
      return false;
    } finally {
      isSavingItem = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(
    int idItem, {
    String? kodeKategori,
    int? idJenis,
    int? pcs,
    String? kategoriInput,
  }) async {
    isSavingItem = true;
    itemError = null;
    notifyListeners();
    try {
      final updated = await repository.updateItem(
        noRetur,
        idItem,
        kodeKategori: kodeKategori,
        idJenis: idJenis,
        pcs: pcs,
        kategoriInput: kategoriInput,
      );
      items = items
          .map((it) => it.idItem == idItem ? updated : it)
          .toList();
      return true;
    } catch (e) {
      itemError = apiErrorMessage(e);
      return false;
    } finally {
      isSavingItem = false;
      notifyListeners();
    }
  }

  Future<bool> removeItem(int idItem) async {
    itemError = null;
    try {
      await repository.deleteItem(noRetur, idItem);
      items = items.where((it) => it.idItem != idItem).toList();
      notifyListeners();
      return true;
    } catch (e) {
      itemError = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Decision ─────────────────────────────────────────────────────────

  Future<bool> decide(String decision) async {
    isDeciding = true;
    decisionError = null;
    notifyListeners();
    try {
      header = await repository.decide(noRetur, decision);
      if (header!.isDiganti) {
        await _loadTurnover();
        await _loadOutputs();
      } else if (header!.isTidakDiganti) {
        await _loadOutputs();
      }
      return true;
    } catch (e) {
      decisionError = apiErrorMessage(e);
      return false;
    } finally {
      isDeciding = false;
      notifyListeners();
    }
  }

  // ── Generate label (TIDAK_DIGANTI) ──────────────────────────────────

  Future<bool> generateLabelForItem(
    int idItem, {
    double? berat,
    int? idReject,
  }) async {
    generatingItemIds.add(idItem);
    generateError = null;
    notifyListeners();
    try {
      final data = await repository.generateLabel(
        noRetur,
        idItem,
        berat: berat,
        idReject: idReject,
      );
      final labelCode = (data['labelCode'] ?? data['LabelCode'])?.toString();
      if (labelCode != null && labelCode.isNotEmpty) {
        items = items
            .map(
              (it) => it.idItem == idItem
                  ? ReturV3Item(
                      idItem: it.idItem,
                      kodeKategori: it.kodeKategori,
                      idJenis: it.idJenis,
                      namaJenis: it.namaJenis,
                      pcs: it.pcs,
                      kategoriInput: it.kategoriInput,
                      berat: berat ?? it.berat,
                      idReject: idReject ?? it.idReject,
                      generatedLabelCode: labelCode,
                    )
                  : it,
            )
            .toList();
      }
      await _loadOutputs();
      return true;
    } catch (e) {
      generateError = apiErrorMessage(e);
      return false;
    } finally {
      generatingItemIds.remove(idItem);
      notifyListeners();
    }
  }

  // ── Turnover targets (DIGANTI) ──────────────────────────────────────

  bool isSavingTarget = false;
  String? targetError;

  Future<bool> addTurnoverTarget(
    int idItem, {
    required String kodeKategori,
    required int idJenis,
    required int pcs,
  }) async {
    isSavingTarget = true;
    targetError = null;
    notifyListeners();
    try {
      await repository.addTurnoverTargets(noRetur, idItem, [
        {'kodeKategori': kodeKategori, 'idJenis': idJenis, 'pcs': pcs},
      ]);
      await _loadTurnover();
      return true;
    } catch (e) {
      targetError = apiErrorMessage(e);
      return false;
    } finally {
      isSavingTarget = false;
      notifyListeners();
    }
  }

  Future<bool> removeTurnoverTarget(int idTarget) async {
    targetError = null;
    try {
      await repository.deleteTurnoverTarget(noRetur, idTarget);
      await _loadTurnover();
      notifyListeners();
      return true;
    } catch (e) {
      targetError = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Scan / turnover (DIGANTI) ───────────────────────────────────────

  /// Scan auto-detect — satu tombol scan untuk semua target: backend yang
  /// menentukan target mana yang cocok berdasarkan kategori+jenis label.
  /// `null` = sukses, String = pesan error untuk ditampilkan inline.
  Future<String?> scanAuto(String labelCode) async {
    try {
      await repository.scanAuto(noRetur, labelCode);
      await _loadTurnover();
      notifyListeners();
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    }
  }

  Future<bool> undoScan(int idTurnover) async {
    try {
      await repository.undoScan(noRetur, idTurnover);
      await _loadTurnover();
      notifyListeners();
      return true;
    } catch (e) {
      decisionError = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Selesaikan retur (mark complete) ────────────────────────────────

  Future<bool> markComplete() async {
    isCompleting = true;
    completeError = null;
    notifyListeners();
    try {
      header = await repository.markComplete(noRetur);
      return true;
    } catch (e) {
      completeError = apiErrorMessage(e);
      return false;
    } finally {
      isCompleting = false;
      notifyListeners();
    }
  }
}
