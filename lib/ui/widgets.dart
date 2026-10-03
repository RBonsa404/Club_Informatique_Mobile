import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api/api_error.dart';
import '../core/format.dart';
import '../core/theme.dart';

const marge = 20.0;

void afficherMessage(BuildContext context, String texte) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texte)));
}

/// Carte du club : surface, lisere, coins arrondis, retour tactile.
class Carte extends StatelessWidget {
  const Carte({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.lisere});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Couleur du lisere supérieur (repère de la maquette), absente par défaut.
  final Color? lisere;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.trait)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lisere != null) Container(height: 3, color: lisere),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

enum Ton { neutre, accent, ambre, succes, danger }

class Etiquette extends StatelessWidget {
  const Etiquette(this.texte, {super.key, this.ton = Ton.neutre, this.icone});
  final String texte;
  final Ton ton;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final couleur = switch (ton) {
      Ton.neutre => p.texteDiscret,
      Ton.accent => p.accent,
      Ton.ambre => p.ambreTexte,
      Ton.succes => Charte.succes,
      Ton.danger => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFCA5A5) : Charte.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(999), border: Border.all(color: couleur.withValues(alpha: 0.35))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 12.5, color: couleur), const SizedBox(width: 5)],
        Flexible(child: Text(texte, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Charte.corps, fontSize: 11.5, fontWeight: FontWeight.w700, color: couleur, height: 1.2))),
      ]),
    );
  }
}

/// Ligne d'information : pictogramme et texte.
class LigneInfo extends StatelessWidget {
  const LigneInfo(this.icone, this.texte, {super.key, this.couleur});
  final IconData icone;
  final String texte;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? context.palette.texteDiscret;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icone, size: 15, color: c)),
      const SizedBox(width: 8),
      Expanded(child: Text(texte, style: context.textes.bodyMedium?.copyWith(color: c, fontSize: 13.5))),
    ]);
  }
}

/// Pastille de date : jour et mois, comme sur les cartes d'événement du site.
class PastilleDate extends StatelessWidget {
  const PastilleDate(this.date, {super.key});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: p.accent.withValues(alpha: 0.3))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(jourDuMois(date), style: TextStyle(fontFamily: Charte.titres, fontSize: 20, fontWeight: FontWeight.w800, color: p.accent, height: 1.05)),
        Text(moisCourt(date), style: TextStyle(fontFamily: Charte.corps, fontSize: 10.5, fontWeight: FontWeight.w700, color: p.texteDiscret, letterSpacing: 0.6)),
      ]),
    );
  }
}

class TitreDeSection extends StatelessWidget {
  const TitreDeSection(this.titre, {super.key, this.action, this.onAction});
  final String titre;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(marge, 26, marge - 8, 10),
        child: Row(children: [
          Expanded(child: Text(titre, style: context.textes.titleLarge)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

/// Avatar neutre aux initiales : aucune photo inventée.
class Avatar extends StatelessWidget {
  const Avatar(this.initiales, {super.key, this.taille = 44, this.image});
  final String initiales;
  final double taille;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Charte.bleuRoyal, Charte.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
          image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: image != null ? null : Text(initiales, style: TextStyle(fontFamily: Charte.titres, fontSize: taille * 0.36, fontWeight: FontWeight.w700, color: Colors.white)),
      );
}

class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.icone, required this.message, this.action, this.onAction});
  final IconData icone;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: p.traitFort)),
          child: Icon(icone, size: 28, color: p.accent),
        ),
        const SizedBox(height: 18),
        Text(message, textAlign: TextAlign.center, style: context.textes.bodyLarge),
        if (action != null) ...[const SizedBox(height: 18), OutlinedButton(onPressed: onAction, child: Text(action!))],
      ]),
    );
  }
}

class EtatErreur extends StatelessWidget {
  const EtatErreur({super.key, required this.erreur, required this.onReessayer});
  final ErreurApi erreur;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => EtatVide(
        icone: erreur.nature == Nature.reseau ? LucideIcons.wifiOff : LucideIcons.circleAlert,
        message: erreur.message,
        action: 'Réessayer',
        onAction: onReessayer,
      );
}

/// Bloc gris animé affiché pendant un chargement : jamais de valeur provisoire.
class Squelette extends StatefulWidget {
  const Squelette({super.key, this.hauteur = 16, this.largeur, this.rayon = 10});
  final double hauteur;
  final double? largeur;
  final double rayon;

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette> with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_animation),
      child: Container(height: widget.hauteur, width: widget.largeur, decoration: BoxDecoration(color: p.surfaceHaute, borderRadius: BorderRadius.circular(widget.rayon))),
    );
  }
}

