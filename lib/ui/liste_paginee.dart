import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api/api_error.dart';
import '../core/api/models.dart';
import 'widgets.dart';

/// Liste alimentée page par page : la suite se charge en approchant de la fin.
class ListePaginee<T> extends StatefulWidget {
  const ListePaginee({super.key, required this.charger, required this.element, required this.messageVide, this.iconeVide = LucideIcons.inbox, this.entete, this.hauteurSquelette = 120});
  final Future<PageDe<T>> Function(int page) charger;
  final Widget Function(BuildContext context, T element, Future<void> Function() recharger) element;
  final String messageVide;
  final IconData iconeVide;
  final Widget? entete;
  final double hauteurSquelette;

  @override
  State<ListePaginee<T>> createState() => _ListePagineeState<T>();
}

class _ListePagineeState<T> extends State<ListePaginee<T>> {
  final _elements = <T>[];
  final _defilement = ScrollController();
  ErreurApi? _erreur;
  bool _initial = true;
  bool _suite = false;
  bool _fin = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      if (_defilement.position.pixels > _defilement.position.maxScrollExtent - 320) _chargerSuite();
    });
    _recharger();
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  Future<void> _recharger({bool discret = false}) async {
    if (!discret) setState(() { _initial = true; _erreur = null; });
    try {
      final page = await widget.charger(0);
      if (!mounted) return;
      setState(() {
        _elements
          ..clear()
          ..addAll(page.contenu);
        _page = 0;
        _fin = page.derniere;
        _initial = false;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (discret && _elements.isNotEmpty) {
        afficherMessage(context, ErreurApi.depuis(e).message);
      } else {
        setState(() { _erreur = ErreurApi.depuis(e); _initial = false; });
      }
    }
  }

  Future<void> _chargerSuite() async {
    if (_suite || _fin || _initial || _erreur != null) return;
    setState(() => _suite = true);
    try {
      final page = await widget.charger(_page + 1);
      if (!mounted) return;
      setState(() {
        _elements.addAll(page.contenu);
        _page += 1;
        _fin = page.derniere || page.contenu.isEmpty;
      });
    } catch (e) {
      if (mounted) afficherMessage(context, ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _suite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initial) {
      return ListView(physics: const NeverScrollableScrollPhysics(), children: [?widget.entete, SqueletteDeListe(hauteur: widget.hauteurSquelette)]);
    }
    final enTete = widget.entete == null ? 0 : 1;
    final Widget corps;
    if (_erreur != null || _elements.isEmpty) {
      corps = ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        ?widget.entete,
        _erreur != null ? EtatErreur(erreur: _erreur!, onReessayer: _recharger) : EtatVide(icone: widget.iconeVide, message: widget.messageVide),
      ]);
    } else {
      corps = ListView.builder(
        controller: _defilement,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: _elements.length + enTete + (_fin ? 0 : 1),
        itemBuilder: (context, i) {
          if (i < enTete) return widget.entete!;
          final rang = i - enTete;
          if (rang >= _elements.length) {
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))));
          }
          return Padding(padding: const EdgeInsets.fromLTRB(marge, 0, marge, 12), child: widget.element(context, _elements[rang], () => _recharger(discret: true)));
        },
      );
    }
    return RefreshIndicator(onRefresh: () => _recharger(discret: true), child: corps);
  }
}
