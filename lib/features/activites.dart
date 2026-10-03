import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/api/api_error.dart';
import '../core/api/club_api.dart';
import '../core/api/models.dart';
import '../core/auth/session.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/liste_paginee.dart';
import '../ui/widgets.dart';
import 'cartes.dart';

/// Onglet Activités : événements et formations, par segments.
class PageActivites extends StatefulWidget {
  const PageActivites({super.key});

  @override
  State<PageActivites> createState() => _PageActivitesState();
}

class _PageActivitesState extends State<PageActivites> {
  int _segment = 0;
  bool _aVenir = true;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Activités')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(marge, 4, marge, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Événements'), icon: Icon(LucideIcons.calendar, size: 16)),
                ButtonSegment(value: 1, label: Text('Formations'), icon: Icon(LucideIcons.graduationCap, size: 16)),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
        ),
        Expanded(
          child: _segment == 0
              ? ListePaginee<Evenement>(
                  key: ValueKey('evenements-$_aVenir'),
                  charger: (page) => api.evenements(page: page, aVenir: _aVenir),
                  messageVide: _aVenir ? 'Aucun événement à venir pour le moment.' : 'Aucun événement passé.',
                  iconeVide: LucideIcons.calendar,
                  entete: Padding(
                    padding: const EdgeInsets.fromLTRB(marge, 0, marge, 12),
                    child: Row(children: [
                      ChoiceChip(label: const Text('À venir'), selected: _aVenir, onSelected: (_) => setState(() => _aVenir = true)),
                      const SizedBox(width: 8),
                      ChoiceChip(label: const Text('Passés'), selected: !_aVenir, onSelected: (_) => setState(() => _aVenir = false)),
                    ]),
                  ),
                  element: (context, e, _) => CarteEvenement(e),
                )
              : ListePaginee<Formation>(
                  key: const ValueKey('formations'),
                  charger: (page) => api.formations(page: page),
                  messageVide: 'Aucune formation publiée pour le moment.',
                  iconeVide: LucideIcons.graduationCap,
                  hauteurSquelette: 170,
                  element: (context, f, _) => CarteFormation(f),
                ),
        ),
      ]),
    );
  }
}

/// Demande de connexion avant une action réservée aux membres.
Future<void> demanderConnexion(BuildContext context, String raison) => showModalBottomSheet<void>(
      context: context,
      builder: (feuille) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Connexion requise', style: feuille.textes.headlineSmall),
            const SizedBox(height: 8),
            Text(raison, style: feuille.textes.bodyLarge),
            const SizedBox(height: 20),
            BoutonPrincipal(
              libelle: 'Se connecter',
              onPressed: () {
                Navigator.pop(feuille);
                context.push('/connexion');
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(feuille);
                  context.push('/inscription');
                },
                child: const Text('Créer un compte'),
              ),
            ),
          ]),
        ),
      ),
    );

Future<bool> confirmer(BuildContext context, {required String titre, required String message, required String action, bool danger = false}) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(titre, style: d.textes.titleLarge),
        content: Text(message, style: d.textes.bodyLarge),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annuler')),
          FilledButton(
            style: danger ? FilledButton.styleFrom(backgroundColor: Charte.danger, minimumSize: const Size(0, 44)) : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(d, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class _Fiche<T> {
  const _Fiche(this.element, this.inscriptions);
  final T element;
  final List<Inscription> inscriptions;
}

/// Barre d'action fixée en bas d'une fiche.
class _BarreAction extends StatelessWidget {
  const _BarreAction({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: context.palette.surface, border: Border(top: BorderSide(color: context.palette.trait))),
        child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(marge, 12, marge, 12), child: child)),
      );
}

// ───────────────────────── Événement ─────────────────────────

class PageEvenement extends StatefulWidget {
  const PageEvenement(this.slug, {super.key});
  final String slug;

  @override
  State<PageEvenement> createState() => _PageEvenementState();
}

class _PageEvenementState extends State<PageEvenement> {
  final _zone = GlobalKey<ChargementState<_Fiche<Evenement>>>();
  bool _envoi = false;

  Future<_Fiche<Evenement>> _charger() async {
    final api = context.read<ClubApi>();
    final connecte = context.read<Session>().connecte;
    final resultats = await Future.wait<Object>([
      api.evenement(widget.slug),
      connecte ? api.mesInscriptions().then((p) => p.contenu).catchError((_) => <Inscription>[]) : Future.value(<Inscription>[]),
    ]);
    return _Fiche(resultats[0] as Evenement, resultats[1] as List<Inscription>);
  }

