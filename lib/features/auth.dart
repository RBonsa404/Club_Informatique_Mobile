import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/api/api_error.dart';
import '../core/auth/session.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../ui/widgets.dart';
import 'contenus.dart';

final _adresse = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Habillage commun des écrans d'authentification : logo, titre, texte d'accroche.
class _Cadre extends StatelessWidget {
  const _Cadre({required this.titre, required this.accroche, required this.enfants});
  final String titre;
  final String accroche;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/img/logo-256.png', width: 84, height: 84))),
                  const SizedBox(height: 22),
                  Text(titre, textAlign: TextAlign.center, style: context.textes.headlineMedium),
                  const SizedBox(height: 8),
                  Text(accroche, textAlign: TextAlign.center, style: context.textes.bodyLarge),
                  const SizedBox(height: 26),
                  ...enfants,
                ]),
              ),
            ),
          ),
        ),
      );
}

class PageConnexion extends StatefulWidget {
  const PageConnexion({super.key});

  @override
  State<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends State<PageConnexion> {
  final _formulaire = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _envoi = false;
  bool _visible = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() => _erreur = null);
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _envoi = true);
    final session = context.read<Session>();
    try {
      await session.connecter(_email.text, _motDePasse.text);
      if (!mounted) return;
      if (session.utilisateur?.changementMotDePasseRequis ?? false) {
        // Le choix du mot de passe initial se fait sur le site, comme le reste de l'administration.
        afficherMessage(context, 'Choisissez d’abord votre mot de passe sur le site web.');
        ouvrirLien(context, '$origineDuSite/connexion');
        await session.deconnecter();
        return;
      }
      afficherMessage(context, 'Bienvenue, ${session.utilisateur?.prenom ?? ''}.');
      context.canPop() ? context.pop() : context.go('/');
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Cadre(
        titre: 'Bon retour',
        accroche: 'Connectez-vous pour accéder à votre espace.',
        enfants: [
          Alerte(_erreur),
          Form(
            key: _formulaire,
            child: AutofillGroup(
              child: Column(children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Adresse électronique', prefixIcon: Icon(LucideIcons.mail, size: 18)),
                  validator: (v) => !_adresse.hasMatch((v ?? '').trim()) ? 'Indiquez une adresse électronique valide.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _motDePasse,
                  obscureText: !_visible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _envoyer(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(onPressed: () => setState(() => _visible = !_visible), icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye, size: 19), tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe'),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Indiquez votre mot de passe.' : null,
                ),
              ]),
            ),
          ),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/mot-de-passe-oublie'), child: const Text('Mot de passe oublié ?'))),
          const SizedBox(height: 8),
          BoutonPrincipal(libelle: 'Se connecter', enCours: _envoi, onPressed: _envoyer, icone: LucideIcons.arrowRight),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Pas encore membre ?', style: context.textes.bodyMedium),
            TextButton(onPressed: () => context.pushReplacement('/inscription'), child: const Text('S’inscrire')),
          ]),
        ],
      );
}

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  State<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final _formulaire = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _filiere = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _accord = false;
  bool _envoi = false;
  bool _visible = false;
  bool _envoye = false;
  String? _erreur;
  Map<String, String> _champs = const {};

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _filiere, _motDePasse]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() { _erreur = null; _champs = const {}; });
    if (!_formulaire.currentState!.validate()) return;
    if (!_accord) return setState(() => _erreur = 'Votre accord est nécessaire pour créer le compte.');
    setState(() => _envoi = true);
    try {
      await context.read<Session>().inscrire(nom: _nom.text, prenom: _prenom.text, email: _email.text, filiere: _filiere.text, motDePasse: _motDePasse.text);
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
  Widget build(BuildContext context) {
    if (_envoye) {
      return _Cadre(
        titre: 'Vérifiez votre boîte de réception',
        accroche: 'Un courriel vient d’être envoyé à ${_email.text.trim()}. Ouvrez le lien qu’il contient pour activer votre compte, puis connectez-vous.',
        enfants: [BoutonPrincipal(libelle: 'Aller à la connexion', onPressed: () => context.pushReplacement('/connexion'))],
      );
    }
    return _Cadre(
      titre: 'Rejoindre le club',
      accroche: 'Créez votre compte pour participer aux formations, aux événements et aux projets.',
      enfants: [
        Alerte(_erreur),
        Form(
          key: _formulaire,
          child: Column(children: [
            TextFormField(controller: _prenom, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.givenName], decoration: const InputDecoration(labelText: 'Prénom *'), validator: (v) => _champs['prenom'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre prénom.' : null)),
            const SizedBox(height: 14),
            TextFormField(controller: _nom, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.familyName], decoration: const InputDecoration(labelText: 'Nom *'), validator: (v) => _champs['nom'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre nom.' : null)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Adresse électronique *'),
              validator: (v) => _champs['email'] ?? (!_adresse.hasMatch((v ?? '').trim()) ? 'Indiquez une adresse électronique valide.' : null),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _filiere, textCapitalization: TextCapitalization.sentences, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Filière *'), validator: (v) => _champs['filiere'] ?? ((v ?? '').trim().length < 2 ? 'Indiquez votre filière.' : null)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _motDePasse,
              obscureText: !_visible,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Mot de passe *',
                helperText: '8 caractères au moins : minuscule, majuscule, chiffre et symbole.',
                helperMaxLines: 2,
                suffixIcon: IconButton(onPressed: () => setState(() => _visible = !_visible), icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye, size: 19), tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe'),
              ),
              validator: (v) => _champs['motDePasse'] ?? controlerMotDePasse(v ?? ''),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          value: _accord,
          onChanged: (v) => setState(() => _accord = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text('J’accepte les conditions d’utilisation et la politique de confidentialité du club.', style: context.textes.bodyMedium),
        ),
        Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => ouvrirLien(context, '$origineDuSite/confidentialite'), child: const Text('Lire la politique de confidentialité'))),
        const SizedBox(height: 10),
        BoutonPrincipal(libelle: 'Créer mon compte', enCours: _envoi, onPressed: _envoyer),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Déjà membre ?', style: context.textes.bodyMedium),
          TextButton(onPressed: () => context.pushReplacement('/connexion'), child: const Text('Se connecter')),
        ]),
      ],
    );
  }
}

