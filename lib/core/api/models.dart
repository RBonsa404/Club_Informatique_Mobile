// Modèles des réponses de l'API. Les dates sont transmises en ISO 8601 (UTC).

typedef Json = Map<String, dynamic>;

String _s(Object? v) => v?.toString() ?? '';
String? _sn(Object? v) {
  final t = v?.toString().trim();
  return t == null || t.isEmpty ? null : t;
}

int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
int? _in(Object? v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
DateTime? _d(Object? v) {
  final t = _sn(v);
  if (t == null) return null;
  // Une date sans fuseau est en UTC (heure d'Ouagadougou).
  final avecFuseau = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(t) ? t : '${t}Z';
  return DateTime.tryParse(avecFuseau)?.toUtc();
}

/// Page de résultats, au format du contrat de pagination.
class PageDe<T> {
  const PageDe({required this.contenu, required this.page, required this.pages, required this.total});
  final List<T> contenu;
  final int page;
  final int pages;
  final int total;

  bool get derniere => page + 1 >= pages;

  static PageDe<T> lire<T>(Object? brut, T Function(Json) lire) {
    final r = brut is Map ? Json.from(brut) : <String, dynamic>{};
    final contenu = (r['content'] is List ? r['content'] as List : const []).whereType<Map>().map((e) => lire(Json.from(e))).toList();
    return PageDe(contenu: contenu, page: _i(r['page']), pages: _in(r['totalPages']) ?? (contenu.isEmpty ? 0 : 1), total: _in(r['totalElements']) ?? contenu.length);
  }
}

const rolesConnus = ['MEMBRE', 'FORMATEUR', 'RESPONSABLE_CLUB', 'ADMIN', 'SUPER_ADMIN', 'DSI'];
const libellesDesRoles = {
  'MEMBRE': 'Membre',
  'FORMATEUR': 'Formateur',
  'RESPONSABLE_CLUB': 'Responsable du Club',
  'ADMIN': 'Administrateur',
  'SUPER_ADMIN': 'Super Admin',
  'DSI': 'DSI',
};

/// Du rôle le plus élevé au moins élevé : donne le libellé affiché.
const prioriteDesRoles = ['SUPER_ADMIN', 'ADMIN', 'DSI', 'RESPONSABLE_CLUB', 'FORMATEUR', 'MEMBRE'];

class Utilisateur {
  const Utilisateur({required this.id, required this.email, required this.nom, required this.prenom, required this.roles, required this.changementMotDePasseRequis});
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final List<String> roles;
  final bool changementMotDePasseRequis;

  String get nomComplet => '$prenom $nom'.trim();
  String get initiales => [prenom, nom].where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase()).join();
  String get roleAffiche => libellesDesRoles[prioriteDesRoles.firstWhere(roles.contains, orElse: () => 'MEMBRE')] ?? 'Membre';

  /// Le Formateur et le Responsable du Club sont aussi membres.
  bool get estMembre => roles.any((r) => r == 'MEMBRE' || r == 'FORMATEUR' || r == 'RESPONSABLE_CLUB');

  factory Utilisateur.lire(Json j) => Utilisateur(
        id: _i(j['id']),
        email: _s(j['email']),
        nom: _s(j['nom']),
        prenom: _s(j['prenom']),
        roles: (j['roles'] is List ? j['roles'] as List : const []).map((e) => '$e').where(rolesConnus.contains).toList(),
        changementMotDePasseRequis: j['changementMotDePasseRequis'] == true,
      );
}

class Actualite {
  const Actualite({required this.id, required this.titre, required this.slug, required this.contenu, this.resume, this.date, this.auteur, this.categorie, this.reserveeAuxMembres = false});
  final int id;
  final String titre;
  final String slug;
  final String contenu;
  final String? resume;
  final DateTime? date;
  final String? auteur;
  final String? categorie;
  final bool reserveeAuxMembres;

  factory Actualite.lire(Json j) => Actualite(
        id: _i(j['id']),
        titre: _s(j['titre']),
        slug: _s(j['slug']),
        contenu: _s(j['contenu']),
        resume: _sn(j['resume']),
        date: _d(j['datePublication']) ?? _d(j['createdAt']),
        auteur: _sn(j['auteurNom']),
        categorie: _sn(j['categorieNom']),
        reserveeAuxMembres: j['visibilite'] == 'MEMBRES',
      );
}

class Evenement {
  const Evenement({required this.id, required this.titre, required this.slug, required this.description, required this.debut, required this.fin, required this.lieu, this.capacite, this.inscrits, this.placesRestantes, this.categorie, this.organisateur});
  final int id;
  final String titre;
  final String slug;
  final String description;
  final DateTime? debut;
  final DateTime? fin;
  final String lieu;
  final int? capacite;
  final int? inscrits;
  final int? placesRestantes;
  final String? categorie;
  final String? organisateur;

  bool get passe => (fin ?? debut)?.isBefore(DateTime.now().toUtc()) ?? false;
  bool get complet => placesRestantes != null && placesRestantes! <= 0;

