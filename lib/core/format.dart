import 'package:intl/intl.dart';

// Heure d'Ouagadougou : UTC toute l'année. Les dates de l'API sont affichées telles quelles, en UTC.
final _jour = DateFormat('d MMMM y', 'fr');
final _jourCourt = DateFormat('d MMM', 'fr');
final _jourLong = DateFormat('EEEE d MMMM y', 'fr');

String _h(DateTime d) => '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
String _maj(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

String dateSimple(DateTime? d) => d == null ? '' : _jour.format(d.toUtc());
String dateCourte(DateTime? d) => d == null ? '' : _jourCourt.format(d.toUtc());
String dateLongue(DateTime? d) => d == null ? '' : _maj(_jourLong.format(d.toUtc()));
String heure(DateTime? d) => d == null ? '' : _h(d.toUtc());
String jourDuMois(DateTime? d) => d == null ? '' : '${d.toUtc().day}';
String moisCourt(DateTime? d) => d == null ? '' : DateFormat('MMM', 'fr').format(d.toUtc()).replaceAll('.', '').toUpperCase();

/// « 9h00 à 12h30 », ou une seule heure si la fin manque.
String plageHoraire(DateTime? debut, DateTime? fin) {
  if (debut == null) return '';
  if (fin == null) return heure(debut);
  return '${heure(debut)} à ${heure(fin)}';
}

/// « il y a 3 h », « hier », puis la date.
String ilYA(DateTime? d) {
  if (d == null) return '';
  final ecart = DateTime.now().toUtc().difference(d.toUtc());
  if (ecart.inMinutes < 1) return 'à l’instant';
  if (ecart.inMinutes < 60) return 'il y a ${ecart.inMinutes} min';
  if (ecart.inHours < 24) return 'il y a ${ecart.inHours} h';
  if (ecart.inDays == 1) return 'hier';
  if (ecart.inDays < 7) return 'il y a ${ecart.inDays} jours';
  return dateSimple(d);
}

enum GenreDeBloc { titre, citation, paragraphe }

class Bloc {
  const Bloc(this.genre, this.texte);
  final GenreDeBloc genre;
  final String texte;
}

/// Découpe un texte rédigé dans l'administration : paragraphes séparés par une ligne vide,
/// titres commençant par « # », citations par « > ». Même règle que sur le site.
List<Bloc> enBlocs(String? texte) {
  if (texte == null || texte.trim().isEmpty) return const [];
  return texte
      .replaceAll(r'\n', '\n')
      .split(RegExp(r'\n{2,}'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) {
    if (RegExp(r'^#{1,6}\s').hasMatch(e)) return Bloc(GenreDeBloc.titre, e.replaceFirst(RegExp(r'^#{1,6}\s+'), ''));
    if (e.startsWith('>')) return Bloc(GenreDeBloc.citation, e.replaceAll(RegExp(r'^>\s?', multiLine: true), ''));
    return Bloc(GenreDeBloc.paragraphe, e);
  }).toList();
}

/// Règle de mot de passe du serveur : 8 caractères, une minuscule, une majuscule, un chiffre, un symbole.
String? controlerMotDePasse(String valeur) {
  if (valeur.length < 8) return 'Au moins 8 caractères.';
  if (!RegExp(r'[a-z]').hasMatch(valeur)) return 'Ajoutez une lettre minuscule.';
  if (!RegExp(r'[A-Z]').hasMatch(valeur)) return 'Ajoutez une lettre majuscule.';
  if (!RegExp(r'\d').hasMatch(valeur)) return 'Ajoutez un chiffre.';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(valeur)) return 'Ajoutez un symbole.';
  return null;
}
