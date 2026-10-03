import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api/models.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';

/// Places restantes, telles que les donne le serveur. Sans capacité fixée, rien n'est affiché.
Widget? etiquetteDesPlaces(int? restantes, {bool passe = false}) {
  if (passe) return const Etiquette('Terminé');
  if (restantes == null) return null;
  if (restantes <= 0) return const Etiquette('Complet', ton: Ton.danger);
  return Etiquette(restantes == 1 ? '1 place restante' : '$restantes places restantes', ton: restantes <= 5 ? Ton.ambre : Ton.succes);
}

class CarteEvenement extends StatelessWidget {
  const CarteEvenement(this.evenement, {super.key});
  final Evenement evenement;

  @override
  Widget build(BuildContext context) {
    final places = etiquetteDesPlaces(evenement.placesRestantes, passe: evenement.passe);
    return Carte(
      onTap: () => context.push('/evenements/${evenement.slug}'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PastilleDate(evenement.debut),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(evenement.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
            const SizedBox(height: 8),
            LigneInfo(LucideIcons.clock, plageHoraire(evenement.debut, evenement.fin)),
            const SizedBox(height: 4),
            LigneInfo(LucideIcons.mapPin, evenement.lieu),
            if (places != null || evenement.categorie != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [if (evenement.categorie != null) Etiquette(evenement.categorie!, ton: Ton.accent), ?places]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class CarteActualite extends StatelessWidget {
  const CarteActualite(this.actualite, {super.key});
  final Actualite actualite;

  @override
  Widget build(BuildContext context) {
    final resume = actualite.resume ?? enBlocs(actualite.contenu).where((b) => b.genre == GenreDeBloc.paragraphe).map((b) => b.texte).firstOrNull;
    return Carte(
      onTap: () => context.push('/actualites/${actualite.slug}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (actualite.categorie != null) Etiquette(actualite.categorie!, ton: Ton.accent),
          if (actualite.reserveeAuxMembres) const Etiquette('Membres', ton: Ton.ambre, icone: LucideIcons.lock),
          if (actualite.date != null) Text(dateSimple(actualite.date), style: context.textes.bodySmall),
        ]),
        const SizedBox(height: 10),
        Text(actualite.titre, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
        if (resume != null) ...[const SizedBox(height: 6), Text(resume, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.textes.bodyMedium)],
      ]),
    );
  }
}

class CarteFormation extends StatelessWidget {
  const CarteFormation(this.formation, {super.key});
  final Formation formation;

  @override
  Widget build(BuildContext context) {
    final prochaine = formation.seances.where((s) => s.ouverte).toList()..sort((a, b) => a.debut!.compareTo(b.debut!));
    return Carte(
      onTap: () => context.push('/formations/${formation.slug}'),
      lisere: Charte.bleuRoyal,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [Etiquette(formation.niveauAffiche, ton: Ton.ambre), if (formation.categorie != null) Etiquette(formation.categorie!, ton: Ton.accent)]),
        const SizedBox(height: 10),
        Text(formation.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
        const SizedBox(height: 6),
        Text(formation.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.bodyMedium),
        const SizedBox(height: 12),
        if (formation.formateur != null) ...[LigneInfo(LucideIcons.user, formation.formateur!), const SizedBox(height: 4)],
        LigneInfo(LucideIcons.calendar, prochaine.isEmpty ? 'Aucune séance ouverte pour le moment' : 'Prochaine séance : ${dateSimple(prochaine.first.debut)}'),
      ]),
    );
  }
}

Ton tonDuProjet(String statut) => switch (statut) {
      'PROPOSE' => Ton.ambre,
      'VALIDE' || 'TERMINE' => Ton.succes,
      'REJETE' => Ton.danger,
      _ => Ton.accent,
    };

class CarteProjet extends StatelessWidget {
  const CarteProjet(this.projet, {super.key, this.personnel = false});
  final Projet projet;

  /// Carte de « Mes projets » : le statut de la proposition et la décision du bureau y figurent.
  final bool personnel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ouvrable = !personnel || projet.statut == 'EN_COURS' || projet.statut == 'TERMINE' || projet.statut == 'VALIDE';
    return Carte(
      onTap: ouvrable ? () => context.push('/projets/${projet.slug}') : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [Etiquette(projet.statutAffiche, ton: tonDuProjet(projet.statut)), if (projet.categorie != null) Etiquette(projet.categorie!, ton: Ton.accent)]),
        const SizedBox(height: 10),
        Text(projet.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
        const SizedBox(height: 6),
        Text(projet.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.textes.bodyMedium),
        if (projet.avancement != null && (projet.statut == 'EN_COURS' || projet.statut == 'TERMINE')) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: projet.avancement! / 100, minHeight: 7, backgroundColor: p.surfaceHaute, color: p.accent),
              ),
            ),
            const SizedBox(width: 10),
            Text('${projet.avancement} %', style: context.textes.labelMedium?.copyWith(color: p.texte)),
          ]),
        ],
        if (personnel && projet.motif != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surfaceHaute.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Décision du bureau', style: context.textes.labelMedium),
              const SizedBox(height: 4),
              Text(projet.motif!, style: context.textes.bodyMedium),
            ]),
          ),
        ],
        if (!personnel && projet.porteur != null) ...[const SizedBox(height: 12), LigneInfo(LucideIcons.user, projet.porteur!)],
        if (projet.technos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final t in projet.technos.take(4)) Etiquette(t)]),
        ],
      ]),
    );
  }
}

/// Rappel compact d'une inscription à venir (accueil).
class CarteRendezVous extends StatelessWidget {
  const CarteRendezVous(this.inscription, {super.key});
  final Inscription inscription;

  @override
  Widget build(BuildContext context) {
    final slug = inscription.pourEvenement ? inscription.evenementSlug : inscription.formationSlug;
    return Carte(
      padding: const EdgeInsets.all(14),
      onTap: slug == null ? null : () => context.push('/${inscription.pourEvenement ? 'evenements' : 'formations'}/$slug'),
      child: Row(children: [
        PastilleDate(inscription.debut),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(inscription.pourEvenement ? 'ÉVÉNEMENT' : 'FORMATION', style: context.textes.labelSmall?.copyWith(color: context.palette.ambreTexte, letterSpacing: 0.8)),
            const SizedBox(height: 3),
            Text(inscription.titre, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textes.titleSmall),
            const SizedBox(height: 3),
            Text(plageHoraire(inscription.debut, inscription.fin), style: context.textes.bodySmall),
          ]),
        ),
      ]),
    );
  }
}