  factory Evenement.lire(Json j) => Evenement(
        id: _i(j['id']),
        titre: _s(j['titre']),
        slug: _s(j['slug']),
        description: _s(j['description']),
        debut: _d(j['dateDebut']),
        fin: _d(j['dateFin']),
        lieu: _s(j['lieu']),
        capacite: _in(j['capaciteMax']),
        inscrits: _in(j['nombreInscrits']),
        placesRestantes: _in(j['placesRestantes']),
        categorie: _sn(j['categorieNom']),
        organisateur: _sn(j['organisateurNom']),
      );
}

const libellesDesNiveaux = {'DEBUTANT': 'Débutant', 'INTERMEDIAIRE': 'Intermédiaire', 'AVANCE': 'Avancé', 'TOUS_NIVEAUX': 'Tous niveaux'};
const libellesDesSeances = {'PLANIFIEE': 'Planifiée', 'EN_COURS': 'En cours', 'TERMINEE': 'Terminée', 'ANNULEE': 'Annulée'};

class Seance {
  const Seance({required this.id, required this.debut, required this.fin, this.lieu, this.capacite, this.placesRestantes, required this.statut});
  final int id;
  final DateTime? debut;
  final DateTime? fin;
  final String? lieu;
  final int? capacite;
  final int? placesRestantes;
  final String statut;

  bool get ouverte => statut == 'PLANIFIEE' && (debut?.isAfter(DateTime.now().toUtc()) ?? false);
  bool get complete => placesRestantes != null && placesRestantes! <= 0;

  factory Seance.lire(Json j) => Seance(
        id: _i(j['id']),
        debut: _d(j['dateDebut']),
        fin: _d(j['dateFin']),
        lieu: _sn(j['lieu']),
        capacite: _in(j['capaciteMax']),
        placesRestantes: _in(j['placesRestantes']),
        statut: _s(j['statut']),
      );
}

class Formation {
  const Formation({required this.id, required this.titre, required this.slug, required this.description, required this.niveau, this.prerequis, this.objectifs, this.formateur, this.categorie, this.seances = const []});
  final int id;
  final String titre;
  final String slug;
  final String description;
  final String niveau;
  final String? prerequis;
  final String? objectifs;
  final String? formateur;
  final String? categorie;
  final List<Seance> seances;

  String get niveauAffiche => libellesDesNiveaux[niveau] ?? niveau;

  factory Formation.lire(Json j) => Formation(
        id: _i(j['id']),
        titre: _s(j['titre']),
        slug: _s(j['slug']),
        description: _s(j['description']),
        niveau: _s(j['niveau']),
        prerequis: _sn(j['prerequis']),
        objectifs: _sn(j['objectifs']),
        formateur: _sn(j['formateurNom']),
        categorie: _sn(j['categorieNom']),
        seances: (j['sessions'] is List ? j['sessions'] as List : const []).whereType<Map>().map((e) => Seance.lire(Json.from(e))).toList(),
      );
}

const libellesDesProjets = {'PROPOSE': 'En attente de validation', 'VALIDE': 'Validé', 'REJETE': 'Rejeté', 'EN_COURS': 'En cours', 'TERMINE': 'Terminé'};

class Projet {
  const Projet({required this.id, required this.titre, required this.slug, required this.description, required this.statut, this.objectifs, this.technologies, this.depot, this.porteur, this.motif, this.suivi, this.avancement, this.categorie, this.membres = const [], this.creeLe});
  final int id;
  final String titre;
  final String slug;
  final String description;
  final String statut;
  final String? objectifs;
  final String? technologies;
  final String? depot;
  final String? porteur;
  final String? motif;
  final String? suivi;
  final int? avancement;
  final String? categorie;
  final List<String> membres;
  final DateTime? creeLe;

  String get statutAffiche => libellesDesProjets[statut] ?? statut;
  List<String> get technos => (technologies ?? '').split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory Projet.lire(Json j) => Projet(
        id: _i(j['id']),
        titre: _s(j['titre']),
        slug: _s(j['slug']),
        description: _s(j['description']),
        statut: _s(j['statut']),
        objectifs: _sn(j['objectifs']),
        technologies: _sn(j['technologies']),
        depot: _sn(j['depotGit']),
        porteur: _sn(j['porteurNom']),
        motif: _sn(j['motifDecision']),
        suivi: _sn(j['suiviFormateur']),
        avancement: _in(j['avancementPourcentage']),
        categorie: _sn(j['categorieNom']),
        membres: (j['membres'] is List ? j['membres'] as List : const []).whereType<Map>().map((e) => _s(e['utilisateurNom'])).where((e) => e.isNotEmpty).toList(),
        creeLe: _d(j['createdAt']),
      );
}

const libellesDesRessources = {'DOCUMENT_PDF': 'Document', 'SUPPORT_COURS': 'Support de cours', 'LIEN_EXTERNE': 'Lien externe', 'VIDEO': 'Vidéo', 'CODE_SOURCE': 'Code source'};

class Ressource {
  const Ressource({required this.id, required this.titre, this.description, required this.type, required this.url, this.formation, this.auteur});
  final int id;
  final String titre;
  final String? description;
  final String type;
  final String url;
  final String? formation;
  final String? auteur;

