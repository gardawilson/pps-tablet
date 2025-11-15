import '../../../broker/model/broker_inputs_model.dart'; // atau arahkan ke model yang benar jika shared model terpisah


String bbTitleKey(BbItem e) {
  if (e.isPartialRow) {
    final npart = (e.noBBPartial ?? '').trim();
    return npart.isEmpty ? '-' : npart;
  }
  final nb = (e.noBahanBaku ?? '').trim();
  final np = e.noPallet; // int?
  final hasNb = nb.isNotEmpty;
  final hasNp = (np != null && np > 0);
  if (!hasNb && !hasNp) return '-';
  if (hasNb && hasNp) return '$nb-$np';
  if (hasNb) return nb;
  return 'Pallet $np';
}


String bbPairLabel(BbItem i) {
  final nb = (i.noBahanBaku ?? '').trim();
  final partRaw = (i.noSak.toString()).trim();
  if (i.isPartialRow) {
    if (nb.isEmpty && partRaw.isEmpty) return '-';
    if (nb.isNotEmpty && partRaw.startsWith('$nb-')) return partRaw;
    final idx = partRaw.lastIndexOf('-');
    final suffix = idx == -1 ? partRaw : partRaw.substring(idx + 1);
    if (nb.isEmpty) return partRaw.isEmpty ? '-' : partRaw;
    return suffix.isEmpty ? nb : '$nb-$suffix';
  }
  final pallet = i.noPallet;
  if (nb.isEmpty && pallet == null) return '-';
  return (pallet == null) ? nb : '$nb-$pallet';
}