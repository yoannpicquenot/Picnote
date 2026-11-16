/// Open / total task counts of a list.
class ListStats {
  const ListStats({required this.total, required this.open});

  final int total;
  final int open;

  int get done => total - open;
}
