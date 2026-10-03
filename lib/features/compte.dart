import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/api/api_error.dart';
import '../core/api/club_api.dart';
import '../core/api/models.dart';
import '../core/auth/session.dart';
import '../core/config.dart';
import '../core/fichiers_io.dart' if (dart.library.js_interop) '../core/fichiers_web.dart';
import '../core/format.dart';
import '../core/preferences.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'activites.dart';
import 'contenus.dart';

class _Entree extends StatelessWidget {
  const _Entree(this.icone, this.titre, {this.sousTitre, required this.onTap, this.externe = false});
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final VoidCallback onTap;
  final bool externe;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = p.accent;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icone, size: 19, color: c)),
      title: Text(titre, style: context.textes.labelLarge?.copyWith(color: p.texte)),
      subtitle: sousTitre == null ? null : Text(sousTitre!, style: context.textes.bodySmall),
      trailing: Icon(externe ? LucideIcons.externalLink : LucideIcons.chevronRight, size: 17, color: p.texteDiscret),
    );
  }
}

class _Groupe extends StatelessWidget {
  const _Groupe(this.titre, this.entrees);
  final String titre;
  final List<Widget> entrees;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(marge, 22, marge, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(titre.toUpperCase(), style: context.textes.labelSmall?.copyWith(letterSpacing: 1.1))),
          Carte(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < entrees.length; i++) ...[if (i > 0) const Divider(indent: 72), entrees[i]],
            ]),
          ),
        ]),
      );
}

/// Onglet Compte : espace personnel du membre, ou invitation à se connecter.
class PageCompte extends StatelessWidget {
  const PageCompte({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final preferences = context.watch<Preferences>();
    final u = session.utilisateur;
    final p = context.palette;
    final gestion = u != null && u.roles.any((r) => r != 'MEMBRE');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(marge, 18, marge, 0),
            child: u == null
                ? Carte(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Votre espace', style: context.textes.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Connectez-vous pour vous inscrire aux activités, retrouver vos supports et proposer un projet.', style: context.textes.bodyLarge),
                      const SizedBox(height: 18),
                      BoutonPrincipal(libelle: 'Se connecter', onPressed: () => context.push('/connexion')),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.push('/inscription'), child: const Text('Créer un compte'))),
                    ]),
                  )
                : Row(children: [
                    Avatar(u.initiales, taille: 62),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.nomComplet, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.headlineSmall),
                        const SizedBox(height: 4),
                        Etiquette(u.roleAffiche, ton: Ton.ambre),
                      ]),
                    ),
                  ]),
          ),
          if (u != null && u.estMembre)
            _Groupe('Mon espace', [
              _Entree(LucideIcons.calendarCheck, 'Mes inscriptions', sousTitre: 'Événements et séances de formation', onTap: () => context.push('/espace/inscriptions')),
              _Entree(LucideIcons.bookOpen, 'Supports et devoirs', sousTitre: 'Documents de vos formations', onTap: () => context.push('/espace/supports')),
              _Entree(LucideIcons.layers, 'Mes projets', sousTitre: 'Propositions et suivi', onTap: () => context.push('/espace/projets')),
            ]),
          if (u != null)
            _Groupe('Mon compte', [
              _Entree(LucideIcons.user, 'Mon profil', onTap: () => context.push('/espace/profil')),
              _Entree(LucideIcons.key, 'Mot de passe', onTap: () => context.push('/espace/mot-de-passe')),
            ]),
          if (gestion)
            _Groupe('Gestion', [
              _Entree(LucideIcons.monitor, 'Espace de gestion', sousTitre: 'Formateur, bureau et administration : sur le site web', externe: true, onTap: () => ouvrirLien(context, '$origineDuSite/espace')),
            ]),
          _Groupe('Le club', [
            _Entree(LucideIcons.info, 'Qui sommes-nous', sousTitre: 'Présentation et bureau', onTap: () => context.push('/club')),
            _Entree(LucideIcons.newspaper, 'Actualités', onTap: () => context.push('/actualites')),
            _Entree(LucideIcons.mail, 'Nous contacter', onTap: () => context.push('/contact')),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(marge, 22, marge, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('APPARENCE', style: context.textes.labelSmall?.copyWith(letterSpacing: 1.1))),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Système'), icon: Icon(LucideIcons.smartphone, size: 15)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Clair'), icon: Icon(LucideIcons.sun, size: 15)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Sombre'), icon: Icon(LucideIcons.moon, size: 15)),
                  ],
                  selected: {preferences.theme},
                  onSelectionChanged: (s) => preferences.choisir(s.first),
                ),
              ),
            ]),
          ),
          _Groupe('Informations', [
            _Entree(LucideIcons.fileText, 'Mentions légales', externe: true, onTap: () => ouvrirLien(context, '$origineDuSite/mentions-legales')),
            _Entree(LucideIcons.shield, 'Confidentialité', externe: true, onTap: () => ouvrirLien(context, '$origineDuSite/confidentialite')),
            _Entree(LucideIcons.fileText, 'Conditions d’utilisation', externe: true, onTap: () => ouvrirLien(context, '$origineDuSite/conditions-utilisation')),
          ]),
          if (u != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(marge, 24, marge, 0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFCA5A5) : Charte.danger, side: BorderSide(color: Charte.danger.withValues(alpha: 0.45))),
                onPressed: () async {
                  if (await confirmer(context, titre: 'Se déconnecter', message: 'Souhaitez-vous fermer votre session sur cet appareil ?', action: 'Se déconnecter')) {
                    await session.deconnecter();
                    if (context.mounted) context.go('/');
                  }
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Se déconnecter'),
              ),
            ),
          Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: Text(Club.nom, style: context.textes.bodySmall?.copyWith(color: p.texteDiscret)))),
        ]),
      ),
    );
  }
}

