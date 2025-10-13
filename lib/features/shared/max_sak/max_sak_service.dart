import 'dart:collection';
import 'max_sak_repository.dart';
import 'max_sak_model.dart';

class MaxSakService {
  final MaxSakRepository repository;
  MaxSakService(this.repository);

  final _cache = HashMap<int, MaxSakDefaults>();
  Future<MaxSakDefaults> get(int idBagian, {bool force = false}) async {
    if (!force && _cache.containsKey(idBagian)) return _cache[idBagian]!;
    final v = await repository.fetch(idBagian);
    _cache[idBagian] = v;
    return v;
  }
}
