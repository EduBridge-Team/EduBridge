import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';

/// The server remains the authority for assigned-specialist edit permissions.
class AdaptationPermissionRepository {
  AdaptationPermissionRepository({Future<http.Response> Function(String)? get})
      : _get = get ?? ApiService.authGet;

  final Future<http.Response> Function(String) _get;

  Future<bool> canEdit(int childId) async {
    try {
      final response = await _get('/children/$childId/accessibility-profile');
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['can_edit'] == true;
    } catch (_) {
      return false;
    }
  }
}
