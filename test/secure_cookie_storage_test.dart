import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/services/api_client.dart';
import 'package:pool_man/services/secure_cookie_storage.dart';

class MemorySecureStore implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class MemoryLegacyStorage implements Storage {
  final values = <String, String>{};

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll(List<String> keys) async => values.clear();
}

class BlockingLegacyStorage extends MemoryLegacyStorage {
  final readStarted = Completer<void>();
  final allowRead = Completer<void>();

  @override
  Future<String?> read(String key) async {
    if (!readStarted.isCompleted) readStarted.complete();
    if (!allowRead.isCompleted) await allowRead.future;
    return super.read(key);
  }
}

class DroppingSecureStore extends MemorySecureStore {
  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  test('writes and reads cookies only through secure storage', () async {
    final secure = MemorySecureStore();
    final legacy = MemoryLegacyStorage();
    final storage = SecureCookieStorage(
      secureStorage: secure,
      legacyStorage: legacy,
    );
    await storage.init(true, false);

    await storage.write('session', 'secret-cookie');

    expect(await storage.read('session'), 'secret-cookie');
    expect(legacy.values, isEmpty);
    expect(secure.values.values, contains('secret-cookie'));
  });

  test('migrates a legacy cookie and deletes its plaintext copy', () async {
    final secure = MemorySecureStore();
    final legacy = MemoryLegacyStorage()..values['session'] = 'old-cookie';
    final storage = SecureCookieStorage(
      secureStorage: secure,
      legacyStorage: legacy,
    );
    await storage.init(true, false);

    expect(await storage.read('session'), 'old-cookie');
    expect(legacy.values, isEmpty);
    expect(secure.values.values, contains('old-cookie'));
  });

  test('legacy plaintext survives when secure migration cannot be verified',
      () async {
    final secure = DroppingSecureStore();
    final legacy = MemoryLegacyStorage()..values['session'] = 'old-cookie';
    final storage = SecureCookieStorage(
      secureStorage: secure,
      legacyStorage: legacy,
    );
    await storage.init(true, false);

    await expectLater(storage.read('session'), throwsA(isA<StateError>()));

    expect(legacy.values['session'], 'old-cookie');
  });

  test('deleteAll clears secure and legacy cookie copies', () async {
    final secure = MemorySecureStore();
    final legacy = MemoryLegacyStorage();
    final storage = SecureCookieStorage(
      secureStorage: secure,
      legacyStorage: legacy,
    );
    await storage.init(true, false);
    await storage.write('one', '1');
    await storage.write('two', '2');
    legacy.values['one'] = 'legacy';

    await storage.deleteAll(['one', 'two']);

    expect(secure.values, isEmpty);
    expect(legacy.values, isEmpty);
  });

  test('a concurrent new write wins over legacy migration', () async {
    final secure = MemorySecureStore();
    final legacy = BlockingLegacyStorage()..values['session'] = 'old-cookie';
    final storage = SecureCookieStorage(
      secureStorage: secure,
      legacyStorage: legacy,
    );
    await storage.init(true, false);

    final migratingRead = storage.read('session');
    await legacy.readStarted.future;
    final newWrite = storage.write('session', 'new-cookie');
    legacy.allowRead.complete();

    expect(await migratingRead, 'old-cookie');
    await newWrite;
    expect(await storage.read('session'), 'new-cookie');
    expect(legacy.values, isEmpty);
  });

  test('concurrent initialization is single-flight', () async {
    final initializer = SingleFlightInitializer();
    final release = Completer<void>();
    var calls = 0;

    Future<void> initialize() async {
      calls++;
      await release.future;
    }

    final first = initializer.run(initialize);
    final second = initializer.run(initialize);
    expect(calls, 1);

    release.complete();
    await Future.wait([first, second]);
    await initializer.run(initialize);
    expect(calls, 1);
  });
}