class PageMotDePasseOublie extends StatefulWidget {
  const PageMotDePasseOublie({super.key});

  @override
  State<PageMotDePasseOublie> createState() => _PageMotDePasseOublieState();
}

class _PageMotDePasseOublieState extends State<PageMotDePasseOublie> {
  final _formulaire = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() => _erreur = null);
    if (!_formulaire.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await context.read<Session>().demanderReinitialisation(_email.text);
      if (mounted) setState(() => _envoye = true);
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => _envoye
      ? _Cadre(
          titre: 'Demande enregistrée',
          accroche: 'Si un compte correspond à cette adresse, un courriel contenant un lien de réinitialisation vient de lui être envoyé. Le lien s’ouvre sur le site du club.',
          enfants: [BoutonPrincipal(libelle: 'Retour à la connexion', onPressed: () => context.pop())],
        )
      : _Cadre(
          titre: 'Mot de passe oublié',
          accroche: 'Indiquez l’adresse de votre compte : vous recevrez un lien pour choisir un nouveau mot de passe.',
          enfants: [
            Alerte(_erreur),
            Form(
              key: _formulaire,
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onFieldSubmitted: (_) => _envoyer(),
                decoration: const InputDecoration(labelText: 'Adresse électronique', prefixIcon: Icon(LucideIcons.mail, size: 18)),
                validator: (v) => !_adresse.hasMatch((v ?? '').trim()) ? 'Indiquez une adresse électronique valide.' : null,
              ),
            ),
            const SizedBox(height: 20),
            BoutonPrincipal(libelle: 'Recevoir le lien', enCours: _envoi, onPressed: _envoyer),
          ],
        );
}

/// Écran d'ouverture, affiché pendant la reprise de la session.
class EcranDeDemarrage extends StatelessWidget {
  const EcranDeDemarrage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Charte.bleuNuit,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(borderRadius: BorderRadius.circular(26), child: Image.asset('assets/img/logo-256.png', width: 116, height: 116)),
            const SizedBox(height: 26),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Charte.cyan)),
          ]),
        ),
      );
}
