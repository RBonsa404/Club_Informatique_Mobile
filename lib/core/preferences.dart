import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Préférences de l'appareil : thème clair, sombre ou celui du système.
class Preferences extends ChangeNotifier {
  static const _stockage = FlutterSecureStorage();
  static const _cle = 'theme';

  ThemeMode _theme = ThemeMode.system;
  ThemeMode get theme => _theme;

  Future<void> charger() async {
    try {
      _theme = switch (await _stockage.read(key: _cle)) { 'clair' => ThemeMode.light, 'sombre' => ThemeMode.dark, _ => ThemeMode.system };
      notifyListeners();
    } catch (_) {
      // Stockage indisponible : le thème du système s'applique.
    }
  }

  Future<void> choisir(ThemeMode theme) async {
    _theme = theme;
    notifyListeners();
    try {
      await _stockage.write(key: _cle, value: switch (theme) { ThemeMode.light => 'clair', ThemeMode.dark => 'sombre', ThemeMode.system => 'systeme' });
    } catch (_) {
      // Le choix reste valable pour la session en cours.
    }
  }
}
