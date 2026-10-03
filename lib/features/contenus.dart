import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_error.dart';
import '../core/api/club_api.dart';
import '../core/api/models.dart';
import '../core/auth/session.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/liste_paginee.dart';
import '../ui/widgets.dart';
import 'activites.dart';
import 'cartes.dart';

/// Ouvre une adresse hors de l'application. Seules les adresses web sont acceptées.
Future<void> ouvrirLien(BuildContext context, String adresse) async {
  final uri = Uri.tryParse(adresse.trim());
  final admis = uri != null && (uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'mailto');
  if (!admis || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) afficherMessage(context, 'Ce lien ne peut pas être ouvert.');
  }
}

// ───────────────────────── Actualités ─────────────────────────

class PageActualites extends StatelessWidget {
  const PageActualites({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    final connecte = context.watch<Session>().connecte;
    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      body: ListePaginee<Actualite>(
        key: ValueKey(connecte),
        charger: (page) => connecte ? api.publications(page: page) : api.actualites(page: page),
        messageVide: 'Aucune actualité publiée pour le moment.',
        iconeVide: LucideIcons.newspaper,
        hauteurSquelette: 140,
        element: (context, a, _) => CarteActualite(a),
      ),
    );
  }
}

class PageActualite extends StatelessWidget {
  const PageActualite(this.slug, {super.key});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    final connecte = context.watch<Session>().connecte;
    return Scaffold(
      appBar: AppBar(title: const Text('Actualité')),
      body: Chargement<Actualite>(
        key: ValueKey(connecte),
        charger: () => connecte ? api.publication(slug) : api.actualite(slug),
        contenu: (context, a, _) => ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (a.categorie != null) Etiquette(a.categorie!, ton: Ton.accent),
            if (a.reserveeAuxMembres) const Etiquette('Réservé aux membres', ton: Ton.ambre, icone: LucideIcons.lock),
          ]),
          const SizedBox(height: 12),
          Text(a.titre, style: context.textes.headlineMedium),
          const SizedBox(height: 10),
          Text([if (a.date != null) dateSimple(a.date), ?a.auteur].join(' · '), style: context.textes.bodySmall),
          const SizedBox(height: 20),
          if (a.resume != null) ...[Text(a.resume!, style: context.textes.bodyLarge?.copyWith(color: context.palette.texte, fontWeight: FontWeight.w600)), const SizedBox(height: 16)],
          TexteRedige(a.contenu),
        ]),
      ),
    );
  }
}

// ───────────────────────── Projets ─────────────────────────

/// Onglet Projets : réalisations des membres ; un membre y propose le sien.
class PageProjets extends StatelessWidget {
  const PageProjets({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    final session = context.watch<Session>();
    final membre = session.utilisateur?.estMembre ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
        actions: [if (membre) TextButton(onPressed: () => context.push('/espace/projets'), child: const Text('Mes projets')), const SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Charte.ambre,
        foregroundColor: Charte.bleuNuit,
        onPressed: () {
          if (!session.connecte) {
            demanderConnexion(context, 'Connectez-vous pour proposer un projet au club.');
          } else if (membre) {
            context.push('/espace/projets/proposer');
          } else {
            afficherMessage(context, 'La proposition de projet est réservée aux membres.');
          }
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Proposer', style: TextStyle(fontFamily: Charte.titres, fontWeight: FontWeight.w700)),
      ),
      body: ListePaginee<Projet>(
        charger: (page) => api.projets(page: page),
        messageVide: 'Aucun projet publié pour le moment.',
        iconeVide: LucideIcons.layers,
        hauteurSquelette: 170,
        element: (context, p, _) => CarteProjet(p),
      ),
    );
  }
}

class PageProjet extends StatelessWidget {
  const PageProjet(this.slug, {super.key});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Projet')),
      body: Chargement<Projet>(
        charger: () => api.projet(slug),
        contenu: (context, p, _) {
          final palette = context.palette;
          return ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
            Wrap(spacing: 8, runSpacing: 6, children: [Etiquette(p.statutAffiche, ton: tonDuProjet(p.statut)), if (p.categorie != null) Etiquette(p.categorie!, ton: Ton.accent)]),
            const SizedBox(height: 12),
            Text(p.titre, style: context.textes.headlineMedium),
            if (p.porteur != null) ...[const SizedBox(height: 10), LigneInfo(LucideIcons.user, 'Porté par ${p.porteur}')],
            if (p.avancement != null && (p.statut == 'EN_COURS' || p.statut == 'TERMINE')) ...[
              const SizedBox(height: 18),
              Carte(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text('Avancement', style: context.textes.titleSmall)), Text('${p.avancement} %', style: context.textes.titleMedium?.copyWith(color: palette.accent))]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: p.avancement! / 100, minHeight: 9, backgroundColor: palette.surfaceHaute, color: palette.accent)),
                  if (p.suivi != null) ...[const SizedBox(height: 12), Text(p.suivi!, style: context.textes.bodyMedium)],
                ]),
              ),
            ],
            const SizedBox(height: 20),
            TexteRedige(p.description),
            if (p.objectifs != null) ...[Text('Objectifs', style: context.textes.titleLarge), const SizedBox(height: 10), TexteRedige(p.objectifs)],
            if (p.technos.isNotEmpty) ...[
              Text('Technologies', style: context.textes.titleLarge),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in p.technos) Etiquette(t)]),
              const SizedBox(height: 20),
            ],
            if (p.membres.isNotEmpty) ...[
              Text('Équipe', style: context.textes.titleLarge),
              const SizedBox(height: 10),
              for (final m in p.membres) Padding(padding: const EdgeInsets.only(bottom: 6), child: LigneInfo(LucideIcons.user, m)),
              const SizedBox(height: 14),
            ],
            if (p.depot != null) OutlinedButton.icon(onPressed: () => ouvrirLien(context, p.depot!), icon: const Icon(LucideIcons.code, size: 18), label: const Text('Voir le dépôt du code')),
          ]);
        },
      ),
    );
  }
}

