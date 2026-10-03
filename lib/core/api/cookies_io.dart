import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cookie de session conservé dans le stockage chiffré de l'appareil (trousseau Android).
class _StockageChiffre implements Storage {
  static const _coffre = FlutterSecureStorage();
  static const _prefixe = 'cookie.';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _coffre.read(key: '$_prefixe$key');

  @override
  Future<void> write(String key, String value) => _coffre.write(key: '$_prefixe$key', value: value);

  @override
  Future<void> delete(String key) => _coffre.delete(key: '$_prefixe$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}

/// Application installée : le client HTTP garde et renvoie lui-même le cookie de session.
void brancherLesCookies(Dio dio) {
  dio.interceptors.add(CookieManager(PersistCookieJar(storage: _StockageChiffre())));
}