// ───────────────────────── Mes inscriptions ─────────────────────────

class PageInscriptions extends StatelessWidget {
  const PageInscriptions({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes inscriptions')),
      body: Chargement<List<Inscription>>(
        charger: () => api.mesInscriptions().then((p) => p.contenu),
        estVide: (l) => l.isEmpty,
        vide: EtatVide(icone: LucideIcons.calendarCheck, message: 'Vous n’êtes inscrit à aucune activité.', action: 'Voir les activités', onAction: () => context.go('/activites')),
        contenu: (context, inscriptions, recharger) {
          final aVenir = inscriptions.where((i) => i.active && i.aVenir).toList()..sort((a, b) => (a.debut ?? DateTime(2100)).compareTo(b.debut ?? DateTime(2100)));
          final autres = inscriptions.where((i) => !(i.active && i.aVenir)).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
            if (aVenir.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('À venir', style: context.textes.titleLarge)),
              for (final i in aVenir) Padding(padding: const EdgeInsets.only(bottom: 12), child: _CarteInscription(i, recharger: recharger)),
            ],
            if (autres.isNotEmpty) ...[
              Padding(padding: EdgeInsets.only(top: aVenir.isEmpty ? 0 : 14, bottom: 10), child: Text('Passées ou annulées', style: context.textes.titleLarge)),
              for (final i in autres) Padding(padding: const EdgeInsets.only(bottom: 12), child: _CarteInscription(i, recharger: recharger)),
            ],
          ]);
        },
      ),
    );
  }
}

class _CarteInscription extends StatelessWidget {
  const _CarteInscription(this.inscription, {required this.recharger});
  final Inscription inscription;
  final Future<void> Function() recharger;