class SqueletteDeListe extends StatelessWidget {
  const SqueletteDeListe({super.key, this.lignes = 4, this.hauteur = 104});
  final int lignes;
  final double hauteur;

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(marge, 12, marge, 24),
        itemCount: lignes,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Squelette(hauteur: hauteur, rayon: 18),
      );
}

/// Zone de données : chargement, erreur, vide ou contenu, avec le geste « tirer pour actualiser ».
class Chargement<T> extends StatefulWidget {
  const Chargement({super.key, required this.charger, required this.contenu, this.estVide, this.vide, this.squelette});
  final Future<T> Function() charger;
  final Widget Function(BuildContext context, T donnees, Future<void> Function() recharger) contenu;
  final bool Function(T donnees)? estVide;
  final Widget? vide;
  final Widget? squelette;

  @override
  State<Chargement<T>> createState() => ChargementState<T>();
}

class ChargementState<T> extends State<Chargement<T>> {
  T? _donnees;
  ErreurApi? _erreur;
  bool _enCours = true;

  @override
  void initState() {
    super.initState();
    recharger();
  }

  Future<void> recharger({bool discret = false}) async {
    if (!discret) setState(() { _enCours = true; _erreur = null; });
    try {
      final donnees = await widget.charger();
      if (mounted) setState(() { _donnees = donnees; _enCours = false; _erreur = null; });
    } catch (e) {
      if (!mounted) return;
      // Un rafraîchissement manqué garde le contenu déjà affiché.
      if (discret && _donnees != null) {
        afficherMessage(context, ErreurApi.depuis(e).message);
      } else {
        setState(() { _erreur = ErreurApi.depuis(e); _enCours = false; });
      }
    }
  }

  Widget _defilable(Widget enfant) => LayoutBuilder(
        builder: (context, contraintes) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: contraintes.maxHeight), child: Center(child: enfant)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_enCours) return widget.squelette ?? const SqueletteDeListe();
    final donnees = _donnees;
    final Widget corps;
    if (_erreur != null) {
      corps = _defilable(EtatErreur(erreur: _erreur!, onReessayer: recharger));
    } else if (donnees == null || (widget.estVide?.call(donnees) ?? false)) {
      corps = _defilable(widget.vide ?? const EtatVide(icone: LucideIcons.inbox, message: 'Aucun contenu pour le moment.'));
    } else {
      corps = widget.contenu(context, donnees, () => recharger(discret: true));
    }
    return RefreshIndicator(onRefresh: () => recharger(discret: true), child: corps);
  }
}

/// Texte rédigé dans l'administration : paragraphes, titres et citations.
class TexteRedige extends StatelessWidget {
  const TexteRedige(this.texte, {super.key});
  final String? texte;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bloc in enBlocs(texte))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: switch (bloc.genre) {
              GenreDeBloc.titre => Padding(padding: const EdgeInsets.only(top: 6), child: Text(bloc.texte, style: context.textes.titleMedium)),
              GenreDeBloc.citation => Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Charte.ambre, width: 3)), color: p.surfaceHaute.withValues(alpha: 0.5)),
                  child: Text(bloc.texte, style: context.textes.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                ),
              GenreDeBloc.paragraphe => Text(bloc.texte, style: context.textes.bodyLarge?.copyWith(height: 1.65)),
            },
          ),
      ],
    );
  }
}

/// Bouton principal avec état d'attente.
class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({super.key, required this.libelle, required this.onPressed, this.enCours = false, this.icone});
  final String libelle;
  final VoidCallback? onPressed;
  final bool enCours;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enCours ? null : onPressed,
          child: enCours
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text(libelle, overflow: TextOverflow.ellipsis)), if (icone != null) ...[const SizedBox(width: 8), Icon(icone, size: 18)]]),
        ),
      );
}

/// Bandeau d'erreur d'un formulaire.
class Alerte extends StatelessWidget {
  const Alerte(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final sombre = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Charte.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Charte.danger.withValues(alpha: 0.4))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.circleAlert, size: 18, color: sombre ? const Color(0xFFFCA5A5) : Charte.danger),
        const SizedBox(width: 10),
        Expanded(child: Text(message!, style: context.textes.bodyMedium?.copyWith(color: sombre ? const Color(0xFFFECACA) : const Color(0xFF991B1B)))),
      ]),
    );
  }
}
