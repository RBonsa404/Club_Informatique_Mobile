import 'package:dio/dio.dart';

enum Nature { reseau, nonConnecte, interdit, introuvable, conflit, saisie, debit, serveur }

/// Erreur d'API au format RFC 9457, avec un code stable et des erreurs par champ.
class ErreurApi implements Exception {
  ErreurApi(this.nature, this.statut, this.message, {this.code, this.champs = const {}});

  final Nature nature;
  final int statut;

  /// Message destiné à l'utilisateur.
  final String message;
  final String? code;
  final Map<String, String> champs;

  static const _messages = {
    Nature.reseau: 'Connexion impossible. Vérifiez votre accès à Internet, puis réessayez.',
    Nature.nonConnecte: 'Votre session a expiré. Veuillez vous reconnecter.',
    Nature.interdit: 'Vous n’avez pas accès à ce contenu.',
    Nature.introuvable: 'Ce contenu est introuvable.',
    Nature.conflit: 'Cette opération entre en conflit avec des données existantes.',
    Nature.saisie: 'Certains champs sont invalides. Vérifiez votre saisie.',
    Nature.debit: 'Trop de tentatives. Réessayez dans quelques minutes.',
    Nature.serveur: 'Un problème est survenu de notre côté. Réessayez dans quelques instants.',
  };

  static ErreurApi depuis(Object erreur) {
    if (erreur is ErreurApi) return erreur;
    if (erreur is! DioException) return ErreurApi(Nature.serveur, 0, _messages[Nature.serveur]!);
    if (erreur.error is ErreurApi) return erreur.error as ErreurApi;
    final reponse = erreur.response;
    if (reponse == null) return ErreurApi(Nature.reseau, 0, _messages[Nature.reseau]!);

    final statut = reponse.statusCode ?? 0;
    final nature = switch (statut) {
      401 => Nature.nonConnecte,
      403 || 423 => Nature.interdit,
      404 => Nature.introuvable,
      409 => Nature.conflit,
      400 || 422 => Nature.saisie,
      429 => Nature.debit,
      _ => Nature.serveur,
    };
    final corps = reponse.data is Map ? Map<String, dynamic>.from(reponse.data as Map) : const <String, dynamic>{};
    final code = corps['code']?.toString();
    final detail = corps['detail']?.toString();
    final champs = <String, String>{};
    if (corps['errors'] is List) {
      for (final e in (corps['errors'] as List).whereType<Map>()) {
        champs.putIfAbsent('${e['field']}', () => '${e['message']}');
      }
    }
    // Le détail est rédigé par le serveur pour l'utilisateur : refus métier, identifiants, compte non actif, maintenance.
    final explicite = nature == Nature.conflit ||
        nature == Nature.saisie ||
        statut == 401 && code != null ||
        statut == 503 ||
        statut == 423 ||
        nature == Nature.interdit && code != null && code != 'ACCES_REFUSE';
    return ErreurApi(nature, statut, explicite && detail != null && detail.isNotEmpty ? detail : _messages[nature]!, code: code, champs: champs);
  }

  @override
  String toString() => message;
}
