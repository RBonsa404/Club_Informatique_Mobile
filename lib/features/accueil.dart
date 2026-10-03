import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/api/club_api.dart';
import '../core/api/models.dart';
import '../core/auth/session.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'cartes.dart';

class _Accueil {
  const _Accueil(this.introduction, this.evenements, this.actualites, this.inscriptions);
  final String introduction;
  final List<Evenement> evenements;
  final List<Actualite> actualites;
  final List<Inscription> inscriptions;
}

/// Onglet Accueil : le club en un coup d'œil, puis ce qui arrive.
class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

  Future<_Accueil> _charger(ClubApi api, bool connecte) async {
    // Le texte d'introduction et les inscriptions sont secondaires : leur échec ne masque pas le reste.
    final resultats = await Future.wait<Object>([
      api.texteDePage('accueil').catchError((_) => ''),
      api.evenements(taille: 3, aVenir: true).then((p) => p.contenu),
      (connecte ? api.publications(taille: 4) : api.actualites(taille: 4)).then((p) => p.contenu),
      connecte ? api.mesInscriptions().then((p) => p.contenu).catchError((_) => <Inscription>[]) : Future.value(<Inscription>[]),
    ]);
    return _Accueil(resultats[0] as String, resultats[1] as List<Evenement>, resultats[2] as List<Actualite>, resultats[3] as List<Inscription>);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final api = context.read<ClubApi>();
    final utilisateur = session.utilisateur;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Chargement<_Accueil>(
          key: ValueKey(session.connecte),
          charger: () => _charger(api, session.connecte),
          squelette: ListView(padding: const EdgeInsets.all(marge), physics: const NeverScrollableScrollPhysics(), children: const [
            Squelette(hauteur: 210, rayon: 24),
            SizedBox(height: 24),
            Squelette(hauteur: 22, largeur: 160),
            SizedBox(height: 14),
            Squelette(hauteur: 110, rayon: 18),
            SizedBox(height: 12),
            Squelette(hauteur: 110, rayon: 18),
          ]),
          contenu: (context, donnees, recharger) {
            final prochaines = donnees.inscriptions.where((i) => i.active && i.aVenir).toList()..sort((a, b) => (a.debut ?? DateTime(2100)).compareTo(b.debut ?? DateTime(2100)));
            final paragraphes = enBlocs(donnees.introduction).where((b) => b.genre == GenreDeBloc.paragraphe).toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                _Entete(utilisateur: utilisateur),
                Padding(
                  padding: const EdgeInsets.fromLTRB(marge, 6, marge, 0),
                  child: _Hero(introduction: paragraphes.isEmpty ? null : paragraphes.first.texte, connecte: session.connecte),
                ),
                if (prochaines.isNotEmpty) ...[
                  TitreDeSection('Vos prochains rendez-vous', action: 'Tout voir', onAction: () => context.push('/espace/inscriptions')),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: marge),
                      itemCount: prochaines.length.clamp(0, 6),
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(width: 280, child: CarteRendezVous(prochaines[i])),
                    ),
                  ),
                ],
                TitreDeSection('Prochains événements', action: 'Tout voir', onAction: () => context.go('/activites')),
                if (donnees.evenements.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: marge), child: _Rien('Aucun événement à venir pour le moment.', LucideIcons.calendar))
                else
                  for (final e in donnees.evenements) Padding(padding: const EdgeInsets.fromLTRB(marge, 0, marge, 12), child: CarteEvenement(e)),
                TitreDeSection('Actualités', action: 'Tout voir', onAction: () => context.push('/actualites')),
                if (donnees.actualites.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: marge), child: _Rien('Aucune actualité publiée pour le moment.', LucideIcons.newspaper))
                else
                  for (final a in donnees.actualites) Padding(padding: const EdgeInsets.fromLTRB(marge, 0, marge, 12), child: CarteActualite(a)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Entete extends StatelessWidget {
  const _Entete({required this.utilisateur});
  final Utilisateur? utilisateur;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(marge, 14, marge - 6, 10),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/img/logo-256.png', width: 42, height: 42)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(utilisateur == null ? Club.nomCourt : 'Bonjour, ${utilisateur!.prenom}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textes.titleMedium),
              Text(utilisateur == null ? Club.institution : utilisateur!.roleAffiche,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textes.labelSmall?.copyWith(color: context.palette.ambreTexte, letterSpacing: 0.4)),
            ]),
          ),
          if (utilisateur == null) TextButton(onPressed: () => context.push('/connexion'), child: const Text('Connexion')),
        ]),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.introduction, required this.connecte});
  final String? introduction;
  final bool connecte;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: context.palette.degradeHero, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: Charte.bleuRoyal.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _Circuit())),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontFamily: Charte.titres, fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.5),
                  children: [TextSpan(text: 'Club Informatique\nde l’'), TextSpan(text: 'IST', style: TextStyle(color: Charte.ambre))],
                ),
              ),
              if (introduction != null) ...[
                const SizedBox(height: 12),
                Text(introduction!, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: Charte.corps, fontSize: 14, height: 1.55, color: Color(0xFFDBEAFE))),
              ],
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Charte.ambre, foregroundColor: Charte.bleuNuit, minimumSize: const Size(0, 46)),
                  onPressed: () => context.push('/club'),
                  child: const Text('Découvrir le club'),
                ),
                if (!connecte)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x66FFFFFF)), minimumSize: const Size(0, 46)),
                    onPressed: () => context.push('/inscription'),
                    child: const Text('Rejoindre'),
                  ),
              ]),
            ]),
          ),
        ]),
      );
}

/// Tracé de circuit discret, repris de l'habillage du site.
class _Circuit extends CustomPainter {
  const _Circuit();

  @override
  void paint(Canvas canvas, Size size) {
    final trait = Paint()
      ..color = Charte.cyan.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final point = Paint()..color = Charte.ambre.withValues(alpha: 0.75);
    final w = size.width, h = size.height;
    final chemins = [
      [Offset(w, h * 0.16), Offset(w - 64, h * 0.16), Offset(w - 92, h * 0.3), Offset(w - 136, h * 0.3)],
      [Offset(w, h * 0.78), Offset(w - 44, h * 0.78), Offset(w - 70, h * 0.64), Offset(w - 104, h * 0.64)],
      [Offset(w - 30, 0), Offset(w - 30, h * 0.09)],
    ];
    for (final c in chemins) {
      final chemin = Path()..moveTo(c.first.dx, c.first.dy);
      for (final o in c.skip(1)) {
        chemin.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(chemin, trait);
      canvas.drawCircle(c.last, 3.2, point);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Rien extends StatelessWidget {
  const _Rien(this.message, this.icone);
  final String message;
  final IconData icone;

  @override
  Widget build(BuildContext context) => Carte(
        child: Row(children: [
          Icon(icone, size: 20, color: context.palette.texteDiscret),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: context.textes.bodyMedium)),
        ]),
      );
}
