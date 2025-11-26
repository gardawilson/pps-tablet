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
  final pallet = i.noPallet;
  final hasNb = nb.isNotEmpty;
  final hasPallet = pallet != null && pallet > 0;

  if (!hasNb && !hasPallet) return '-';
  if (hasNb && hasPallet) return '$nb-$pallet'; // A.0000000001-1
  if (hasNb) return nb;                         // A.0000000001
  return 'Pallet $pallet';                      // Pallet 1
}
