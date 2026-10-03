import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

/// Écran d'ouverture : il prolonge l'écran de démarrage d'Android (même fond, même logo au centre),
/// puis fait apparaître le nom du club pendant la reprise de la session.
class EcranDeDemarrage extends StatefulWidget {
  const EcranDeDemarrage({super.key});

  @override
  State<EcranDeDemarrage> createState() => _EcranDeDemarrageState();
}

class _EcranDeDemarrageState extends State<EcranDeDemarrage> with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apparition = CurvedAnimation(parent: _animation, curve: const Interval(0.25, 1, curve: Curves.easeOutCubic));
    return Scaffold(
      backgroundColor: Charte.bleuNuit,
      body: Stack(children: [
        Positioned.fill(child: FadeTransition(opacity: apparition, child: const CustomPaint(painter: _Decor()))),
        // Le logo reste exactement au centre : aucun saut entre l'écran d'Android et celui de l'application.
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Charte.cyan.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: 2)],
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/img/logo-256.png'),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.42),
          child: FadeTransition(
            opacity: apparition,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(apparition),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontFamily: Charte.titres, fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                    children: [TextSpan(text: 'Club Informatique\nde l’'), TextSpan(text: 'IST', style: TextStyle(color: Charte.ambre))],
                  ),
                ),
                const SizedBox(height: 10),
                Text(Club.institution.toUpperCase(), style: const TextStyle(fontFamily: Charte.corps, fontSize: 11, fontWeight: FontWeight.w600, color: Charte.ambre, letterSpacing: 1.6)),
              ]),
            ),
          ),
        ),
        const Align(
          alignment: Alignment(0, 0.86),
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Charte.cyan)),
        ),
      ]),
    );
  }
}

/// Halo et tracés de circuit de la charte.
class _Decor extends CustomPainter {
  const _Decor();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = RadialGradient(center: const Alignment(0.9, -1), radius: 1.3, colors: [Charte.bleuRoyal.withValues(alpha: 0.55), Charte.bleuNuit.withValues(alpha: 0)]).createShader(Offset.zero & size),
    );
    final trait = Paint()
      ..color = Charte.cyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final point = Paint()..color = Charte.ambre.withValues(alpha: 0.8);
    final chemins = [
      [Offset(w, h * 0.12), Offset(w - 70, h * 0.12), Offset(w - 104, h * 0.17), Offset(w - 150, h * 0.17)],
      [Offset(0, h * 0.2), Offset(48, h * 0.2), Offset(76, h * 0.24), Offset(112, h * 0.24)],
      [Offset(0, h * 0.82), Offset(60, h * 0.82), Offset(92, h * 0.78), Offset(134, h * 0.78)],
      [Offset(w, h * 0.93), Offset(w - 52, h * 0.93), Offset(w - 80, h * 0.89), Offset(w - 116, h * 0.89)],
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
