import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'core/auth/session.dart';
import 'core/config.dart';
import 'core/preferences.dart';
import 'core/theme.dart';
import 'features/accueil.dart';
import 'features/activites.dart';
import 'features/auth.dart';
import 'features/compte.dart';
import 'features/contenus.dart';

/// Pages réservées à un utilisateur connecté.
bool _protegee(String chemin) => chemin.startsWith('/espace');

GoRouter creerRouteur(Session session) => GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      redirect: (context, etat) {
        final chemin = etat.matchedLocation;
        if (!session.connecte && _protegee(chemin)) return '/connexion';
        if (session.connecte && (chemin == '/connexion' || chemin == '/inscription')) return '/';
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, etat, coque) => _Coque(coque),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const PageAccueil())]),
            StatefulShellBranch(routes: [GoRoute(path: '/activites', builder: (_, _) => const PageActivites())]),
            StatefulShellBranch(routes: [GoRoute(path: '/projets', builder: (_, _) => const PageProjets())]),
            StatefulShellBranch(routes: [GoRoute(path: '/notifications', builder: (_, _) => const PageNotifications())]),
            StatefulShellBranch(routes: [GoRoute(path: '/compte', builder: (_, _) => const PageCompte())]),
          ],
        ),
        GoRoute(path: '/connexion', builder: (_, _) => const PageConnexion()),
        GoRoute(path: '/inscription', builder: (_, _) => const PageInscription()),
        GoRoute(path: '/mot-de-passe-oublie', builder: (_, _) => const PageMotDePasseOublie()),
        GoRoute(path: '/actualites', builder: (_, _) => const PageActualites()),
        GoRoute(path: '/actualites/:slug', builder: (_, e) => PageActualite(e.pathParameters['slug']!)),
        GoRoute(path: '/evenements/:slug', builder: (_, e) => PageEvenement(e.pathParameters['slug']!)),
        GoRoute(path: '/formations/:slug', builder: (_, e) => PageFormation(e.pathParameters['slug']!)),
        GoRoute(path: '/projets/:slug', builder: (_, e) => PageProjet(e.pathParameters['slug']!)),
        GoRoute(path: '/club', builder: (_, _) => const PageClub()),
        GoRoute(path: '/contact', builder: (_, _) => const PageContact()),
        GoRoute(path: '/espace/inscriptions', builder: (_, _) => const PageInscriptions()),
        GoRoute(path: '/espace/supports', builder: (_, _) => const PageSupports()),
        GoRoute(path: '/espace/projets', builder: (_, _) => const PageMesProjets()),
        GoRoute(path: '/espace/projets/proposer', builder: (_, _) => const PageProposerProjet()),
        GoRoute(path: '/espace/profil', builder: (_, _) => const PageProfil()),
        GoRoute(path: '/espace/mot-de-passe', builder: (_, _) => const PageMotDePasse()),
      ],
    );

/// Coque de l'application : cinq onglets en bas de l'écran, chacun gardant sa position.
class _Coque extends StatelessWidget {
  const _Coque(this.coque);
  final StatefulNavigationShell coque;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final nonLues = session.nonLues;
    return Scaffold(
      body: coque,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.palette.trait))),
        child: NavigationBar(
          selectedIndex: coque.currentIndex,
          onDestinationSelected: (i) {
            // Un second appui sur l'onglet actif ramène à sa première page.
            coque.goBranch(i, initialLocation: i == coque.currentIndex);
            if (i == 3) session.actualiserNonLues();
          },
          destinations: [
            const NavigationDestination(icon: Icon(LucideIcons.house), label: 'Accueil'),
            const NavigationDestination(icon: Icon(LucideIcons.calendar), label: 'Activités'),
            const NavigationDestination(icon: Icon(LucideIcons.layers), label: 'Projets'),
            NavigationDestination(
              icon: Badge(isLabelVisible: nonLues > 0, label: Text(nonLues > 99 ? '99+' : '$nonLues'), backgroundColor: Charte.ambre, textColor: Charte.bleuNuit, child: const Icon(LucideIcons.bell)),
              label: 'Notifications',
            ),
            const NavigationDestination(icon: Icon(LucideIcons.user), label: 'Compte'),
          ],
        ),
      ),
    );
  }
}

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> with WidgetsBindingObserver {
  late final GoRouter _routeur = creerRouteur(context.read<Session>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Au retour au premier plan, le compteur de notifications est remis à jour.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<Session>().actualiserNonLues();
  }

  @override
  Widget build(BuildContext context) {
    final pret = context.select<Session, bool>((s) => s.pret);
    final theme = context.watch<Preferences>().theme;
    const langues = [Locale('fr')];
    const traductions = [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate];
    if (!pret) {
      return MaterialApp(debugShowCheckedModeBanner: false, title: Club.nom, theme: themeDuClub(Brightness.dark), locale: langues.first, supportedLocales: langues, localizationsDelegates: traductions, home: const EcranDeDemarrage());
    }
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: Club.nom,
      theme: themeDuClub(Brightness.light),
      darkTheme: themeDuClub(Brightness.dark),
      themeMode: theme,
      locale: langues.first,
      supportedLocales: langues,
      localizationsDelegates: traductions,
      routerConfig: _routeur,
    );
  }
}
