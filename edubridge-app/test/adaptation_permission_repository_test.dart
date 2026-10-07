import 'package:edubridge_app/features/adaptation/data/adaptation_permission_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('only an explicit server grant enables editing for the requested child', () async {
    final repository = AdaptationPermissionRepository(get: (path) async {
      expect(path, '/children/42/accessibility-profile');
      return http.Response('{"can_edit":true}', 200);
    });
    expect(await repository.canEdit(42), true);
  });

  for (final body in ['{}', '{"can_edit":false}', '{"can_edit":"true"}',
      '{"can_edit":1}', 'invalid']) {
    test('does not grant editing for $body', () async {
      final repository = AdaptationPermissionRepository(
        get: (_) async => http.Response(body, 200));
      expect(await repository.canEdit(42), false);
    });
  }

  test('403 cannot grant editing even when the body says true', () async {
    final repository = AdaptationPermissionRepository(
      get: (_) async => http.Response('{"can_edit":true}', 403));
    expect(await repository.canEdit(42), false);
  });

  test('offline requests leave editing disabled', () async {
    final repository = AdaptationPermissionRepository(
      get: (_) async => throw http.ClientException('offline'));
    expect(await repository.canEdit(42), false);
  });
}