class PageMesProjets extends StatelessWidget {
  const PageMesProjets({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes projets')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Charte.ambre,
        foregroundColor: Charte.bleuNuit,
        onPressed: () => context.push('/espace/projets/proposer'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Proposer', style: TextStyle(fontFamily: Charte.titres, fontWeight: FontWeight.w700)),
      ),
      body: Chargement<List<Projet>>(
        charger: () => api.mesProjets().then((p) => p.contenu),
        estVide: (l) => l.isEmpty,
        vide: const EtatVide(icone: LucideIcons.layers, message: 'Vous n’avez encore proposé aucun projet.'),
        contenu: (context, projets, _) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(marge, 8, marge, 96),
          itemCount: projets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => CarteProjet(projets[i], personnel: true),
        ),
      ),
    );
  }
}

class PageProposerProjet extends StatefulWidget {
  const PageProposerProjet({super.key});

  @override
  State<PageProposerProjet> createState() => _PageProposerProjetState();
}

class _PageProposerProjetState extends State<PageProposerProjet> {
  final _formulaire = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _description = TextEditingController();
  final _objectifs = TextEditingController();
  final _technologies = TextEditingController();
  final _depot = TextEditingController();
  List<Categorie> _categories = const [];
  int? _categorie;
  bool _envoi = false;
  String? _erreur;
  Map<String, String> _champs = const {};

  @override
  void initState() {
    super.initState();
    context.read<ClubApi>().categories().then((c) => mounted ? setState(() => _categories = c) : null).catchError((_) => null);
  }

  @override
  void dispose() {
    for (final c in [_titre, _description, _objectifs, _technologies, _depot]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() { _erreur = null; _champs = const {}; });
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await context.read<ClubApi>().proposerProjet(
            titre: _titre.text.trim(),
            description: _description.text.trim(),
            objectifs: _objectifs.text.trim(),
            technologies: _technologies.text.trim(),
            depotGit: _depot.text.trim().isEmpty ? null : _depot.text.trim(),
            categorieId: _categorie,
          );
      if (!mounted) return;
      afficherMessage(context, 'Votre proposition est envoyée au bureau du club.');
      context.pushReplacement('/espace/projets');
    } catch (e) {
      final erreur = ErreurApi.depuis(e);
      if (mounted) setState(() { _erreur = erreur.champs.isEmpty ? erreur.message : null; _champs = erreur.champs; _envoi = false; });
      _formulaire.currentState?.validate();
    }
  }

  String? _requis(String? v, String champ, {int min = 2}) => _champs[champ] ?? ((v ?? '').trim().length < min ? 'Ce champ est obligatoire.' : null);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Proposer un projet')),
        body: Form(
          key: _formulaire,
          child: ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
            Text('Décrivez votre idée. Le Responsable du Club l’examine, puis vous recevez sa décision par notification.', style: context.textes.bodyLarge),
            const SizedBox(height: 20),
            Alerte(_erreur),
            TextFormField(controller: _titre, maxLength: 200, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Titre du projet *', counterText: ''), validator: (v) => _requis(v, 'titre', min: 3)),
            const SizedBox(height: 14),
            TextFormField(controller: _description, minLines: 4, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Description *', alignLabelWithHint: true), validator: (v) => _requis(v, 'description', min: 10)),
            const SizedBox(height: 14),
            TextFormField(controller: _objectifs, minLines: 3, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Objectifs *', alignLabelWithHint: true), validator: (v) => _requis(v, 'objectifs')),
            const SizedBox(height: 14),
            TextFormField(controller: _technologies, decoration: const InputDecoration(labelText: 'Technologies *', helperText: 'Séparées par des virgules : Flutter, Java, PostgreSQL'), validator: (v) => _requis(v, 'technologies')),
            const SizedBox(height: 14),
            if (_categories.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                initialValue: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [const DropdownMenuItem(value: null, child: Text('Sans catégorie')), for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.nom, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _categorie = v),
                isExpanded: true,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _depot,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Dépôt du code (facultatif)', hintText: 'https://github.com/…'),
              validator: (v) => _champs['depotGit'] ?? ((v ?? '').trim().isNotEmpty && !RegExp(r'^https?://').hasMatch(v!.trim()) ? 'L’adresse doit commencer par https://' : null),
            ),
            const SizedBox(height: 24),
            BoutonPrincipal(libelle: 'Envoyer la proposition', enCours: _envoi, onPressed: _envoyer, icone: LucideIcons.send),
          ]),
        ),
      );
}

