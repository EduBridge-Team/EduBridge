import 'package:flutter/foundation.dart';

/// Owns loading state; only the latest request may publish its result.
class CommunicationListController extends ChangeNotifier {
  CommunicationListController({required Future<List<dynamic>> Function() load,
    required this.errorMessage}) : _load = load;

  final Future<List<dynamic>> Function() _load;
  final String errorMessage;
  List<dynamic> items = [];
  bool loading = true;
  String? error;
  int _generation = 0;
  bool _disposed = false;

  Future<bool> reload({bool showLoader = true}) async {
    if (_disposed) return false;
    final generation = ++_generation;
    if (showLoader) loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _load();
      if (_disposed || generation != _generation) return false;
      items = result;
      loading = false;
      notifyListeners();
      return true;
    } catch (_) {
      if (_disposed || generation != _generation) return false;
      error = errorMessage;
      loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
