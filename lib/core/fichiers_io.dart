import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Enregistre le fichier dans le dossier temporaire de l'application, puis l'ouvre avec l'application adaptée.
Future<bool> ouvrirOctets(List<int> octets, String nom, String? type) async {
  final dossier = await getTemporaryDirectory();
  final propre = nom.replaceAll(RegExp(r'[^\w.\- ]'), '_');
  final fichier = File('${dossier.path}/$propre');
  await fichier.writeAsBytes(octets, flush: true);
  final resultat = await OpenFilex.open(fichier.path, type: type);
  return resultat.type == ResultType.done;
}
