import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Aperçu dans un navigateur : c'est le navigateur qui garde le cookie de session.
void brancherLesCookies(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