// ───────────────────────── Notifications ─────────────────────────

/// Adresse de l'application correspondant au lien d'une notification ; nul si la page n'existe que sur le site.
String? routeDeNotification(String lien) {
  if (lien == '/evenements' || lien == '/formations') return '/activites';
  if (lien == '/projets') return '/projets';
  const connues = ['/evenements/', '/formations/', '/projets/', '/actualites/'];
  if (connues.any(lien.startsWith) || lien == '/actualites') return lien;
  if (lien == '/espace/projets' || lien == '/espace/supports' || lien == '/espace/inscriptions') return lien;
  return null;
}

class PageNotifications extends StatefulWidget {
  const PageNotifications({super.key});

  @override
  State<PageNotifications> createState() => _PageNotificationsState();
}

class _PageNotificationsState extends State<PageNotifications> {
  bool _nonLuesSeulement = false;
  int _version = 0;

  Future<void> _ouvrir(NotificationRecue n, Future<void> Function() recharger) async {
    final api = context.read<ClubApi>();
    final session = context.read<Session>();
    if (!n.lue) {
      try {
        await api.marquerLue(n.id);
        session.actualiserNonLues();
        recharger();
      } catch (_) {
        // L'ouverture du lien prime sur le marquage.
      }
    }
    if (!mounted || n.lien == null) return;
    final route = routeDeNotification(n.lien!);
    if (route == null) {
      ouvrirLien(context, n.lien!.startsWith('http') ? n.lien! : '$origineDuSite${n.lien}');
    } else if (route == '/activites' || route == '/projets') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final api = context.read<ClubApi>();
    if (!session.connecte) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: EtatVide(
            icone: LucideIcons.bell,
            message: 'Connectez-vous pour recevoir les annonces du club, les rappels de vos séances et les décisions sur vos projets.',
            action: 'Se connecter',
            onAction: () => context.push('/connexion'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (session.nonLues > 0)
            TextButton(
              onPressed: () async {
                try {
                  await api.toutMarquerLu();
                  await session.actualiserNonLues();
                  if (mounted) setState(() => _version++);
                } catch (e) {
                  if (context.mounted) afficherMessage(context, ErreurApi.depuis(e).message);
                }
              },
              child: const Text('Tout marquer lu'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListePaginee<NotificationRecue>(
        key: ValueKey('$_nonLuesSeulement-$_version'),
        charger: (page) {
          session.actualiserNonLues();
          return api.notifications(page: page, lue: _nonLuesSeulement ? false : null);
        },
        messageVide: _nonLuesSeulement ? 'Aucune notification non lue.' : 'Vous n’avez aucune notification.',
        iconeVide: LucideIcons.bell,
        hauteurSquelette: 92,
        entete: Padding(
          padding: const EdgeInsets.fromLTRB(marge, 4, marge, 12),
          child: Row(children: [
            ChoiceChip(label: const Text('Toutes'), selected: !_nonLuesSeulement, onSelected: (_) => setState(() => _nonLuesSeulement = false)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Non lues'), selected: _nonLuesSeulement, onSelected: (_) => setState(() => _nonLuesSeulement = true)),
          ]),
        ),
        element: (context, n, recharger) => _CarteNotification(n, onTap: () => _ouvrir(n, recharger)),
      ),
    );
  }
}

class _CarteNotification extends StatelessWidget {
  const _CarteNotification(this.notification, {required this.onTap});
  final NotificationRecue notification;
  final VoidCallback onTap;

  static IconData _icone(String type) => switch (type) {
        'INSCRIPTION' => LucideIcons.calendarCheck,
        'VALIDATION_PROJET' => LucideIcons.layers,
        'RAPPEL_SESSION' => LucideIcons.clock,
        'MESSAGE_GLOBAL' => LucideIcons.volume2,
        _ => LucideIcons.bell,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    return Carte(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: (n.lue ? p.texteDiscret : p.accent).withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
          child: Icon(_icone(n.type), size: 18, color: n.lue ? p.texteDiscret : p.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleSmall?.copyWith(fontWeight: n.lue ? FontWeight.w600 : FontWeight.w700))),
              if (!n.lue) Container(width: 9, height: 9, margin: const EdgeInsets.only(left: 8), decoration: const BoxDecoration(color: Charte.ambre, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(n.message, style: context.textes.bodyMedium),
            const SizedBox(height: 8),
            Row(children: [
              Text('${n.typeAffiche} · ${ilYA(n.date)}', style: context.textes.bodySmall),
              const Spacer(),
              if (n.lien != null) Icon(LucideIcons.chevronRight, size: 16, color: p.texteDiscret),
            ]),
          ]),
        ),
      ]),
    );
  }
}
