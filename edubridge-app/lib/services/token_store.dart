import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageException implements Exception {
  const TokenStorageException();

  @override
  String toString() => 'تعذّر حفظ جلسة الدخول بأمان، حاول مرة أخرى';
}

/// Serializes credential changes and migrates the old plaintext token only
/// after verifying the secure copy. A durable logout marker blocks stale keys
/// if the platform cannot delete them immediately.
class TokenStore {
  TokenStore({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
    Future<void> Function()? delete,
  })  : _read = read ?? (() => _storage.read(key: _key)),
        _write = write ?? ((token) => _storage.write(key: _key, value: token)),
        _delete = delete ?? (() => _storage.delete(key: _key));

  static final instance = TokenStore();
  static const _key = 'edubridge.auth.token';
  static const _cleared = 'auth.token.cleared';
  static const _migrating = 'auth.token.migrating';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(migrateWithBackup: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  final Future<void> Function() _delete;
  Future<void> _tail = Future<void>.value();
  bool _blocked = false;

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  void _require(bool persisted) {
    if (!persisted) throw const TokenStorageException();
  }

  Future<String?> get() => _serialize(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (_blocked || prefs.getBool(_cleared) == true) {
            await _cleanup(prefs);
            return null;
          }
          final stored = await _read();
          if (stored != null && stored.isNotEmpty &&
              prefs.getBool(_migrating) != true) {
            _require(await prefs.remove('token'));
            return _blocked ? null : stored;
          }
          final legacy = prefs.getString('token');
          if (legacy == null || legacy.isEmpty) {
            _require(await prefs.remove(_migrating));
            return _blocked || stored == null || stored.isEmpty ? null : stored;
          }
          _require(await prefs.setBool(_migrating, true));
          await _write(legacy);
          if (await _read() != legacy) throw const TokenStorageException();
          _require(await prefs.remove('token'));
          _require(await prefs.remove(_migrating));
          return _blocked ? null : legacy;
        } catch (_) {
          // Never fall back to a plaintext token or strand the startup splash.
          // Failed migration leaves its source available for a later retry.
          return null;
        }
      });

  Future<void> save(String token) => _serialize(() async {
        if (token.isEmpty) throw const TokenStorageException();
        try {
          final prefs = await SharedPreferences.getInstance();
          // Prevent a partial secure write being restored as a valid session.
          _require(await prefs.setBool(_cleared, true));
          await _write(token);
          if (await _read() != token) throw const TokenStorageException();
          _require(await prefs.remove('token'));
          _require(await prefs.remove(_migrating));
          _require(await prefs.remove(_cleared));
          _blocked = false;
        } catch (_) {
          _blocked = true;
          throw const TokenStorageException();
        }
      });

  Future<void> clear() {
    _blocked = true;
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      _require(await prefs.setBool(_cleared, true));
      await _cleanup(prefs);
    });
  }

  Future<void> _cleanup(SharedPreferences prefs) async {
    // Keep the durable marker until a new verified token is saved.
    try {
      await _delete();
    } catch (_) {
      // The marker prevents reuse; get() retries cleanup after restart.
    }
    _require(await prefs.remove('token'));
    _require(await prefs.remove(_migrating));
  }
}
