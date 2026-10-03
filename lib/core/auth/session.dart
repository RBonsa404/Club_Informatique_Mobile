import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_error.dart';
import '../api/cookies_io.dart' if (dart.library.js_interop) '../api/cookies_web.dart';
import '../api/models.dart';
import '../config.dart';

/// Session de l'utilisateur et client HTTP.
///
/// Le jeton d'accès reste en mémoire. Le jeton de renouvellement voyage dans le cookie que pose le serveur :
/// l'application le conserve dans le stockage chiffré de l'appareil et le renvoie pour renouveler la session.
class Session extends ChangeNotifier {
  Session() {
    dio = Dio(BaseOptions(
      baseUrl: adresseApi,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'Accept': 'application/json'},
    ));
    brancherLesCookies(dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: _avecJeton, onError: _surErreur));
  }

  late final Dio dio;
  String? _jeton;
  Utilisateur? _utilisateur;
  bool _pret = false;
  Future<bool>? _renouvellement;
  int _nonLues = 0;

  Utilisateur? get utilisateur => _utilisateur;
  bool get connecte => _utilisateur != null;

  /// Faux tant que la tentative de reprise de session au démarrage n'est pas terminée.
  bool get pret => _pret;
  int get nonLues => _nonLues;

  static bool _sansJeton(RequestOptions o) => o.extra['sansJeton'] == true;
  static final _options = Options(extra: {'sansJeton': true});

  void _avecJeton(RequestOptions options, RequestInterceptorHandler handler) {
    if (_jeton != null && !_sansJeton(options)) options.headers['Authorization'] = 'Bearer $_jeton';
    handler.next(options);
  }

  /// Jeton d'accès expiré : la session est renouvelée une fois, puis la requête est rejouée.
  Future<void> _surErreur(DioException erreur, ErrorInterceptorHandler handler) async {
    final options = erreur.requestOptions;
    final rejouable = erreur.response?.statusCode == 401 && !_sansJeton(options) && options.extra['rejouee'] != true && _utilisateur != null;
    if (!rejouable) return handler.next(erreur);
    if (await renouveler()) {
      try {
        options.extra['rejouee'] = true;
        return handler.resolve(await dio.fetch(options));
      } on DioException catch (seconde) {
        return handler.next(seconde);
      }
    }
    handler.next(erreur);
  }

  void _accepter(Object? brut) {
    final corps = brut is Map ? Json.from(brut) : const <String, dynamic>{};
    if (corps['accessToken'] is! String || corps['utilisateur'] is! Map) throw ErreurApi(Nature.serveur, 0, 'Réponse d’authentification invalide.');
    _jeton = corps['accessToken'] as String;
    _utilisateur = Utilisateur.lire(Json.from(corps['utilisateur'] as Map));
  }

  void _oublier() {
    _jeton = null;
    _utilisateur = null;
    _nonLues = 0;
  }

  /// Au démarrage : reprend la session si l'appareil en garde une.
  Future<void> reprendre() async {
    // L'écran d'ouverture reste visible un court instant, même si la reprise est immédiate.
    await Future.wait([renouveler(), Future<void>.delayed(const Duration(milliseconds: 1400))]);
    _pret = true;
    notifyListeners();
    if (connecte) unawaited(actualiserNonLues());
  }

  /// Les appels simultanés partagent une seule demande de renouvellement.
  Future<bool> renouveler() {
    return _renouvellement ??= () async {
      try {
        _accepter((await dio.post<Object?>('/auth/refresh', options: _options)).data);
        return true;
      } catch (_) {
        final etaitConnecte = connecte;
        _oublier();
        if (etaitConnecte) notifyListeners();
        return false;
      } finally {
        _renouvellement = null;
      }
    }();
  }

  Future<void> connecter(String email, String motDePasse) async {
    try {
      final reponse = await dio.post<Object?>('/auth/login', data: {'email': email.trim(), 'motDePasse': motDePasse, 'seSouvenir': true}, options: _options);
      _accepter(reponse.data);
      notifyListeners();
      unawaited(actualiserNonLues());
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  Future<void> inscrire({required String nom, required String prenom, required String email, required String filiere, required String motDePasse}) async {
    try {
      await dio.post<Object?>('/auth/register',
          data: {'nom': nom.trim(), 'prenom': prenom.trim(), 'email': email.trim(), 'filiere': filiere.trim(), 'motDePasse': motDePasse, 'consentement': true}, options: _options);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  Future<void> demanderReinitialisation(String email) async {
    try {
      await dio.post<Object?>('/auth/forgot-password', data: {'email': email.trim()}, options: _options);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  Future<void> deconnecter() async {
    try {
      await dio.post<Object?>('/auth/logout');
    } catch (_) {
      // La session locale est fermée même si le serveur est injoignable.
    }
    _oublier();
    notifyListeners();
  }

  /// Après une modification du profil : le nom affiché suit.
  void majIdentite({required String nom, required String prenom}) {
    final u = _utilisateur;
    if (u == null) return;
    _utilisateur = Utilisateur(id: u.id, email: u.email, nom: nom, prenom: prenom, roles: u.roles, changementMotDePasseRequis: u.changementMotDePasseRequis);
    notifyListeners();
  }

  Future<void> actualiserNonLues() async {
    if (!connecte) return;
    try {
      final reponse = await dio.get<Object?>('/notifications/non-lues/count');
      final valeur = reponse.data is Map ? (reponse.data as Map)['nonLues'] : null;
      final n = valeur is num ? valeur.toInt() : 0;
      if (n != _nonLues) {
        _nonLues = n;
        notifyListeners();
      }
    } catch (_) {
      // Le compteur est secondaire : son échec ne perturbe pas l'écran en cours.
    }
  }
}
