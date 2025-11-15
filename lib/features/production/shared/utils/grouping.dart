Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) keyOf) {
  final map = <K, List<T>>{};
  for (final item in items) {
    final k = keyOf(item);
    map.putIfAbsent(k, () => <T>[]).add(item);
  }
  return map;
}