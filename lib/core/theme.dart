import 'package:flutter/material.dart';

/// Charte du Club Informatique de l'IST : mêmes couleurs et polices que le site.
class Charte {
  static const bleuRoyal = Color(0xFF1D4ED8);
  static const bleuNuit = Color(0xFF0B1E3F);
  static const cyan = Color(0xFF38BDF8);
  static const ambre = Color(0xFFFBBF24);
  static const ambreFonce = Color(0xFFF59E0B);
  static const succes = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const titres = 'Poppins';
  static const corps = 'Inter';
}

/// Couleurs propres à chaque thème, au-delà de ce que porte [ColorScheme].
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.fond,
    required this.surface,
    required this.surfaceHaute,
    required this.texte,
    required this.texteSecondaire,
    required this.texteDiscret,
    required this.trait,
    required this.traitFort,
    required this.accent,
    required this.ambreTexte,
    required this.degradeHero,
  });

  final Color fond;
  final Color surface;
  final Color surfaceHaute;
  final Color texte;
  final Color texteSecondaire;
  final Color texteDiscret;
  final Color trait;
  final Color traitFort;

  /// Couleur des éléments actifs : cyan en sombre, bleu royal en clair.
  final Color accent;
  final Color ambreTexte;
  final List<Color> degradeHero;

  static const sombre = Palette(
    fond: Color(0xFF070D1E),
    surface: Color(0xFF0F172A),
    surfaceHaute: Color(0xFF162447),
    texte: Color(0xFFF8FAFC),
    texteSecondaire: Color(0xFFCBD5E1),
    texteDiscret: Color(0xFF94A3B8),
    trait: Color(0x1AFFFFFF),
    traitFort: Color(0x4D38BDF8),
    accent: Charte.cyan,
    ambreTexte: Charte.ambre,
    degradeHero: [Color(0xFF0B1E3F), Color(0xFF12306B), Color(0xFF1D4ED8)],
  );

  static const clair = Palette(
    fond: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceHaute: Color(0xFFF1F5F9),
    texte: Color(0xFF0F172A),
    texteSecondaire: Color(0xFF334155),
    texteDiscret: Color(0xFF566378),
    trait: Color(0xFFE2E8F0),
    traitFort: Color(0xFFCBD5E1),
    accent: Charte.bleuRoyal,
    ambreTexte: Color(0xFFB45309),
    degradeHero: [Color(0xFF0B1E3F), Color(0xFF12306B), Color(0xFF1D4ED8)],
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) => other is Palette && t > 0.5 ? other : this;
}

extension PaletteDuContexte on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
  TextTheme get textes => Theme.of(this).textTheme;
}

ThemeData themeDuClub(Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final p = sombre ? Palette.sombre : Palette.clair;
  final schema = ColorScheme.fromSeed(seedColor: Charte.bleuRoyal, brightness: luminosite).copyWith(
    primary: sombre ? Charte.cyan : Charte.bleuRoyal,
    onPrimary: sombre ? Charte.bleuNuit : Colors.white,
    secondary: Charte.ambre,
    onSecondary: Charte.bleuNuit,
    surface: p.surface,
    onSurface: p.texte,
    error: Charte.danger,
    outline: p.traitFort,
    outlineVariant: p.trait,
  );

  TextStyle titre(double taille, FontWeight graisse, {double hauteur = 1.2}) =>
      TextStyle(fontFamily: Charte.titres, fontSize: taille, fontWeight: graisse, height: hauteur, color: p.texte, letterSpacing: -0.3);
  TextStyle corps(double taille, {FontWeight graisse = FontWeight.w400, Color? couleur, double hauteur = 1.5}) =>
      TextStyle(fontFamily: Charte.corps, fontSize: taille, fontWeight: graisse, height: hauteur, color: couleur ?? p.texteSecondaire);

  final rayon = BorderRadius.circular(16);
  final bordureChamp = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.traitFort));

  return ThemeData(
    useMaterial3: true,
    brightness: luminosite,
    colorScheme: schema,
    scaffoldBackgroundColor: p.fond,
    fontFamily: Charte.corps,
    extensions: [p],
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displaySmall: titre(32, FontWeight.w800, hauteur: 1.08),
      headlineMedium: titre(26, FontWeight.w800, hauteur: 1.12),
      headlineSmall: titre(22, FontWeight.w700),
      titleLarge: titre(19, FontWeight.w700),
      titleMedium: titre(16.5, FontWeight.w700),
      titleSmall: titre(14.5, FontWeight.w600),
      bodyLarge: corps(16),
      bodyMedium: corps(14.5),
      bodySmall: corps(12.5, couleur: p.texteDiscret),
      labelLarge: corps(15, graisse: FontWeight.w700, couleur: p.texte, hauteur: 1.2),
      labelMedium: corps(12.5, graisse: FontWeight.w600, couleur: p.texteDiscret, hauteur: 1.2),
      labelSmall: corps(11, graisse: FontWeight.w600, couleur: p.texteDiscret, hauteur: 1.2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.fond,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.texte,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: titre(19, FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: rayon, side: BorderSide(color: p.trait)),
    ),
    dividerTheme: DividerThemeData(color: p.trait, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent.withValues(alpha: 0.16),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (etats) => corps(11.5, graisse: etats.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, couleur: etats.contains(WidgetState.selected) ? p.accent : p.texteDiscret, hauteur: 1.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((etats) => IconThemeData(size: 23, color: etats.contains(WidgetState.selected) ? p.accent : p.texteDiscret)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Charte.bleuRoyal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: Charte.titres, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.texte,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        side: BorderSide(color: p.traitFort),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: Charte.titres, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accent, textStyle: const TextStyle(fontFamily: Charte.corps, fontSize: 14.5, fontWeight: FontWeight.w600)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: sombre ? const Color(0x99020612) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordureChamp,
      enabledBorder: bordureChamp,
      focusedBorder: bordureChamp.copyWith(borderSide: BorderSide(color: p.accent, width: 2)),
      errorBorder: bordureChamp.copyWith(borderSide: const BorderSide(color: Charte.danger)),
      focusedErrorBorder: bordureChamp.copyWith(borderSide: const BorderSide(color: Charte.danger, width: 2)),
      labelStyle: corps(14.5, couleur: p.texteDiscret),
      hintStyle: corps(14.5, couleur: p.texteDiscret),
      errorStyle: corps(12.5, couleur: sombre ? const Color(0xFFFCA5A5) : Charte.danger),
      errorMaxLines: 3,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accent.withValues(alpha: 0.18),
      side: BorderSide(color: p.trait),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: corps(13, graisse: FontWeight.w600, couleur: p.texte, hauteur: 1.2),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surfaceHaute,
      contentTextStyle: corps(14, couleur: p.texte),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.traitFort)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    listTileTheme: ListTileThemeData(iconColor: p.texteDiscret, textColor: p.texte),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()}),
  );
}
