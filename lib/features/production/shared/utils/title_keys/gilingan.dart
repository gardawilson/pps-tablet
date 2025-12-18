// features/production/shared/utils/title_keys/reject_repository.dart

import '../../models/gilingan_item.dart';

String gilinganTitleKey(GilinganItem e) {
  if (e.isPartialRow) {
    final np = (e.noGilinganPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final ng = (e.noGilingan ?? '').trim();
  return ng.isEmpty ? '-' : ng;
}
