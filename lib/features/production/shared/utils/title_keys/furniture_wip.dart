// lib/features/production/shared/utils/title_keys/furniture_wip_title_key.dart

import '../../models/furniture_wip_item.dart';

String furnitureWipTitleKey(FurnitureWipItem e) {
  if (e.isPartialRow) {
    final np = (e.noFurnitureWIPPartial ?? '').trim();
    return np.isEmpty ? '-' : np;
  }
  final nfw = (e.noFurnitureWIP ?? '').trim();
  return nfw.isEmpty ? '-' : nfw;
}