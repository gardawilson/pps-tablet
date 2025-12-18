// features/production/shared/utils/title_keys/reject.dart

import '../../models/reject_item.dart';

String rejectTitleKey(RejectItem e) {
  if (e.isPartialRow) {
    final np = (e.noRejectPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final nr = (e.noReject ?? '').trim();
  return nr.isEmpty ? '-' : nr;
}
