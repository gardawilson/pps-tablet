// lib/features/production/shared/utils/title_keys/barang_jadi_title_key.dart

import '../../models/barang_jadi_item.dart';

String barangJadiTitleKey(BarangJadiItem e) {
  if (e.isPartialRow) {
    final np = (e.noBJPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final nbj = (e.noBJ ?? '').trim();
  return nbj.isEmpty ? '-' : nbj;
}