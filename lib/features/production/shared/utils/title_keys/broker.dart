// features/production/shared/utils/title_keys/broker.dart
import '../../../broker/model/broker_inputs_model.dart';

String brokerTitleKey(BrokerItem e) {
  // Untuk partial, gunakan noBrokerPartial sebagai key
  if (e.isPartialRow) {
    final np = (e.noBrokerPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }

  // Untuk full item, gunakan noBroker saja (TANPA noSak)
  // Detail sak akan ditampilkan di dalam detailsBuilder
  final nb = (e.noBroker ?? '').trim();
  return nb.isEmpty ? '-' : nb;
}