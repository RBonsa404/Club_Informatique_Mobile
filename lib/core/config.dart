import 'package:flutter/foundation.dart';

/// Adresse de l'API. L'application appelle le backend de la plateforme web, sans le modifier.
/// Elle se remplace à la compilation : `--dart-define=API_URL=https://…/api/v1`.
const _adresseDefinie = String.fromEnvironment('API_URL');
const _adresseEnLigne = 'https://api.ist-club.bf/api/v1';

/// Dans un navigateur (aperçu de développement), l'API est servie sous la même origine que l'application.
String get adresseApi => _adresseDefinie.isNotEmpty ? _adresseDefinie : (kIsWeb ? '/api/v1' : _adresseEnLigne);

/// Origine du site web, distincte de celle de l'API : sert à ouvrir les pages qui restent sur le web
/// (pages légales, espaces de gestion). Remplaçable à la compilation : `--dart-define=SITE_URL=https://…`.
const _siteDefini = String.fromEnvironment('SITE_URL');
const _siteEnLigne = 'https://informatique.ist-club.bf';
String get origineDuSite => _siteDefini.isNotEmpty ? _siteDefini : (kIsWeb ? Uri.base.origin : _siteEnLigne);

/// Coordonnées réelles du club.
class Club {
  static const nom = 'Club Informatique de l’IST';
  static const nomCourt = 'Club Informatique';
  static const institution = 'Institut Supérieur de Technologies';
  static const ville = 'Ouagadougou, Burkina Faso';
  static const courriel = 'contact@informatique.ist-club.bf';
  static const whatsapp = 'https://wa.me/22664931557';
  static const whatsappAffiche = '+226 64 93 15 57';
  static const linkedin = 'https://www.linkedin.com/in/club-informatique-453a4043b/';
  static const facebook = 'https://www.facebook.com/profile.php?id=61595555190991';
  static const tiktok = 'https://www.tiktok.com/@istclubinformatique';
}
