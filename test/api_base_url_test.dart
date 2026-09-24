import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/services/api_client.dart';

void main() {
  test('release accepts an absolute public HTTPS endpoint', () {
    expect(
      validateApiBaseUrl(
        'https://api.poolman.ir/v1',
        isRelease: true,
      ),
      'https://api.poolman.ir/v1',
    );
  });

  for (final invalid in [
    '',
    'not a uri',
    'http://api.poolman.ir',
    'https:///missing-host',
    'https://money-tracker.example.workers.dev',
    'https://localhost:8787',
    'https://127.0.0.1',
    'https://10.0.0.5',
    'https://172.16.1.2',
    'https://192.168.1.2',
    'https://[::1]',
    'https://[::ffff:127.0.0.1]',
    'https://service.internal',
    'https://user:pass@api.poolman.ir',
    'https://api.poolman.ir?token=secret',
  ]) {
    test('release rejects $invalid', () {
      expect(
        () => validateApiBaseUrl(invalid, isRelease: true),
        throwsStateError,
      );
    });
  }

  test('debug can use a local HTTP development endpoint', () {
    expect(
      validateApiBaseUrl('http://localhost:8787', isRelease: false),
      'http://localhost:8787',
    );
  });
}