  String get typeAffiche => libellesDesRessources[type] ?? type;

  factory Ressource.lire(Json j) => Ressource(
        id: _i(j['id']),
        titre: _s(j['titre']),
        description: _sn(j['description']),
        type: _s(j['type']),
        url: _s(j['urlFichier']),
        formation: _sn(j['formationTitre']),
        auteur: _sn(j['auteurNom']),
      );
}

class Devoir {
  const Devoir({required this.id, required this.titre, this.description, this.limite, this.consigne});
  final int id;
  final String titre;
  final String? description;
  final DateTime? limite;
  final String? consigne;

  factory Devoir.lire(Json j) => Devoir(id: _i(j['id']), titre: _s(j['titre']), description: _sn(j['description']), limite: _d(j['dateLimite']), consigne: _sn(j['fichierConsigne']));
}

const libellesDesInscriptions = {'CONFIRMEE': 'Inscription confirmée', 'LISTE_ATTENTE': 'Liste d’attente', 'ANNULEE': 'Annulée'};

class Inscription {
  const Inscription({required this.id, required this.statut, this.evenementId, this.evenementTitre, this.evenementSlug, this.seanceId, this.formationId, this.formationTitre, this.formationSlug, this.lieu, this.debut, this.fin});
  final int id;
  final String statut;
  final int? evenementId;
  final String? evenementTitre;
  final String? evenementSlug;
  final int? seanceId;
  final int? formationId;
  final String? formationTitre;
  final String? formationSlug;
  final String? lieu;
  final DateTime? debut;
  final DateTime? fin;

  bool get pourEvenement => evenementId != null;
  bool get active => statut != 'ANNULEE';
  bool get aVenir => (fin ?? debut)?.isAfter(DateTime.now().toUtc()) ?? true;
  String get titre => (pourEvenement ? evenementTitre : formationTitre) ?? '';
  String get statutAffiche => libellesDesInscriptions[statut] ?? statut;

  factory Inscription.lire(Json j) => Inscription(
        id: _i(j['id']),
        statut: _s(j['statut']),
        evenementId: _in(j['evenementId']),
        evenementTitre: _sn(j['evenementTitre']),
        evenementSlug: _sn(j['evenementSlug']),
        seanceId: _in(j['sessionFormationId']),
        formationId: _in(j['formationId']),
        formationTitre: _sn(j['formationTitre']),
        formationSlug: _sn(j['formationSlug']),
        lieu: _sn(j['lieu']),
        debut: _d(j['dateDebut']),
        fin: _d(j['dateFin']),
      );
}

const libellesDesNotifications = {'MESSAGE_GLOBAL': 'Annonce', 'INSCRIPTION': 'Inscription', 'VALIDATION_PROJET': 'Projet', 'RAPPEL_SESSION': 'Rappel', 'SYSTEME': 'Système'};

class NotificationRecue {
  const NotificationRecue({required this.id, required this.titre, required this.message, required this.type, this.lien, required this.lue, this.date});
  final int id;
  final String titre;
  final String message;
  final String type;
  final String? lien;
  final bool lue;
  final DateTime? date;

  String get typeAffiche => libellesDesNotifications[type] ?? 'Notification';

  factory NotificationRecue.lire(Json j) =>
      NotificationRecue(id: _i(j['id']), titre: _s(j['titre']), message: _s(j['message']), type: _s(j['type']), lien: _sn(j['lien']), lue: j['lue'] == true, date: _d(j['createdAt']));
}

const libellesDesComptes = {'ACTIF': 'Compte actif', 'INACTIF': 'Compte inactif', 'SUSPENDU': 'Compte suspendu', 'EN_ATTENTE_ACTIVATION': 'En attente d’activation'};

class Profil {
  const Profil({required this.id, required this.nom, required this.prenom, required this.email, this.filiere, this.biographie, this.numeroMembre, this.adhesion, required this.statut, this.photo});
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? filiere;
  final String? biographie;
  final String? numeroMembre;
  final DateTime? adhesion;
  final String statut;
  final String? photo;

  factory Profil.lire(Json j) => Profil(
        id: _i(j['id']),
        nom: _s(j['nom']),
        prenom: _s(j['prenom']),
        email: _s(j['email']),
        filiere: _sn(j['filiere']),
        biographie: _sn(j['biographie']),
        numeroMembre: _sn(j['numeroMembre']),
        adhesion: _d(j['dateAdhesion']),
        statut: _s(j['statut']),
        photo: _sn(j['photo']),
      );
}

class MembreBureau {
  const MembreBureau({required this.nom, required this.prenom, required this.fonction, this.filiere});
  final String nom;
  final String prenom;
  final String fonction;
  final String? filiere;

  factory MembreBureau.lire(Json j) => MembreBureau(nom: _s(j['nom']), prenom: _s(j['prenom']), fonction: _s(j['fonction']), filiere: _sn(j['filiere']));
}

class Categorie {
  const Categorie({required this.id, required this.nom});
  final int id;
  final String nom;
  factory Categorie.lire(Json j) => Categorie(id: _i(j['id']), nom: _s(j['nom']));
}
