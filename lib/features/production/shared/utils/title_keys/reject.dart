// features/production/shared/utils/title_keys/reject.dart
import '../../../broker/model/broker_inputs_model.dart';

String rejectTitleKey(RejectItem e) {
  if (e.isPartialRow) {
    final np = (e.noRejectPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final nr = (e.noReject ?? '').trim();
  return nr.isEmpty ? '-' : nr;
}
