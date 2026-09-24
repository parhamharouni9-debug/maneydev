import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureValueStore implements SecureValueStore {
  FlutterSecureValueStore()
      : _storage = const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureCookieStorage implements Storage {
  SecureCookieStorage({
    required SecureValueStore secureStorage,
    Storage? legacyStorage,
  })  : _secureStorage = secureStorage,
        _legacyStorage = legacyStorage;

  factory SecureCookieStorage.android({required Storage legacyStorage}) =>
      SecureCookieStorage.platform(legacyStorage: legacyStorage);

  factory SecureCookieStorage.platform({required Storage legacyStorage}) =>
      SecureCookieStorage(
        secureStorage: FlutterSecureValueStore(),
        legacyStorage: legacyStorage,
      );

  final SecureValueStore _secureStorage;
  final Storage? _legacyStorage;
  late String _keyPrefix;
  Future<void> _operationTail = Future<void>.value();

  String _secureKey(String key) => '$_keyPrefix$key';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) =>
      _serialized(() async {
        _keyPrefix = 'pool_man.cookies.v1.'
            'ie${ignoreExpires ? 1 : 0}.ps${persistSession ? 1 : 0}.';
        await _legacyStorage?.init(persistSession, ignoreExpires);
      });

  @override
  Future<String?> read(String key) => _serialized(() async {
        final secureKey = _secureKey(key);
        final secured = await _secureStorage.read(secureKey);
        if (secured != null) return secured;

        final legacy = await _legacyStorage?.read(key);
        if (legacy == null) return null;

        await _secureStorage.write(secureKey, legacy);
        final verified = await _secureStorage.read(secureKey);
        if (verified != legacy) {
          throw StateError('Secure cookie migration verification failed.');
        }
        await _legacyStorage?.delete(key);
        return legacy;
      });

  @override
  Future<void> write(String key, String value) => _serialized(() async {
        await _secureStorage.write(_secureKey(key), value);
        await _legacyStorage?.delete(key);
      });

  @override
  Future<void> delete(String key) => _serialized(() async {
        await _secureStorage.delete(_secureKey(key));
        await _legacyStorage?.delete(key);
      });

  @override
  Future<void> deleteAll(List<String> keys) => _serialized(() async {
        await Future.wait(
          keys.map((key) => _secureStorage.delete(_secureKey(key))),
        );
        await _legacyStorage?.deleteAll(keys);
      });

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
