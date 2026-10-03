import 'dart:async';
import 'package:flutter/foundation.dart';
import 'list_page.dart';

typedef PageFetcher = Future<ListPage> Function(int page, String query);

class PagedListController extends ChangeNotifier {
  PagedListController(this.fetchPage);
  final PageFetcher fetchPage;
  List<dynamic> items = [];
  int page = 1;
  int total = 0;
  int lastPage = 1;
  String query = '';
  bool loading = true;
  String? error;
  int _revision = 0;
  bool _disposed = false;
  Timer? _debounce;

  Future<void> load([int requestedPage = 1]) =>
      _loadInternal(requestedPage, showLoading: true);

  Future<void> refresh([int requestedPage = 1]) =>
      _loadInternal(requestedPage, showLoading: false);

  Future<void> _loadInternal(
    int requestedPage, {
    required bool showLoading,
  }) async {
    if (_disposed) return;
    _debounce?.cancel();
    final revision = ++_revision;
    if (showLoading) loading = true;
    error = null;
    if (showLoading) notifyListeners();
    try {
      final result = await fetchPage(requestedPage, query);
      if (_disposed || revision != _revision) return;
      if (result.page != requestedPage) {
        throw const FormatException('Unexpected page');
      }
      items = result.items;
      page = result.page;
      total = result.total;
      lastPage = result.lastPage;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      error = 'تعذّر تحميل القائمة، حاول مجدداً';
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void search(String value) {
    if (_disposed) return;
    query = value;
    ++_revision; // Invalidate old responses before the debounce starts.
    _debounce?.cancel();
    loading = true;
    error = null;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 300), () => load());
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _debounce?.cancel();
    super.dispose();
  }
}