  @override
  Widget build(BuildContext context) {
    final i = inscription;
    final slug = i.pourEvenement ? i.evenementSlug : i.formationSlug;
    final annulable = i.active && i.aVenir;
    return Carte(
      onTap: slug == null ? null : () => context.push('/${i.pourEvenement ? 'evenements' : 'formations'}/$slug'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PastilleDate(i.debut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.pourEvenement ? 'ÉVÉNEMENT' : 'FORMATION', style: context.textes.labelSmall?.copyWith(color: context.palette.ambreTexte, letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(i.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
              const SizedBox(height: 6),
              LigneInfo(LucideIcons.clock, plageHoraire(i.debut, i.fin)),
              if (i.lieu != null) ...[const SizedBox(height: 4), LigneInfo(LucideIcons.mapPin, i.lieu!)],
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: Etiquette(i.statutAffiche, ton: switch (i.statut) { 'CONFIRMEE' => Ton.succes, 'LISTE_ATTENTE' => Ton.ambre, _ => Ton.neutre }))),
          if (annulable)
            TextButton(
              onPressed: () async {
                if (!await confirmer(context, titre: 'Annuler l’inscription', message: 'Souhaitez-vous annuler votre inscription à « ${i.titre} » ?', action: 'Annuler l’inscription', danger: true)) return;
                if (!context.mounted) return;
                try {
                  await context.read<ClubApi>().annulerInscription(i.id);
                  if (context.mounted) afficherMessage(context, 'Votre inscription est annulée.');
                  await recharger();
                } catch (e) {
                  if (context.mounted) afficherMessage(context, ErreurApi.depuis(e).message);
                }
              },
              child: const Text('Se désinscrire'),
            ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Supports et devoirs ─────────────────────────

class _Supports {
  const _Supports(this.formation, this.ressources, this.devoirs);
  final String formation;
  final List<Ressource> ressources;
  final List<Devoir> devoirs;
}

Future<void> ouvrirDocument(BuildContext context, String adresse, String titre) async {
  if (!ClubApi.estFichierDepose(adresse)) return ouvrirLien(context, adresse);
  afficherMessage(context, 'Téléchargement en cours…');
  try {
    final fichier = await context.read<ClubApi>().telecharger(adresse);
    final ouvert = await ouvrirOctets(fichier.octets, fichier.nom ?? titre, fichier.type);
    if (!ouvert && context.mounted) afficherMessage(context, 'Aucune application installée ne peut ouvrir ce fichier.');
  } catch (e) {
    if (context.mounted) afficherMessage(context, ErreurApi.depuis(e).message);
  }
}

class PageSupports extends StatelessWidget {
  const PageSupports({super.key});

  Future<List<_Supports>> _charger(ClubApi api) async {
    final inscriptions = (await api.mesInscriptions()).contenu.where((i) => i.active && i.formationId != null);
    final formations = {for (final i in inscriptions) i.formationId!: i.formationTitre ?? 'Formation'};
    return Future.wait(formations.entries.map((f) async {
      final resultats = await Future.wait<Object>([api.ressourcesDeFormation(f.key), api.devoirsDeFormation(f.key)]);
      return _Supports(f.value, resultats[0] as List<Ressource>, resultats[1] as List<Devoir>);
    }));
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Supports et devoirs')),
      body: Chargement<List<_Supports>>(
        charger: () => _charger(api),
        estVide: (l) => l.isEmpty,
        vide: EtatVide(
          icone: LucideIcons.bookOpen,
          message: 'Les supports apparaissent ici dès que vous êtes inscrit à une formation.',
          action: 'Voir les formations',
          onAction: () => context.go('/activites'),
        ),
        contenu: (context, formations, _) => ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
          for (final f in formations) ...[
            Padding(padding: const EdgeInsets.only(top: 8, bottom: 12), child: Text(f.formation, style: context.textes.titleLarge)),
            if (f.ressources.isEmpty && f.devoirs.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 12), child: Carte(child: Text('Aucun support ni devoir publié pour cette formation.'))),
            for (final r in f.ressources)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Carte(
                  onTap: () => ouvrirDocument(context, r.url, r.titre),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    _Pastille(switch (r.type) { 'VIDEO' => LucideIcons.monitor, 'LIEN_EXTERNE' => LucideIcons.externalLink, 'CODE_SOURCE' => LucideIcons.code, _ => LucideIcons.fileText }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleSmall),
                        const SizedBox(height: 3),
                        Text(r.typeAffiche, style: context.textes.bodySmall),
                      ]),
                    ),
                    Icon(LucideIcons.download, size: 18, color: context.palette.texteDiscret),
                  ]),
                ),
              ),
            for (final d in f.devoirs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Carte(
                  lisere: Charte.ambre,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Etiquette('Devoir', ton: Ton.ambre), const Spacer(), if (d.limite != null) Text('Pour le ${dateSimple(d.limite)}', style: context.textes.bodySmall)]),
                    const SizedBox(height: 10),
                    Text(d.titre, style: context.textes.titleSmall),
                    if (d.description != null) ...[const SizedBox(height: 6), Text(d.description!, style: context.textes.bodyMedium)],
                    if (d.consigne != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => ouvrirDocument(context, d.consigne!, d.titre), icon: const Icon(LucideIcons.fileText, size: 16), label: const Text('Ouvrir la consigne'))),
                    ],
                  ]),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.icone);
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(width: 42, height: 42, decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icone, size: 19, color: p.accent));
  }
}

