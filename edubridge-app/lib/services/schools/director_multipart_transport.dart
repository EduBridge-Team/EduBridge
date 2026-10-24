import 'package:http/http.dart' as http;

import '../../config.dart';
import '../api_service.dart';

typedef DirectorMultipartSend = Future<http.StreamedResponse> Function(
  http.BaseRequest request,
);

/// Private uploads retain the operator session; a late 401 cannot log out a newer session.
class DirectorMultipartTransport {
  DirectorMultipartTransport({
    Future<String?> Function()? token,
    Future<void> Function()? logout,
    DirectorMultipartSend? send,
  }) : _token = token ?? ApiService.getToken,
       _logout = logout ?? ApiService.logout,
       _send = send ?? ((request) => request.send());
  final Future<String?> Function() _token;
  final Future<void> Function() _logout;
  final DirectorMultipartSend _send;

  Future<http.Response> upload(
    String path,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    final token = await _token();
    if (token == null || token.isEmpty) return http.Response('', 401);
    final request =
        http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}$path'))
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['Accept'] = 'application/json'
          ..fields.addAll(fields)
          ..files.addAll(files);
    final response = await http.Response.fromStream(await _send(request));
    if (response.statusCode == 401 && await _token() == token) await _logout();
    return response;
  }
}
