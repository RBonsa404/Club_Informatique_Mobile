import 'package:dio/dio.dart';

import 'api_error.dart';
import 'models.dart';

/// Appels à l'API de la plateforme. Chaque méthode correspond à une route existante du backend.
class ClubApi {
  ClubApi(this._dio);
  final Dio _dio;

  Future<T> _appel<T>(Future<Response<Object?>> Function() requete, T Function(Object? corps) lire) async {
    try {
      return lire((await requete()).data);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  static Json _objet(Object? c) => c is Map ? Json.from(c) : <String, dynamic>{};
  static List<T> _liste<T>(Object? c, T Function(Json) lire) => (c is List ? c : const []).whereType<Map>().map((e) => lire(Json.from(e))).toList();
  static Map<String, dynamic> _sansNuls(Map<String, dynamic> m) => {...m}..removeWhere((_, v) => v == null);

  // ───── Contenus publics ─────
  Future<String> texteDePage(String slug) => _appel(() => _dio.get('/pages/$slug'), (c) => '${_objet(c)['contenu'] ?? ''}');
  Future<List<MembreBureau>> bureau() => _appel(() => _dio.get('/bureau'), (c) => _liste(c, MembreBureau.lire));
  Future<List<Categorie>> categories() => _appel(() => _dio.get('/categories'), (c) => _liste(c, Categorie.lire));

  Future<PageDe<Actualite>> actualites({int page = 0, int taille = 10}) =>
      _appel(() => _dio.get('/actualites', queryParameters: {'page': page, 'size': taille}), (c) => PageDe.lire(c, Actualite.lire));
  Future<Actualite> actualite(String slug) => _appel(() => _dio.get('/actualites/slug/$slug'), (c) => Actualite.lire(_objet(c)));

  /// Publications visibles par un membre connecté : actualités publiques et annonces réservées aux membres.
  Future<PageDe<Actualite>> publications({int page = 0, int taille = 10}) =>
      _appel(() => _dio.get('/publications', queryParameters: {'page': page, 'size': taille}), (c) => PageDe.lire(c, Actualite.lire));
  Future<Actualite> publication(String slug) => _appel(() => _dio.get('/publications/slug/$slug'), (c) => Actualite.lire(_objet(c)));

  Future<PageDe<Evenement>> evenements({int page = 0, int taille = 10, bool? aVenir}) => _appel(
      () => _dio.get('/evenements', queryParameters: _sansNuls({'page': page, 'size': taille, 'aVenir': aVenir, 'sort': aVenir == false ? 'dateDebut,desc' : 'dateDebut,asc'})),
      (c) => PageDe.lire(c, Evenement.lire));
  Future<Evenement> evenement(String slug) => _appel(() => _dio.get('/evenements/slug/$slug'), (c) => Evenement.lire(_objet(c)));

  Future<PageDe<Formation>> formations({int page = 0, int taille = 10}) =>
      _appel(() => _dio.get('/formations', queryParameters: {'page': page, 'size': taille}), (c) => PageDe.lire(c, Formation.lire));
  Future<Formation> formation(String slug) => _appel(() => _dio.get('/formations/slug/$slug'), (c) => Formation.lire(_objet(c)));

  Future<PageDe<Projet>> projets({int page = 0, int taille = 10}) =>
      _appel(() => _dio.get('/projets', queryParameters: {'page': page, 'size': taille}), (c) => PageDe.lire(c, Projet.lire));
  Future<Projet> projet(String slug) => _appel(() => _dio.get('/projets/slug/$slug'), (c) => Projet.lire(_objet(c)));

  Future<PageDe<Ressource>> ressourcesPubliques({int page = 0, int taille = 20}) =>
      _appel(() => _dio.get('/ressources/publiques', queryParameters: {'page': page, 'size': taille}), (c) => PageDe.lire(c, Ressource.lire));

  Future<void> contacter({required String nom, required String email, required String sujet, required String message, required int dureeSaisieMs}) => _appel(
      () => _dio.post('/contact', data: {'nom': nom, 'email': email, 'sujet': sujet, 'message': message, 'siteWeb': '', 'dureeSaisieMs': dureeSaisieMs}), (_) {});

  // ───── Inscriptions ─────
  Future<PageDe<Inscription>> mesInscriptions({int taille = 100}) =>
      _appel(() => _dio.get('/inscriptions/me', queryParameters: {'page': 0, 'size': taille, 'sort': 'dateInscription,desc'}), (c) => PageDe.lire(c, Inscription.lire));
  Future<Inscription> inscrireEvenement(int id) => _appel(() => _dio.post('/inscriptions/evenements/$id'), (c) => Inscription.lire(_objet(c)));
  Future<Inscription> inscrireSeance(int id) => _appel(() => _dio.post('/inscriptions/formations/$id'), (c) => Inscription.lire(_objet(c)));
  Future<void> annulerInscription(int id) => _appel(() => _dio.delete('/inscriptions/$id'), (_) {});

  // ───── Supports et devoirs ─────
  Future<List<Ressource>> ressourcesDeFormation(int formationId) => _appel(() => _dio.get('/ressources/formation/$formationId'), (c) => _liste(c, Ressource.lire));
  Future<List<Devoir>> devoirsDeFormation(int formationId) => _appel(() => _dio.get('/formations/$formationId/devoirs'), (c) => _liste(c, Devoir.lire));

  // ───── Projets du membre ─────
  Future<PageDe<Projet>> mesProjets() => _appel(() => _dio.get('/projets/mes-projets', queryParameters: {'page': 0, 'size': 50}), (c) => PageDe.lire(c, Projet.lire));
  Future<Projet> proposerProjet({required String titre, required String description, required String objectifs, required String technologies, String? depotGit, int? categorieId}) => _appel(
      () => _dio.post('/projets', data: {'titre': titre, 'description': description, 'objectifs': objectifs, 'technologies': technologies, 'depotGit': depotGit, 'categorieId': categorieId}),
      (c) => Projet.lire(_objet(c)));

  // ───── Notifications ─────
  Future<PageDe<NotificationRecue>> notifications({int page = 0, bool? lue}) =>
      _appel(() => _dio.get('/notifications', queryParameters: _sansNuls({'page': page, 'size': 20, 'lue': lue})), (c) => PageDe.lire(c, NotificationRecue.lire));
  Future<void> marquerLue(int id) => _appel(() => _dio.put('/notifications/$id/lue'), (_) {});
  Future<void> toutMarquerLu() => _appel(() => _dio.put('/notifications/lire-toutes'), (_) {});

  // ───── Compte ─────
  Future<Profil> profil() => _appel(() => _dio.get('/users/me'), (c) => Profil.lire(_objet(c)));
  Future<Profil> modifierProfil({required String nom, required String prenom, required String filiere, required String biographie}) =>
      _appel(() => _dio.put('/users/me', data: {'nom': nom, 'prenom': prenom, 'filiere': filiere, 'biographie': biographie}), (c) => Profil.lire(_objet(c)));
  Future<Profil> deposerPhoto(List<int> octets, String nomDuFichier, String typeMime) => _appel(
      () => _dio.post('/users/me/photo', data: FormData.fromMap({'fichier': MultipartFile.fromBytes(octets, filename: nomDuFichier, contentType: DioMediaType.parse(typeMime))})),
      (c) => Profil.lire(_objet(c)));
  Future<Profil> retirerPhoto() => _appel(() => _dio.delete('/users/me/photo'), (c) => Profil.lire(_objet(c)));
  Future<void> changerMotDePasse(String ancien, String nouveau) => _appel(() => _dio.put('/users/me/password', data: {'ancienMotDePasse': ancien, 'nouveauMotDePasse': nouveau}), (_) {});
  Future<bool> preferenceCourriel() => _appel(() => _dio.get('/users/me/preferences'), (c) => _objet(c)['notificationsCourriel'] == true);
  Future<void> reglerPreferenceCourriel(bool active) => _appel(() => _dio.put('/users/me/preferences', data: {'notificationsCourriel': active}), (_) {});

  /// Contenu d'un fichier protégé (photo de profil, support), lu avec la session en cours.
  Future<({List<int> octets, String? type, String? nom})> telecharger(String adresse) async {
    try {
      final reponse = await _dio.get<List<int>>(adresse.startsWith('/api/v1') ? adresse.substring(7) : adresse, options: Options(responseType: ResponseType.bytes));
      final disposition = reponse.headers.value('content-disposition') ?? '';
      final nom = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''').firstMatch(disposition)?.group(1);
      return (octets: reponse.data ?? <int>[], type: reponse.headers.value('content-type')?.split(';').first.trim(), nom: nom == null ? null : Uri.decodeComponent(nom));
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  /// Vrai si l'adresse désigne un fichier déposé sur la plateforme (et non un lien externe).
  static bool estFichierDepose(String adresse) => adresse.startsWith('/api/v1/fichiers/') || adresse.startsWith('/fichiers/');
}