// ───────────────────────── Profil ─────────────────────────

class PageProfil extends StatefulWidget {
  const PageProfil({super.key});

  @override
  State<PageProfil> createState() => _PageProfilState();
}

class _PageProfilState extends State<PageProfil> {
  final _formulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _filiere = TextEditingController();
  final _biographie = TextEditingController();
  Profil? _profil;
  Uint8List? _photo;
  bool? _courriel;
  ErreurApi? _erreurDeChargement;
  bool _envoi = false;
  bool _envoiPhoto = false;
  String? _erreur;
  Map<String, String> _champs = const {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _filiere, _biographie]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _erreurDeChargement = null);
    final api = context.read<ClubApi>();
    try {
      final profil = await api.profil();
      if (!mounted) return;
      _appliquer(profil);
      api.preferenceCourriel().then((v) => mounted ? setState(() => _courriel = v) : null).catchError((_) => null);
    } catch (e) {
      if (mounted) setState(() => _erreurDeChargement = ErreurApi.depuis(e));
    }
  }

  void _appliquer(Profil profil) {
    setState(() {
      _profil = profil;
      _nom.text = profil.nom;
      _prenom.text = profil.prenom;
      _filiere.text = profil.filiere ?? '';
      _biographie.text = profil.biographie ?? '';
      if (profil.photo == null) _photo = null;
    });
    if (profil.photo != null) {
      context.read<ClubApi>().telecharger(profil.photo!).then((f) => mounted ? setState(() => _photo = Uint8List.fromList(f.octets)) : null).catchError((_) => null);
    }
  }

  Future<void> _enregistrer() async {
    setState(() { _erreur = null; _champs = const {}; });
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final profil = await context.read<ClubApi>().modifierProfil(nom: _nom.text.trim(), prenom: _prenom.text.trim(), filiere: _filiere.text.trim(), biographie: _biographie.text.trim());
      if (!mounted) return;
      context.read<Session>().majIdentite(nom: profil.nom, prenom: profil.prenom);
      _appliquer(profil);
      afficherMessage(context, 'Votre profil est mis à jour.');
    } catch (e) {
      final erreur = ErreurApi.depuis(e);
      if (mounted) setState(() { _erreur = erreur.champs.isEmpty ? erreur.message : null; _champs = erreur.champs; });
      _formulaire.currentState?.validate();
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _changerPhoto() async {
    final choix = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 88);
    if (choix == null || !mounted) return;
    setState(() => _envoiPhoto = true);
    try {
      final octets = await choix.readAsBytes();
      final nom = choix.name.toLowerCase();
      final type = choix.mimeType ?? (nom.endsWith('.png') ? 'image/png' : nom.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      if (!mounted) return;
      final profil = await context.read<ClubApi>().deposerPhoto(octets, choix.name, type);
      if (!mounted) return;
      _appliquer(profil);
      afficherMessage(context, 'Votre photo est mise à jour.');
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoiPhoto = false);
    }
  }

  Future<void> _retirerPhoto() async {
    setState(() => _envoiPhoto = true);
    try {
      final profil = await context.read<ClubApi>().retirerPhoto();
      if (mounted) _appliquer(profil);
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoiPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = _profil;
    final session = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _erreurDeChargement != null
          ? Center(child: EtatErreur(erreur: _erreurDeChargement!, onReessayer: _charger))
          : profil == null
              ? const SqueletteDeListe(lignes: 5, hauteur: 64)
              : Form(
                  key: _formulaire,
                  child: ListView(padding: const EdgeInsets.fromLTRB(marge, 12, marge, 32), children: [
                    Center(
                      child: Stack(alignment: Alignment.center, children: [
                        Avatar(session.utilisateur?.initiales ?? '', taille: 104, image: _photo == null ? null : MemoryImage(_photo!)),
                        if (_envoiPhoto) const SizedBox(width: 104, height: 104, child: CircularProgressIndicator(strokeWidth: 3)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      TextButton.icon(onPressed: _envoiPhoto ? null : _changerPhoto, icon: const Icon(LucideIcons.image, size: 16), label: Text(_photo == null ? 'Ajouter une photo' : 'Changer la photo')),
                      if (profil.photo != null) TextButton(onPressed: _envoiPhoto ? null : _retirerPhoto, child: const Text('Retirer')),
                    ]),
                    const SizedBox(height: 8),
                    Carte(
                      child: Column(children: [
                        LigneInfo(LucideIcons.mail, profil.email),
                        if (profil.numeroMembre != null) ...[const SizedBox(height: 8), LigneInfo(LucideIcons.tag, 'Membre n° ${profil.numeroMembre}')],
                        if (profil.adhesion != null) ...[const SizedBox(height: 8), LigneInfo(LucideIcons.calendar, 'Adhésion le ${dateSimple(profil.adhesion)}')],
                        const SizedBox(height: 8),
                        LigneInfo(LucideIcons.userCheck, libellesDesComptes[profil.statut] ?? profil.statut),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Alerte(_erreur),
                    TextFormField(controller: _prenom, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Prénom *'), validator: (v) => _champs['prenom'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre prénom.' : null)),
                    const SizedBox(height: 14),
                    TextFormField(controller: _nom, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nom *'), validator: (v) => _champs['nom'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre nom.' : null)),
                    const SizedBox(height: 14),
                    TextFormField(controller: _filiere, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Filière'), validator: (_) => _champs['filiere']),
                    const SizedBox(height: 14),
                    TextFormField(controller: _biographie, minLines: 3, maxLines: 6, maxLength: 500, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Quelques mots sur vous', alignLabelWithHint: true), validator: (_) => _champs['biographie']),
                    const SizedBox(height: 12),
                    BoutonPrincipal(libelle: 'Enregistrer', enCours: _envoi, onPressed: _enregistrer),
                    if (_courriel != null) ...[
                      const SizedBox(height: 22),
                      Carte(
                        padding: EdgeInsets.zero,
                        child: SwitchListTile(
                          value: _courriel!,
                          title: Text('Notifications par courriel', style: context.textes.labelLarge),
                          subtitle: Text('Recevoir aussi les notifications du club par courriel.', style: context.textes.bodySmall),
                          onChanged: (v) async {
                            final avant = _courriel;
                            setState(() => _courriel = v);
                            try {
                              await context.read<ClubApi>().reglerPreferenceCourriel(v);
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _courriel = avant);
                              afficherMessage(context, ErreurApi.depuis(e).message);
                            }
                          },
                        ),
                      ),
                    ],
                  ]),
                ),
    );
  }
}

class PageMotDePasse extends StatefulWidget {
  const PageMotDePasse({super.key});

  @override
  State<PageMotDePasse> createState() => _PageMotDePasseState();
}

class _PageMotDePasseState extends State<PageMotDePasse> {
  final _formulaire = GlobalKey<FormState>();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _envoi = false;
  bool _visible = false;
  String? _erreur;
  Map<String, String> _champs = const {};

  @override
  void dispose() {
    for (final c in [_ancien, _nouveau, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() { _erreur = null; _champs = const {}; });
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await context.read<ClubApi>().changerMotDePasse(_ancien.text, _nouveau.text);
      if (!mounted) return;
      afficherMessage(context, 'Votre mot de passe est modifié.');
      context.pop();
    } catch (e) {
      final erreur = ErreurApi.depuis(e);
      if (mounted) setState(() { _erreur = erreur.champs.isEmpty ? erreur.message : null; _champs = erreur.champs; _envoi = false; });
      _formulaire.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final oeil = IconButton(onPressed: () => setState(() => _visible = !_visible), icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye, size: 19), tooltip: _visible ? 'Masquer' : 'Afficher');
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
      body: Form(
        key: _formulaire,
        child: ListView(padding: const EdgeInsets.fromLTRB(marge, 12, marge, 32), children: [
          Alerte(_erreur),
          TextFormField(controller: _ancien, obscureText: !_visible, autofillHints: const [AutofillHints.password], decoration: InputDecoration(labelText: 'Mot de passe actuel *', suffixIcon: oeil), validator: (v) => _champs['ancienMotDePasse'] ?? ((v ?? '').isEmpty ? 'Indiquez votre mot de passe actuel.' : null)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nouveau,
            obscureText: !_visible,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe *', helperText: '8 caractères au moins : minuscule, majuscule, chiffre et symbole.', helperMaxLines: 2),
            validator: (v) => _champs['nouveauMotDePasse'] ?? controlerMotDePasse(v ?? '') ?? (v == _ancien.text ? 'Le nouveau mot de passe doit être différent de l’actuel.' : null),
          ),
          const SizedBox(height: 14),
          TextFormField(controller: _confirmation, obscureText: !_visible, decoration: const InputDecoration(labelText: 'Confirmation *'), validator: (v) => v != _nouveau.text ? 'Les deux mots de passe ne sont pas identiques.' : null),
          const SizedBox(height: 24),
          BoutonPrincipal(libelle: 'Modifier le mot de passe', enCours: _envoi, onPressed: _envoyer),
        ]),
      ),
    );
  }
}

// ───────────────────────── Le club ─────────────────────────

class _LeClub {
  const _LeClub(this.texte, this.bureau);
  final String texte;
  final List<MembreBureau> bureau;
}

class PageClub extends StatelessWidget {
  const PageClub({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Qui sommes-nous')),
      body: Chargement<_LeClub>(
        charger: () async {
          final resultats = await Future.wait<Object>([api.texteDePage('presentation'), api.bureau().catchError((_) => <MembreBureau>[])]);
          return _LeClub(resultats[0] as String, resultats[1] as List<MembreBureau>);
        },
        contenu: (context, club, _) {
          final blocs = enBlocs(club.texte);
          final intro = blocs.takeWhile((b) => b.genre != GenreDeBloc.titre).toList();
          // Chaque titre ouvre une carte, comme sur le site.
          final sections = <(String, List<String>)>[];
          for (final b in blocs.skip(intro.length)) {
            if (b.genre == GenreDeBloc.titre) {
              sections.add((b.texte, <String>[]));
            } else if (sections.isNotEmpty) {
              sections.last.$2.add(b.texte);
            }
          }
          const couleurs = [Charte.bleuRoyal, Charte.ambre, Charte.cyan];
          const icones = [LucideIcons.target, LucideIcons.layers, LucideIcons.shield];
          return ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.asset('assets/img/logo-256.png', width: 104, height: 104))),
            const SizedBox(height: 18),
            Center(child: Text(Club.nom, textAlign: TextAlign.center, style: context.textes.headlineSmall)),
            const SizedBox(height: 4),
            Center(child: Text('${Club.institution} · ${Club.ville}', textAlign: TextAlign.center, style: context.textes.bodySmall)),
            const SizedBox(height: 22),
            if (blocs.isEmpty) const Carte(child: Text('La présentation du club est en cours de rédaction.')),
            for (final b in intro) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(b.texte, style: context.textes.bodyLarge?.copyWith(height: 1.65))),
            for (var i = 0; i < sections.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Carte(
                  lisere: couleurs[i % couleurs.length],
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [_Pastille(icones[i % icones.length]), const SizedBox(width: 12), Expanded(child: Text(sections[i].$1, style: context.textes.titleMedium))]),
                    for (final paragraphe in sections[i].$2) Padding(padding: const EdgeInsets.only(top: 10), child: Text(paragraphe, style: context.textes.bodyMedium?.copyWith(height: 1.6))),
                  ]),
                ),
              ),
            if (club.bureau.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 14, bottom: 12), child: Text('Le bureau', style: context.textes.titleLarge)),
              for (final m in club.bureau)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Carte(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Avatar('${m.prenom.isEmpty ? '' : m.prenom[0]}${m.nom.isEmpty ? '' : m.nom[0]}'.toUpperCase(), taille: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${m.prenom} ${m.nom}', style: context.textes.titleSmall),
                          const SizedBox(height: 2),
                          Text(m.fonction, style: context.textes.bodyMedium?.copyWith(color: context.palette.ambreTexte, fontWeight: FontWeight.w600)),
                          if (m.filiere != null) Text(m.filiere!, style: context.textes.bodySmall),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              OutlinedButton(onPressed: () => ouvrirLien(context, Club.whatsapp), child: const Text('WhatsApp')),
              OutlinedButton(onPressed: () => ouvrirLien(context, Club.linkedin), child: const Text('LinkedIn')),
              OutlinedButton(onPressed: () => ouvrirLien(context, Club.facebook), child: const Text('Facebook')),
              OutlinedButton(onPressed: () => ouvrirLien(context, Club.tiktok), child: const Text('TikTok')),
            ]),
          ]);
        },
      ),
    );
  }
}

