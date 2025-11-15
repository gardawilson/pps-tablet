// features/production/shared/utils/title_keys/gilingan.dart
import '../../../broker/model/broker_inputs_model.dart';

String gilinganTitleKey(GilinganItem e) {
  if (e.isPartialRow) {
    final np = (e.noGilinganPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final ng = (e.noGilingan ?? '').trim();
  return ng.isEmpty ? '-' : ng;
}
