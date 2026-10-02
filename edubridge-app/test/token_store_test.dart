import 'dart:async';

import 'package:edubridge_app/services/api_service.dart';
import 'package:edubridge_app/services/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const key = 'edubridge.auth.token';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('migrates and verifies legacy token before deleting plaintext', () async {
    SharedPreferences.setMockInitialValues({'token': 'legacy'});
    final store = TokenStore();
    expect(await store.get(), 'legacy');
    expect(await storage.read(key: key), 'legacy');
    expect((await SharedPreferences.getInstance()).containsKey('token'), false);
    expect(await TokenStore().get(), 'legacy');
  });

  test('secure copy takes precedence over stale plaintext', () async {
    SharedPreferences.setMockInitialValues({'token': 'stale'});
    FlutterSecureStorage.setMockInitialValues({key: 'current'});
    expect(await TokenStore().get(), 'current');
    expect((await SharedPreferences.getInstance()).containsKey('token'), false);
  });

  test('failed migration preserves its source and retries after restart', () async {
    SharedPreferences.setMockInitialValues({'token': 'legacy'});
    final failing = TokenStore(write: (_) async => throw StateError('locked'));
    expect(await failing.get(), null);
    expect((await SharedPreferences.getInstance()).getString('token'), 'legacy');
    expect(await TokenStore().get(), 'legacy');
  });

  test('unverified migration is retried instead of using a bad secure copy', () async {
    SharedPreferences.setMockInitialValues({'token': 'legacy'});
    final failing = TokenStore(
      write: (_) async => storage.write(key: key, value: 'bad-copy'),
    );
    expect(await failing.get(), null);
    expect((await SharedPreferences.getInstance()).getString('token'), 'legacy');
    expect(await TokenStore().get(), 'legacy');
    expect(await storage.read(key: key), 'legacy');
  });

  test('secure read failure never falls back to plaintext', () async {
    SharedPreferences.setMockInitialValues({'token': 'legacy'});
    expect(await TokenStore(read: () async => throw StateError('locked')).get(), null);
    expect((await SharedPreferences.getInstance()).getString('token'), 'legacy');
  });

  test('logout blocks failed deletion across restarts and permits new login', () async {
    SharedPreferences.setMockInitialValues({'token': 'old-plaintext'});
    FlutterSecureStorage.setMockInitialValues({key: 'old-secure'});
    final failing = TokenStore(delete: () async => throw StateError('locked'));
    await failing.clear();
    expect(await failing.get(), null);
    expect((await SharedPreferences.getInstance()).containsKey('token'), false);
    final restarted = TokenStore();
    expect(await restarted.get(), null);
    expect(await storage.read(key: key), null);
    await restarted.save('new-session');
    expect(await TokenStore().get(), 'new-session');
    expect((await SharedPreferences.getInstance()).containsKey('token'), false);
  });

  test('failed token replacement stays signed out and can be retried', () async {
    FlutterSecureStorage.setMockInitialValues({key: 'old-session'});
    final failing = TokenStore(write: (_) async => throw StateError('locked'));
    await expectLater(failing.save('new-session'), throwsA(isA<TokenStorageException>()));
    expect(await TokenStore().get(), null);
    await TokenStore().save('new-session');
    expect(await TokenStore().get(), 'new-session');
  });

  test('logout racing an in-flight read cannot restore the session', () async {
    final started = Completer<void>();
    final release = Completer<String?>();
    final store = TokenStore(read: () {
      started.complete();
      return release.future;
    });
    final reading = store.get();
    await started.future;
    final clearing = store.clear();
    release.complete('old-session');
    expect(await reading, null);
    await clearing;
    expect(await TokenStore().get(), null);
  });

  test('concurrent migration and logout end with no saved credential', () async {
    SharedPreferences.setMockInitialValues({'token': 'legacy'});
    final store = TokenStore();
    final reading = store.get();
    final clearing = store.clear();
    expect(await reading, null);
    await clearing;
    expect(await TokenStore().get(), null);
    expect(await storage.read(key: key), null);
  });

  test('API startup restores migrated auth and logout clears it', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'saved-session', 'role': 'parent', 'userId': 1, 'name': 'Parent',
    });
    await ApiService.initializeAuthState();
    expect(ApiService.isAuthenticated.value, true);
    expect(ApiService.userRole.value, 'parent');
    await ApiService.logout();
    expect(ApiService.isAuthenticated.value, false);
    expect(ApiService.userRole.value, null);
    expect(await ApiService.getToken(), null);
    expect(await storage.read(key: key), null);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('token'), false);
    expect(prefs.containsKey('userId'), false);
  });
}
