import 'package:club_informatique_mobile/core/api/api_error.dart';
import 'package:club_informatique_mobile/core/api/models.dart';
import 'package:club_informatique_mobile/core/format.dart';
import 'package:club_informatique_mobile/features/contenus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DioException _reponse(int statut, Object? corps) {
  final options = RequestOptions(path: '/essai');
  return DioException(requestOptions: options, response: Response(requestOptions: options, statusCode: statut, data: corps));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('dates', () {
    final debut = DateTime.utc(2026, 10, 9, 14, 0);
    test('affiche les heures et les dates en français, à l’heure d’Ouagadougou', () {
      expect(plageHoraire(debut, DateTime.utc(2026, 10, 9, 17, 30)), '14h00 à 17h30');
      expect(dateSimple(debut), '9 octobre 2026');
      expect(dateLongue(debut), 'Vendredi 9 octobre 2026');
      expect(jourDuMois(debut), '9');
      expect(moisCourt(debut), 'OCT');
    });

    test('lit une date sans fuseau comme une date UTC', () {
      final e = Evenement.lire({'id': 1, 'titre': 'A', 'slug': 'a', 'description': '', 'lieu': 'IST', 'dateDebut': '2026-10-09T14:00:00', 'dateFin': '2026-10-09T17:00:00Z'});
      expect(e.debut, DateTime.utc(2026, 10, 9, 14));
      expect(e.fin, DateTime.utc(2026, 10, 9, 17));
    });
  });

  group('texte rédigé', () {
    test('sépare titres, citations et paragraphes', () {
      final blocs = enBlocs('Introduction.\n\n# Titre\n\n> Citation\n\nSuite.');
      expect(blocs.map((b) => b.genre), [GenreDeBloc.paragraphe, GenreDeBloc.titre, GenreDeBloc.citation, GenreDeBloc.paragraphe]);
      expect(blocs[1].texte, 'Titre');
      expect(enBlocs('   '), isEmpty);
    });
  });

  group('mot de passe', () {
    test('applique la règle du serveur', () {
      expect(controlerMotDePasse('court'), isNotNull);
      expect(controlerMotDePasse('sansmajuscule1!'), isNotNull);
      expect(controlerMotDePasse('SansChiffre!'), isNotNull);
      expect(controlerMotDePasse('SansSymbole1'), isNotNull);
      expect(controlerMotDePasse('Conforme-2026'), isNull);
    });
  });

  group('modèles', () {
    test('lit une page de résultats et ignore les rôles inconnus', () {
      final page = PageDe.lire({'content': [{'id': 3, 'titre': 'T', 'slug': 't', 'description': 'd', 'statut': 'EN_COURS', 'technologies': 'Flutter, Java ; SQL'}], 'page': 0, 'totalPages': 2, 'totalElements': 11}, Projet.lire);
      expect(page.contenu.single.technos, ['Flutter', 'Java', 'SQL']);
      expect(page.derniere, isFalse);
      expect(page.total, 11);

      final u = Utilisateur.lire({'id': 1, 'email': 'a@b.c', 'nom': 'Salou', 'prenom': 'Christ Orient', 'roles': ['MEMBRE', 'FORMATEUR', 'INCONNU']});
      expect(u.roles, ['MEMBRE', 'FORMATEUR']);
      expect(u.roleAffiche, 'Formateur');
      expect(u.initiales, 'CS');
      expect(u.estMembre, isTrue);
    });

    test('ne déduit aucune place quand le serveur n’en donne pas', () {
      final e = Evenement.lire({'id': 1, 'titre': 'A', 'slug': 'a', 'description': '', 'lieu': 'IST'});
      expect(e.placesRestantes, isNull);
      expect(e.complet, isFalse);
    });
  });

  group('erreurs', () {
    test('reprend le message du serveur pour un refus métier et les erreurs par champ', () {
      final conflit = ErreurApi.depuis(_reponse(409, {'detail': 'Vous êtes déjà inscrit.', 'code': 'DEJA_INSCRIT'}));
      expect(conflit.message, 'Vous êtes déjà inscrit.');
      expect(conflit.code, 'DEJA_INSCRIT');

      final saisie = ErreurApi.depuis(_reponse(400, {'detail': 'Saisie invalide.', 'errors': [{'field': 'titre', 'message': 'Le titre est obligatoire.'}]}));
      expect(saisie.champs['titre'], 'Le titre est obligatoire.');
    });

    test('ne révèle pas le détail d’une erreur interne et signale l’absence de réseau', () {
      expect(ErreurApi.depuis(_reponse(500, {'detail': 'NullPointerException'})).message, isNot(contains('NullPointer')));
      expect(ErreurApi.depuis(DioException(requestOptions: RequestOptions(path: '/x'))).nature, Nature.reseau);
    });

    test('reprend le message d’identifiants refusés', () {
      final refus = ErreurApi.depuis(_reponse(401, {'detail': 'Adresse électronique ou mot de passe incorrect.', 'code': 'IDENTIFIANTS_REFUSES'}));
      expect(refus.message, 'Adresse électronique ou mot de passe incorrect.');
    });
  });

  group('liens des notifications', () {
    test('ouvre dans l’application les pages qu’elle contient', () {
      expect(routeDeNotification('/espace/projets'), '/espace/projets');
      expect(routeDeNotification('/espace/supports'), '/espace/supports');
      expect(routeDeNotification('/evenements/atelier-git'), '/evenements/atelier-git');
      expect(routeDeNotification('/formations/initiation'), '/formations/initiation');
      expect(routeDeNotification('/evenements'), '/activites');
    });

    test('renvoie vers le site pour les pages de gestion', () {
      expect(routeDeNotification('/espace/gestion/projets'), isNull);
    });
  });
}
