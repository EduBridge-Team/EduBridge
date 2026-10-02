class ListPage {
  const ListPage({required this.items, required this.page, required this.total, required this.lastPage});
  final List<dynamic> items;
  final int page;
  final int total;
  final int lastPage;

  factory ListPage.fromJson(Map<String, dynamic> data, String key) {
    final rows = data[key];
    final meta = data['pagination'];
    if (rows is! List || meta is! Map || meta['page'] is! int || meta['total'] is! int ||
        meta['last_page'] is! int || (meta['page'] as int) < 1 ||
        (meta['last_page'] as int) < 1 || (meta['total'] as int) < 0 ||
        rows.any((row) => row is! Map || row['id'] is! int)) {
      throw const FormatException('Invalid list page');
    }
    return ListPage(items: rows, page: meta['page'] as int, total: meta['total'] as int, lastPage: meta['last_page'] as int);
  }
}
