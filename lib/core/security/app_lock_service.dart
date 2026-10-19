import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key/value store for the app-lock PIN hash. Secure storage in the app,
/// in-memory in tests.
abstract class PinStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecurePinStore implements PinStore {
  SecurePinStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryPinStore implements PinStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Sets and checks the device app-lock PIN.
///
/// The PIN is never stored: only a random salt and a PBKDF2-HMAC-SHA256
/// hash of it, as `v1$iterations$salt$hash` (base64).
class AppLockService {
  AppLockService(this._store, {this.iterations = 20000});

  final PinStore _store;
  final int iterations;

  static const _key = 'app_lock_pin_v1';
  static const minLength = 4;
  static const maxLength = 6;

  static bool isValidPin(String pin) =>
      pin.length >= minLength && pin.length <= maxLength && RegExp(r'^\d+$').hasMatch(pin);

  Future<bool> hasPin() async => (await _store.read(_key)) != null;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError('PIN must be $minLength–$maxLength digits');
    }
    final rnd = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    final hash = pbkdf2(utf8.encode(pin), salt, iterations);
    await _store.write(_key, 'v1\$$iterations\$${base64Encode(salt)}\$${base64Encode(hash)}');
  }

  Future<bool> verify(String pin) async {
    final stored = await _store.read(_key);
    if (stored == null) return false;
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != 'v1') return false;
    final rounds = int.tryParse(parts[1]) ?? 0;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = pbkdf2(utf8.encode(pin), salt, rounds);
    // Constant-time compare.
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  Future<void> clearPin() => _store.delete(_key);

  /// PBKDF2-HMAC-SHA256, one 32-byte block.
  static List<int> pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.from(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }
}
