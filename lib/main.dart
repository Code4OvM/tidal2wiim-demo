import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/kuenstler_sortierung.dart';
import 'services/tidal_auth_service.dart';

part 'core/hilfen.dart';
part 'core/sammlung.dart';
part 'models/modelle.dart';
part 'data/lokale_datenbank.dart';
part 'services/cover_cache.dart';
part 'services/tidal_api.dart';
part 'pages/home_page.dart';
part 'data/kuenstler_sortierung_speichern.dart';
part 'pages/kuenstler_sortiernamen_page.dart';
part 'pages/start_page.dart';
part 'pages/kuenstler_page.dart';
part 'pages/kategorie_page.dart';
part 'pages/album_detail_page.dart';
part 'widgets/dialoge.dart';
part 'widgets/album_grid.dart';
part 'widgets/album_cover.dart';

void main() {
  runApp(const Tidal2WiiMApp());
}

class Tidal2WiiMApp extends StatelessWidget {
  const Tidal2WiiMApp({super.key, this.bibliothekLaden, this.authService});

  // Optionaler Datenzugriff für isolierte Oberflächentests.
  // Im normalen App-Start wird unverändert SQLite verwendet.
  final Future<LokaleBibliothekCache?> Function()? bibliothekLaden;
  final TidalAuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tidal2WiiM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        bibliothekLaden: bibliothekLaden,
        authService: authService,
      ),
    );
  }
}
