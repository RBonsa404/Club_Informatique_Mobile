import 'package:flutter/foundation.dart';

/// Adresse de l'API. L'application appelle le backend de la plateforme web, sans le modifier.
/// Elle se remplace à la compilation : `--dart-define=API_URL=https://…/api/v1`.
const _adresseDefinie = String.fromEnvironment('API_URL');
const _adresseEnLigne = 'https://istclubinformatique.up.railway.app/api/v1';

/// Dans un navigateur (aperçu de développement), l'API est servie sous la même origine que l'application.
String get adresseApi => _adresseDefinie.isNotEmpty ? _adresseDefinie : (kIsWeb ? '/api/v1' : _adresseEnLigne);

/// Origine du site web : sert à ouvrir les pages qui restent sur le web (pages légales, espaces de gestion).
String get origineDuSite => adresseApi.startsWith('http') ? Uri.parse(adresseApi).origin : Uri.base.origin;

/// Coordonnées réelles du club.
class Club {
  static const nom = 'Club Informatique de l’IST';
  static const nomCourt = 'Club Informatique';
  static const institution = 'Institut Supérieur de Technologie';
  static const ville = 'Ouagadougou, Burkina Faso';
  static const courriel = 'clubinformatique.ist@gmail.com';
  static const whatsapp = 'https://wa.me/22664931557';
  static const whatsappAffiche = '+226 64 93 15 57';
  static const linkedin = 'https://www.linkedin.com/in/club-informatique-453a4043b/';
  static const facebook = 'https://web.facebook.com/profile.php?id=61594887003694';
  static const tiktok = 'https://www.tiktok.com/@clubinformatique74';
}
