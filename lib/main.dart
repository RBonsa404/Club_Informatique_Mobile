import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/club_api.dart';
import 'core/auth/session.dart';
import 'core/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');

  final session = Session();
  final preferences = Preferences();
  // La reprise de session et la lecture du thème se font pendant l'écran d'ouverture.
  preferences.charger();
  session.reprendre();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      ChangeNotifierProvider.value(value: preferences),
      Provider(create: (_) => ClubApi(session.dio)),
    ],
    child: const Application(),
  ));
}