  Future<void> _agir(Future<void> Function() action, String succes) async {
    setState(() => _envoi = true);
    try {
      await action();
      if (!mounted) return;
      afficherMessage(context, succes);
      await _zone.currentState?.recharger(discret: true);
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
      body: Chargement<_Fiche<Evenement>>(
        key: _zone,
        charger: _charger,
        squelette: const _SqueletteDeFiche(),
        contenu: (context, fiche, _) {
          final e = fiche.element;
          final inscription = fiche.inscriptions.where((i) => i.active && i.evenementId == e.id).firstOrNull;
          final places = etiquetteDesPlaces(e.placesRestantes, passe: e.passe);

          Widget? action;
          if (e.passe) {
            action = null;
          } else if (inscription != null) {
            action = Row(children: [
              Expanded(child: Etiquette(inscription.statutAffiche, ton: inscription.statut == 'CONFIRMEE' ? Ton.succes : Ton.ambre, icone: LucideIcons.check)),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _envoi
                    ? null
                    : () async {
                        if (await confirmer(context, titre: 'Annuler l’inscription', message: 'Souhaitez-vous annuler votre inscription à « ${e.titre} » ?', action: 'Annuler l’inscription', danger: true)) {
                          _agir(() => api.annulerInscription(inscription.id), 'Votre inscription est annulée.');
                        }
                      },
                child: const Text('Se désinscrire'),
              ),
            ]);
          } else {
            action = BoutonPrincipal(
              libelle: e.complet ? 'Rejoindre la liste d’attente' : 'S’inscrire',
              enCours: _envoi,
              onPressed: () => session.connecte
                  ? _agir(() async => api.inscrireEvenement(e.id), e.complet ? 'Vous êtes sur la liste d’attente.' : 'Votre inscription est enregistrée.')
                  : demanderConnexion(context, 'Connectez-vous pour vous inscrire à cet événement.'),
            );
          }

          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 24), children: [
                Wrap(spacing: 8, runSpacing: 6, children: [if (e.categorie != null) Etiquette(e.categorie!, ton: Ton.accent), ?places]),
                const SizedBox(height: 12),
                Text(e.titre, style: context.textes.headlineMedium),
                const SizedBox(height: 18),
                Carte(
                  child: Column(children: [
                    _Detail(LucideIcons.calendar, 'Date', dateLongue(e.debut)),
                    const Divider(height: 24),
                    _Detail(LucideIcons.clock, 'Horaire', plageHoraire(e.debut, e.fin)),
                    const Divider(height: 24),
                    _Detail(LucideIcons.mapPin, 'Lieu', e.lieu),
                    if (e.organisateur != null) ...[const Divider(height: 24), _Detail(LucideIcons.user, 'Organisé par', e.organisateur!)],
                  ]),
                ),
                const SizedBox(height: 22),
                Text('À propos', style: context.textes.titleLarge),
                const SizedBox(height: 10),
                TexteRedige(e.description),
              ]),
            ),
            if (action != null) _BarreAction(child: action),
          ]);
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.icone, this.libelle, this.valeur);
  final IconData icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
        child: Icon(icone, size: 18, color: p.accent),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(libelle, style: context.textes.labelMedium),
          const SizedBox(height: 2),
          Text(valeur, style: context.textes.bodyLarge?.copyWith(color: p.texte, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}

class _SqueletteDeFiche extends StatelessWidget {
  const _SqueletteDeFiche();

  @override
  Widget build(BuildContext context) => ListView(physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(marge), children: const [
        Squelette(hauteur: 22, largeur: 120),
        SizedBox(height: 14),
        Squelette(hauteur: 34),
        SizedBox(height: 20),
        Squelette(hauteur: 190, rayon: 18),
        SizedBox(height: 24),
        Squelette(hauteur: 16),
        SizedBox(height: 10),
        Squelette(hauteur: 16),
        SizedBox(height: 10),
        Squelette(hauteur: 16, largeur: 220),
      ]);
}

// ───────────────────────── Formation ─────────────────────────

class PageFormation extends StatefulWidget {
  const PageFormation(this.slug, {super.key});
  final String slug;

  @override
  State<PageFormation> createState() => _PageFormationState();
}

class _PageFormationState extends State<PageFormation> {
  final _zone = GlobalKey<ChargementState<_Fiche<Formation>>>();
  int? _envoi;

  Future<_Fiche<Formation>> _charger() async {
    final api = context.read<ClubApi>();
    final connecte = context.read<Session>().connecte;
    final resultats = await Future.wait<Object>([
      api.formation(widget.slug),
      connecte ? api.mesInscriptions().then((p) => p.contenu).catchError((_) => <Inscription>[]) : Future.value(<Inscription>[]),
    ]);
    return _Fiche(resultats[0] as Formation, resultats[1] as List<Inscription>);
  }

  Future<void> _agir(int seance, Future<void> Function() action, String succes) async {
    setState(() => _envoi = seance);
    try {
      await action();
      if (!mounted) return;
      afficherMessage(context, succes);
      await _zone.currentState?.recharger(discret: true);
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoi = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final api = context.read<ClubApi>();
    return Scaffold(
      appBar: AppBar(title: const Text('Formation')),
      body: Chargement<_Fiche<Formation>>(
        key: _zone,
        charger: _charger,
        squelette: const _SqueletteDeFiche(),
        contenu: (context, fiche, _) {
          final f = fiche.element;
          final seances = [...f.seances]..sort((a, b) => (a.debut ?? DateTime(2100)).compareTo(b.debut ?? DateTime(2100)));
          final inscrit = fiche.inscriptions.any((i) => i.active && i.formationId == f.id);
          return ListView(padding: const EdgeInsets.fromLTRB(marge, 8, marge, 32), children: [
            Wrap(spacing: 8, runSpacing: 6, children: [Etiquette(f.niveauAffiche, ton: Ton.ambre), if (f.categorie != null) Etiquette(f.categorie!, ton: Ton.accent)]),
            const SizedBox(height: 12),
            Text(f.titre, style: context.textes.headlineMedium),
            if (f.formateur != null) ...[const SizedBox(height: 10), LigneInfo(LucideIcons.user, 'Animée par ${f.formateur}')],
            const SizedBox(height: 18),
            TexteRedige(f.description),
            if (f.objectifs != null) ...[Text('Objectifs', style: context.textes.titleLarge), const SizedBox(height: 10), TexteRedige(f.objectifs)],
            if (f.prerequis != null) ...[Text('Prérequis', style: context.textes.titleLarge), const SizedBox(height: 10), TexteRedige(f.prerequis)],
            if (inscrit) ...[
              OutlinedButton.icon(onPressed: () => context.push('/espace/supports'), icon: const Icon(LucideIcons.bookOpen, size: 18), label: const Text('Supports et devoirs')),
              const SizedBox(height: 22),
            ],
            Text('Séances', style: context.textes.titleLarge),
            const SizedBox(height: 12),
            if (seances.isEmpty)
              const Carte(child: Text('Aucune séance n’est planifiée pour le moment.'))
            else
              for (final s in seances)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CarteSeance(
                    seance: s,
                    inscription: fiche.inscriptions.where((i) => i.active && i.seanceId == s.id).firstOrNull,
                    enCours: _envoi == s.id,
                    bloque: _envoi != null,
                    onInscrire: () => session.connecte
                        ? _agir(s.id, () async => api.inscrireSeance(s.id), s.complete ? 'Vous êtes sur la liste d’attente.' : 'Votre inscription est enregistrée.')
                        : demanderConnexion(context, 'Connectez-vous pour vous inscrire à cette séance.'),
                    onAnnuler: (inscription) async {
                      if (await confirmer(context, titre: 'Annuler l’inscription', message: 'Souhaitez-vous annuler votre inscription à la séance du ${dateSimple(s.debut)} ?', action: 'Annuler l’inscription', danger: true)) {
                        _agir(s.id, () => api.annulerInscription(inscription.id), 'Votre inscription est annulée.');
                      }
                    },
                  ),
                ),
          ]);
        },
      ),
    );
  }
}

class _CarteSeance extends StatelessWidget {
  const _CarteSeance({required this.seance, required this.inscription, required this.enCours, required this.bloque, required this.onInscrire, required this.onAnnuler});
  final Seance seance;
  final Inscription? inscription;
  final bool enCours;
  final bool bloque;
  final VoidCallback onInscrire;
  final void Function(Inscription) onAnnuler;

  @override
  Widget build(BuildContext context) {
    final places = seance.ouverte ? etiquetteDesPlaces(seance.placesRestantes) : Etiquette(libellesDesSeances[seance.statut] ?? seance.statut);
    return Carte(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PastilleDate(seance.debut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dateLongue(seance.debut), style: context.textes.titleSmall),
              const SizedBox(height: 6),
              LigneInfo(LucideIcons.clock, plageHoraire(seance.debut, seance.fin)),
              if (seance.lieu != null) ...[const SizedBox(height: 4), LigneInfo(LucideIcons.mapPin, seance.lieu!)],
              if (places != null) ...[const SizedBox(height: 10), places],
            ]),
          ),
        ]),
        if (inscription != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Etiquette(inscription!.statutAffiche, ton: inscription!.statut == 'CONFIRMEE' ? Ton.succes : Ton.ambre, icone: LucideIcons.check)),
            const SizedBox(width: 10),
            TextButton(onPressed: bloque || !seance.ouverte ? null : () => onAnnuler(inscription!), child: const Text('Se désinscrire')),
          ]),
        ] else if (seance.ouverte) ...[
          const SizedBox(height: 14),
          BoutonPrincipal(libelle: seance.complete ? 'Rejoindre la liste d’attente' : 'S’inscrire à cette séance', enCours: enCours, onPressed: bloque ? null : onInscrire),
        ],
      ]),
    );
  }
}
