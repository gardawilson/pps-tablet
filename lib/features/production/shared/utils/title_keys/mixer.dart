// features/production/shared/utils/title_keys/mixer.dart
import '../../../broker/model/broker_inputs_model.dart';

String mixerTitleKey(MixerItem e) {
  // Untuk partial, gunakan noMixerPartial sebagai key
  if (e.isPartialRow) {
    final np = (e.noMixerPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }

  // Untuk full item, gunakan noMixer saja (TANPA noSak)
  // Detail sak akan ditampilkan di dalam detailsBuilder
  final nm = (e.noMixer ?? '').trim();
  return nm.isEmpty ? '-' : nm;
}