// ───────────────────────── Contact ─────────────────────────

class PageContact extends StatefulWidget {
  const PageContact({super.key});

  @override
  State<PageContact> createState() => _PageContactState();
}

class _PageContactState extends State<PageContact> {
  final _formulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _sujet = TextEditingController();
  final _message = TextEditingController();
  final _ouverture = DateTime.now();
  bool _accord = false;
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;
  Map<String, String> _champs = const {};

  @override
  void initState() {
    super.initState();
    final u = context.read<Session>().utilisateur;
    if (u != null) {
      _nom.text = u.nomComplet;
      _email.text = u.email;
    }
  }

  @override
  void dispose() {
    for (final c in [_nom, _email, _sujet, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() { _erreur = null; _champs = const {}; });
    if (!_formulaire.currentState!.validate()) return;
    if (!_accord) return setState(() => _erreur = 'Votre accord est nécessaire pour envoyer le message.');
    setState(() => _envoi = true);
    try {
      await context.read<ClubApi>().contacter(nom: _nom.text.trim(), email: _email.text.trim(), sujet: _sujet.text.trim(), message: _message.text.trim(), dureeSaisieMs: DateTime.now().difference(_ouverture).inMilliseconds);
      if (mounted) setState(() => _envoye = true);
    } catch (e) {
      final erreur = ErreurApi.depuis(e);
      if (mounted) setState(() { _erreur = erreur.champs.isEmpty ? erreur.message : null; _champs = erreur.champs; });
      _formulaire.currentState?.validate();
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nous contacter')),
        body: _envoye
            ? Center(child: EtatVide(icone: LucideIcons.check, message: 'Votre message est envoyé. Le club vous répondra par courriel.', action: 'Retour', onAction: () => context.pop()))
            : Form(
                key: _formulaire,
                child: ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
                  Carte(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _Entree(LucideIcons.messageCircle, 'WhatsApp', sousTitre: Club.whatsappAffiche, externe: true, onTap: () => ouvrirLien(context, Club.whatsapp)),
                      const Divider(indent: 72),
                      _Entree(LucideIcons.mail, 'Courriel', sousTitre: Club.courriel, externe: true, onTap: () => ouvrirLien(context, 'mailto:${Club.courriel}')),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('Écrire au club', style: context.textes.titleLarge),
                  const SizedBox(height: 14),
                  Alerte(_erreur),
                  TextFormField(controller: _nom, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nom complet *'), validator: (v) => _champs['nom'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre nom.' : null)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Adresse électronique *'),
                    validator: (v) => _champs['email'] ?? (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch((v ?? '').trim()) ? 'Indiquez une adresse électronique valide.' : null),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(controller: _sujet, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Sujet *'), validator: (v) => _champs['sujet'] ?? ((v ?? '').trim().length < 3 ? 'Indiquez le sujet de votre message.' : null)),
                  const SizedBox(height: 14),
                  TextFormField(controller: _message, minLines: 5, maxLines: 10, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Message *', alignLabelWithHint: true), validator: (v) => _champs['message'] ?? ((v ?? '').trim().length < 10 ? 'Votre message est trop court.' : null)),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    value: _accord,
                    onChanged: (v) => setState(() => _accord = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text('J’accepte que ces informations soient utilisées pour répondre à ma demande.', style: context.textes.bodyMedium),
                  ),
                  const SizedBox(height: 12),
                  BoutonPrincipal(libelle: 'Envoyer le message', enCours: _envoi, onPressed: _envoyer, icone: LucideIcons.send),
                ]),
              ),
      );
}
