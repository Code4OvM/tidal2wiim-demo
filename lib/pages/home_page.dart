part of '../main.dart';

// ============================================================================
// Hauptseite
// ============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.bibliothekLaden, this.authService});

  final Future<LokaleBibliothekCache?> Function()? bibliothekLaden;
  final TidalAuthService? authService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const FlutterAppAuth _appAuth = FlutterAppAuth();

  static const String _clientId = 'Y1mKZd5jZnBvqKQ1';
  static const String _redirectUrl = 'tidal2wiim://login-callback';

  static const AuthorizationServiceConfiguration _serviceConfiguration =
      AuthorizationServiceConfiguration(
        authorizationEndpoint: 'https://login.tidal.com/authorize',
        tokenEndpoint: 'https://auth.tidal.com/v1/oauth2/token',
      );

  static const String _sammlungsPfad =
      '/v2/userCollectionAlbums/me/relationships/items';

  static const double _kuenstlerZeilenHoehe = 76;

  late final TidalAuthService _auth;
  bool _anmeldungWirdGeladen = true;
  String? _land;
  String? _naechsterCursor;

  final Set<String> _geleseneCursor = {};
  List<Album> _alben = [];

  final TextEditingController _suchController = TextEditingController();

  final ScrollController _albumScrollController = ScrollController();
  final ScrollController _kuenstlerScrollController = ScrollController();
  final ScrollController _kategorieScrollController = ScrollController();

  String _suchtext = '';
  Sortierung _sortierung = Sortierung.kuenstler;
  SammlungAnsicht _sammlungsAnsicht = SammlungAnsicht.alben;
  AppSeite _appSeite = AppSeite.start;

  Map<String, KuenstlerEinstellung> _kuenstlerEinstellungen = {};
  List<Kategorie> _kategorien = [];

  bool _kuenstlerEinstellungenGeladen = false;
  bool _kategorienGeladen = false;
  bool _lokalLaedt = false;
  bool _hintergrundAktualisierung = false;
  String? _lokalFehler;
  DateTime? _bibliothekGespeichertAm;

  int _seitenGeladen = 0;
  bool _beschaeftigt = false;
  bool _ladeAlben = false;
  bool _stoppVorgemerkt = false;
  bool _detailsOffen = false;

  String _status = 'Nicht angemeldet';
  String _apiErgebnis = 'Noch keine API-Abfrage durchgeführt.';
  String _albenStatus = 'Noch keine Alben geladen.';

  bool get _hatToken => _auth.hasSession;
  bool get _authBedienungGesperrt =>
      _beschaeftigt ||
      _anmeldungWirdGeladen ||
      _hintergrundAktualisierung ||
      _ladeAlben ||
      _auth.isRefreshing;

  bool get _vollstaendig => _seitenGeladen > 0 && _naechsterCursor == null;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? TidalAuthService(clientId: _clientId);
    _auth.addListener(_authGeaendert);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialisieren());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_authGeaendert);
    if (widget.authService == null) _auth.dispose();
    _suchController.dispose();
    _albumScrollController.dispose();
    _kuenstlerScrollController.dispose();
    _kategorieScrollController.dispose();
    super.dispose();
  }

  Future<void> _initialisieren() async {
    await Future.wait<void>([_bibliothekAusCacheLaden(), _auth.restore()]);
    if (!mounted) return;
    setState(() {
      _anmeldungWirdGeladen = false;
    });
    _authGeaendert();
    if (!_hatToken) return;
    if (await _onlineZugangPruefen() && mounted && _alben.isNotEmpty) {
      unawaited(_bibliothekImHintergrundAktualisieren());
    }
  }

  void _authGeaendert() {
    if (!mounted) return;
    setState(() {
      _status = _auth.isRefreshing
          ? 'Anmeldung wird automatisch erneuert ...'
          : _auth.hasUsableAccessToken
          ? 'Angemeldet ✓'
          : _auth.hasSession
          ? 'Anmeldung gespeichert · Online-Prüfung ausstehend'
          : 'Nicht angemeldet';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_authBedienungGesperrt &&
        _auth.initialized &&
        _hatToken) {
      unawaited(_onlineZugangPruefen());
    }
  }

  Future<bool> _onlineZugangPruefen() async {
    try {
      await _auth.accessToken();
      return mounted;
    } on TidalSignInRequired {
      _anmeldungUngueltig();
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiErgebnis = _fehlerText(e);
        });
      }
    }
    return false;
  }

  Future<void> _anmeldungVergessen() async {
    if (_authBedienungGesperrt) return;
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anmeldung auf diesem Tablet vergessen?'),
        content: const Text(
          'Nur die gespeicherten Tidal2WiiM-Zugangsdaten werden entfernt. '
          'Kategorien, Künstlernamen und Bibliothek bleiben lokal erhalten. '
          'Die separate TIDAL-App wird dadurch nicht abgemeldet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Anmeldung vergessen'),
          ),
        ],
      ),
    );
    if (!mounted || bestaetigt != true) return;
    setState(() {
      _beschaeftigt = true;
    });
    try {
      await _auth.forget();
      if (!mounted) return;
      setState(() {
        _land = null;
        _status = 'Nicht angemeldet';
        _apiErgebnis = _auth.storageWarning ?? 'Gespeicherte Anmeldung entfernt. Lokale Bibliothek bleibt erhalten.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _beschaeftigt = false;
        });
      }
    }
  }

  void _sammlungLeeren() {
    _alben = [];
    _seitenGeladen = 0;
    _naechsterCursor = null;
    _geleseneCursor.clear();
  }

  // --------------------------------------------------------------------------
  // Lokale Daten
  // --------------------------------------------------------------------------

  Future<void> _bibliothekAusCacheLaden() async {
    try {
      final laden =
          widget.bibliothekLaden ?? LokaleDatenbank.instance.albumCacheLaden;
      final cache = await laden();

      if (!mounted ||
          cache == null ||
          _seitenGeladen > 0 ||
          _hintergrundAktualisierung) {
        return;
      }

      setState(() {
        _alben = cache.alben;
        _bibliothekGespeichertAm = cache.gespeichertAm;
        _albenStatus =
            'Lokale Bibliothek geladen ✓ – ${cache.alben.length} Alben.';
      });

      unawaited(LokalerCoverCache.instance.synchronisieren(cache.alben));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lokalFehler =
            'Lokaler Bibliotheks-Cache konnte nicht gelesen werden: '
            '${e.runtimeType}';
      });
    }
  }

  String _cacheZeitText(DateTime zeit) {
    String zwei(int wert) => wert.toString().padLeft(2, '0');

    return '${zwei(zeit.day)}.${zwei(zeit.month)}.${zeit.year} '
        '${zwei(zeit.hour)}:${zwei(zeit.minute)}';
  }

  Future<void> _kuenstlerEinstellungenLaden({bool erzwingen = false}) async {
    if (_kuenstlerEinstellungenGeladen && !erzwingen) return;

    setState(() {
      _lokalLaedt = true;
      _lokalFehler = null;
    });

    try {
      final daten = await LokaleDatenbank.instance
          .kuenstlerEinstellungenLaden();

      if (!mounted) return;

      setState(() {
        _kuenstlerEinstellungen = daten;
        _kuenstlerEinstellungenGeladen = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lokalFehler = 'Lokale Datenbank: ${e.runtimeType}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _lokalLaedt = false;
        });
      }
    }
  }

  Future<void> _kategorienLaden({bool erzwingen = false}) async {
    if (_kategorienGeladen && !erzwingen) return;

    setState(() {
      _lokalLaedt = true;
      _lokalFehler = null;
    });

    try {
      final daten = await LokaleDatenbank.instance.kategorienLaden();

      if (!mounted) return;

      setState(() {
        _kategorien = daten;
        _kategorienGeladen = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lokalFehler = 'Lokale Datenbank: ${e.runtimeType}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _lokalLaedt = false;
        });
      }
    }
  }

  Future<void> _ansichtWechseln(SammlungAnsicht ansicht) async {
    _suchController.clear();

    setState(() {
      _suchtext = '';
      _sammlungsAnsicht = ansicht;
    });

    if (ansicht == SammlungAnsicht.kuenstler) {
      await _kuenstlerEinstellungenLaden();
    }

    if (ansicht == SammlungAnsicht.kategorien) {
      await _kategorienLaden();
    }
  }

  // --------------------------------------------------------------------------
  // Kategorien verwalten
  // --------------------------------------------------------------------------

  Future<void> _kategorieAnlegen() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _KategorieNameDialog(titel: 'Neue Kategorie'),
    );

    if (!mounted || name == null) return;

    try {
      await LokaleDatenbank.instance.kategorieAnlegen(name);
      await _kategorienLaden(erzwingen: true);
    } on DatabaseException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Die Kategorie existiert bereits oder der Name ist ungültig.',
          ),
        ),
      );
    }
  }

  Future<void> _kategorieUmbenennen(Kategorie kategorie) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _KategorieNameDialog(
        titel: 'Kategorie umbenennen',
        startwert: kategorie.name,
      ),
    );

    if (!mounted || name == null || name == kategorie.name) return;

    try {
      await LokaleDatenbank.instance.kategorieUmbenennen(kategorie.id, name);
      await _kategorienLaden(erzwingen: true);
    } on DatabaseException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dieser Kategoriename ist bereits vorhanden.'),
        ),
      );
    }
  }

  Future<void> _kategorieLoeschen(Kategorie kategorie) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategorie löschen?'),
          content: Text(
            '„${kategorie.name}“ wird gelöscht.\n\n'
            'Die Alben selbst werden nicht verändert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (bestaetigt != true) return;

    await LokaleDatenbank.instance.kategorieLoeschen(kategorie.id);
    await _kategorienLaden(erzwingen: true);
  }

  Future<void> _kategorieOeffnen(Kategorie kategorie) async {
    // Suchfeld-Fokus vor dem Seitenwechsel lösen und die Tastatur schließen.
    FocusScope.of(context).unfocus();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KategoriePage(
          kategorieId: kategorie.id,
          kategorieName: kategorie.name,
          alleAlben: _alben,
          authService: _auth,
          land: _land,
          onAnmeldungUngueltig: _anmeldungUngueltig,
          onKategorienGeaendert: () async {
            await _kategorienLaden(erzwingen: true);
          },
        ),
      ),
    );

    if (!mounted) return;
    await _kategorienLaden(erzwingen: true);
  }

  // --------------------------------------------------------------------------
  // Künstler bearbeiten
  // --------------------------------------------------------------------------

  Future<void> _kuenstlerBearbeiten(KuenstlerOrdner ordner) async {
    await _kuenstlerEinstellungenLaden();

    if (!mounted) return;

    final bestehend = _kuenstlerEinstellungen[ordner.kuenstler.id];

    final ergebnis = await showDialog<_KuenstlerDialogErgebnis>(
      context: context,
      builder: (_) => _KuenstlerBearbeitenDialog(
        kuenstlerId: ordner.kuenstler.id,
        tidalName: ordner.kuenstler.name,
        bestehend: bestehend,
      ),
    );

    if (!mounted || ergebnis == null) return;

    if (ergebnis.zuruecksetzen) {
      await LokaleDatenbank.instance.kuenstlerEinstellungLoeschen(
        ordner.kuenstler.id,
      );
    } else {
      final einstellung = ergebnis.einstellung;
      if (einstellung == null) return;

      final unveraendert =
          einstellung.eigenerName == null &&
          einstellung.sortiername == ordner.kuenstler.name;

      if (unveraendert) {
        await LokaleDatenbank.instance.kuenstlerEinstellungLoeschen(
          ordner.kuenstler.id,
        );
      } else {
        await LokaleDatenbank.instance.kuenstlerEinstellungSpeichern(
          einstellung,
        );
      }
    }

    await _kuenstlerEinstellungenLaden(erzwingen: true);
  }

  // --------------------------------------------------------------------------
  // TIDAL
  // --------------------------------------------------------------------------

  Future<void> _login({bool sammlungNachLogin = false}) async {
    if (_authBedienungGesperrt) return;
    _suchController.clear();
    var abgleichStarten = false;
    setState(() {
      _beschaeftigt = true;
      _suchtext = '';
      _status = 'TIDAL-Anmeldung wird gestartet ...';
      _apiErgebnis = 'Bitte die Anmeldung abschließen.';
    });

    try {
      // Kein Client-Secret und kein zusätzlich erfundener Scope.
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: _serviceConfiguration,
          scopes: const ['user.read', 'collection.read'],
        ),
      );
      if (!mounted) return;
      final access = _text(result.accessToken);
      if (access == null) {
        throw const TidalAuthUnavailable(
          'TIDAL hat kein Access-Token geliefert.',
        );
      }
      await _auth.acceptLogin(
        TidalSession(
          accessToken: access,
          refreshToken: _text(result.refreshToken),
          expiresAt: result.accessTokenExpirationDateTime,
        ),
      );
      if (!mounted) return;
      setState(() {
        _land = null;
        _status = 'Angemeldet ✓';
        _apiErgebnis =
            _auth.storageWarning ??
            (_auth.hasRefreshToken
                ? 'Anmeldung sicher gespeichert. Der Zugang wird bei Bedarf automatisch erneuert.'
                : 'Angemeldet. TIDAL hat kein Refresh-Token geliefert; später ist eine Neuanmeldung nötig.');
        if (sammlungNachLogin && _alben.isNotEmpty) {
          _appSeite = AppSeite.sammlung;
        }
      });
      abgleichStarten = _alben.isNotEmpty;
    } on FlutterAppAuthUserCancelledException {
      if (!mounted) return;
      _authGeaendert();
      setState(() {
        _apiErgebnis =
            'Anmeldung abgebrochen. Vorhandene Sitzung bleibt erhalten.';
      });
    } on FlutterAppAuthPlatformException {
      if (!mounted) return;
      _authGeaendert();
      setState(() {
        _apiErgebnis = 'TIDAL-Anmeldung konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
      });
    } catch (e) {
      if (!mounted) return;
      _authGeaendert();
      setState(() {
        _apiErgebnis = _fehlerText(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _beschaeftigt = false;
        });
        if (abgleichStarten) {
          unawaited(_bibliothekImHintergrundAktualisieren());
        }
      }
    }
  }

  Future<Json> _getJson(
    http.Client client,
    String pfad, [
    Map<String, String> parameter = const {},
  ]) {
    return _apiLesen(
      client,
      _auth,
      pfad.split('/').where((teil) => teil.isNotEmpty).toList(),
      parameter,
    );
  }

  Future<void> _verbindungPruefen() async {
    if (_beschaeftigt) return;

    if (!await _onlineZugangPruefen() || !mounted) return;

    setState(() {
      _beschaeftigt = true;
      _apiErgebnis = 'Benutzerdaten werden geladen ...';
    });

    final client = http.Client();

    try {
      final dokument = await _getJson(client, '/v2/users/me');

      if (!mounted) return;

      final daten = _objekt(dokument['data']);
      final id = _text(daten['id']);
      final land = _text(_optionalObjekt(daten['attributes'])['country']);

      setState(() {
        _land = land;
        _apiErgebnis =
            'Verbindung erfolgreich ✓\n'
            'HTTP 200 – Benutzerdaten gelesen\n\n'
            'TIDAL-Benutzer-ID: ${id ?? 'unbekannt'}\n'
            'Land: ${land ?? 'nicht übermittelt'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiErgebnis = _fehlerText(e);
      });
    } finally {
      client.close();

      if (mounted) {
        setState(() {
          _beschaeftigt = false;
        });
      }
    }
  }

  Future<void> _bibliothekImHintergrundAktualisieren() async {
    if (_hintergrundAktualisierung || !_hatToken || !mounted) return;
    final sitzungsVersion = _auth.epoch;

    setState(() {
      _hintergrundAktualisierung = true;
      _albenStatus =
          'Lokale Bibliothek aktiv · TIDAL-Abgleich läuft im Hintergrund ...';
    });

    final client = http.Client();
    final map = <String, Album>{};
    final geseheneCursor = <String>{};
    var seiten = 0;
    String? cursor;

    try {
      do {
        if (cursor != null && !geseheneCursor.add(cursor)) {
          throw const FormatException(
            'Wiederholter Sammlungs-Cursor bei Hintergrundaktualisierung.',
          );
        }

        final seite = await _seiteLesen(client, cursor);

        for (final album in seite.alben) {
          map[album.id] = album;
        }

        seiten++;
        cursor = seite.naechsterCursor;
      } while (cursor != null);

      if (!mounted || _auth.epoch != sitzungsVersion) return;
      final frischeAlben = map.values.toList();
      final gespeichertAm = DateTime.now();

      await LokaleDatenbank.instance.albumCacheSpeichern(
        frischeAlben,
        gespeichertAm: gespeichertAm,
      );

      if (!mounted) return;

      setState(() {
        _alben = frischeAlben;
        _seitenGeladen = seiten;
        _naechsterCursor = null;
        _geleseneCursor
          ..clear()
          ..addAll(geseheneCursor);
        _bibliothekGespeichertAm = gespeichertAm;
        _albenStatus =
            'Im Hintergrund aktualisiert ✓ – ${frischeAlben.length} Alben, '
            '$seiten Seiten.';
      });

      unawaited(LokalerCoverCache.instance.synchronisieren(frischeAlben));
    } catch (e) {
      if (!mounted) return;

      if (_istAnmeldeFehler(e)) {
        _anmeldungUngueltig();
        return;
      }

      setState(() {
        _albenStatus =
            'Lokale Bibliothek bleibt aktiv. '
            'Hintergrundaktualisierung fehlgeschlagen: ${_fehlerText(e)}';
      });
    } finally {
      client.close();

      if (mounted) {
        setState(() {
          _hintergrundAktualisierung = false;
        });
      }
    }
  }

  Future<void> _albenLaden({bool neu = false}) async {
    if (_beschaeftigt ||
        _hintergrundAktualisierung ||
        (_vollstaendig && !neu)) {
      return;
    }

    if (!await _onlineZugangPruefen() || !mounted) return;

    setState(() {
      _beschaeftigt = true;
      _ladeAlben = true;
      _stoppVorgemerkt = false;
    });

    final client = http.Client();
    var ersteSeiteErsetzt = !neu;

    try {
      while (mounted) {
        final cursor = ersteSeiteErsetzt ? _naechsterCursor : null;
        final seite = await _seiteLesen(client, cursor);

        if (!mounted) return;

        setState(() {
          if (!ersteSeiteErsetzt) {
            _sammlungLeeren();
            ersteSeiteErsetzt = true;
          }

          final map = {for (final album in _alben) album.id: album};

          for (final album in seite.alben) {
            map[album.id] = album;
          }

          _alben = map.values.toList();
          _seitenGeladen++;
          _geleseneCursor.add(cursor ?? '');
          _naechsterCursor = seite.naechsterCursor;

          _albenStatus = _vollstaendig
              ? 'Vollständig geladen ✓ – ${_alben.length} Alben, '
                    '$_seitenGeladen Seiten.'
              : '${_alben.length} Alben aus $_seitenGeladen Seiten geladen.';
        });

        if (_vollstaendig || _stoppVorgemerkt) break;
      }

      if (_vollstaendig) {
        final gespeichertAm = DateTime.now();

        try {
          await LokaleDatenbank.instance.albumCacheSpeichern(
            List<Album>.from(_alben),
            gespeichertAm: gespeichertAm,
          );

          if (mounted) {
            setState(() {
              _bibliothekGespeichertAm = gespeichertAm;
            });

            unawaited(
              LokalerCoverCache.instance.synchronisieren(
                List<Album>.from(_alben),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _lokalFehler =
                  'Bibliothek konnte lokal nicht gespeichert werden: '
                  '${e.runtimeType}';
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _albenStatus = _fehlerText(e);
      });
    } finally {
      client.close();

      if (mounted) {
        setState(() {
          _beschaeftigt = false;
          _ladeAlben = false;
          _stoppVorgemerkt = false;

          if (_vollstaendig) {
            _appSeite = AppSeite.sammlung;
          }
        });
      }
    }
  }

  void _anhalten() {
    if (!_ladeAlben || _stoppVorgemerkt) return;
    setState(() {
      _stoppVorgemerkt = true;
    });
  }

  Future<AlbumSeite> _seiteLesen(http.Client client, String? cursor) async {
    final collectionParameter = <String, String>{'sort': '-addedAt'};

    if (cursor != null) {
      collectionParameter['page[cursor]'] = cursor;
    }

    final sammlung = await _getJson(
      client,
      _sammlungsPfad,
      collectionParameter,
    );

    final ids = <String>[];

    for (final verweis in _liste(sammlung['data'])) {
      final id = _text(verweis['id']);

      if (verweis['type'] != 'albums' || id == null) {
        throw const FormatException('Ungültiger Albumverweis.');
      }

      if (!ids.contains(id)) {
        ids.add(id);
      }
    }

    final naechsterCursor = _cursorLesen(sammlung);
    final ressourcen = <String, Json>{};

    for (var start = 0; start < ids.length; start += 20) {
      final gruppe = ids.skip(start).take(20).join(',');

      String? detailCursor;
      final detailCursorGesehen = <String>{};

      do {
        final parameter = <String, String>{
          'filter[id]': gruppe,
          'include': 'artists,coverArt',
        };

        if (_land != null) {
          parameter['countryCode'] = _land!;
        }

        if (detailCursor != null) {
          parameter['page[cursor]'] = detailCursor;
        }

        final dokument = await _getJson(client, '/v2/albums', parameter);

        for (final ressource in [
          ..._liste(dokument['data']),
          ..._liste(dokument['included'] ?? []),
        ]) {
          final typ = _text(ressource['type']);
          final id = _text(ressource['id']);

          if (typ == null || id == null) {
            throw const FormatException('Ressourcenkennung fehlt.');
          }

          ressourcen['$typ:$id'] = ressource;
        }

        final weiter = _cursorLesen(dokument);

        if (weiter != null && !detailCursorGesehen.add(weiter)) {
          throw const FormatException('Wiederholter Metadaten-Cursor.');
        }

        detailCursor = weiter;
      } while (detailCursor != null);
    }

    return AlbumSeite(
      ids.map((id) => Album.ausRessourcen(id, ressourcen)).toList(),
      naechsterCursor,
    );
  }

  void _anmeldungUngueltig() {
    if (!mounted) return;

    setState(() {
      _status = 'TIDAL-Anmeldung nicht mehr gültig. Bitte erneut anmelden.';
      _appSeite = AppSeite.start;
    });
  }

  // --------------------------------------------------------------------------
  // Navigation
  // --------------------------------------------------------------------------

  Future<void> _albumOeffnen(Album album) async {
    if (_detailsOffen) return;

    FocusScope.of(context).unfocus();
    _detailsOffen = true;

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AlbumDetailPage(
            album: album,
            authService: _auth,
            land: _land,
            onAnmeldungUngueltig: _anmeldungUngueltig,
            onKategorienGeaendert: () async {
              await _kategorienLaden(erzwingen: true);
            },
          ),
        ),
      );
    } finally {
      _detailsOffen = false;
    }
  }

  Future<void> _kuenstlerOeffnen(KuenstlerOrdner ordner) async {
    // Suchfeld-Fokus vor dem Seitenwechsel lösen und die Tastatur schließen.
    FocusScope.of(context).unfocus();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KuenstlerPage(
          ordner: ordner,
          authService: _auth,
          land: _land,
          onAnmeldungUngueltig: _anmeldungUngueltig,
          onKategorienGeaendert: () async {
            await _kategorienLaden(erzwingen: true);
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Alphabet
  // --------------------------------------------------------------------------

  void _zuKuenstlerBuchstabeSpringen(
    String buchstabe,
    Map<String, int> alphabetIndex,
  ) {
    final zielIndex = alphabetIndex[buchstabe];

    if (zielIndex == null || !_kuenstlerScrollController.hasClients) {
      return;
    }

    final position = _kuenstlerScrollController.position;
    final zielOffset = zielIndex * _kuenstlerZeilenHoehe;

    _kuenstlerScrollController.animateTo(
      zielOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _alphabetLeiste(Map<String, int> alphabetIndex) {
    return SizedBox(
      width: 34,
      child: Column(
        children: _alphabet.map((buchstabe) {
          final vorhanden = alphabetIndex.containsKey(buchstabe);

          return Expanded(
            child: InkWell(
              onTap: vorhanden
                  ? () =>
                        _zuKuenstlerBuchstabeSpringen(buchstabe, alphabetIndex)
                  : null,
              child: Center(
                child: Text(
                  buchstabe,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: vorhanden ? FontWeight.bold : FontWeight.normal,
                    color: vorhanden
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Seitenaufteilung und Oberfläche
  // --------------------------------------------------------------------------

  void _sammlungOeffnen() {
    if (_alben.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _appSeite = AppSeite.sammlung;
    });
  }

  Future<void> _sammlungVonStartOeffnen() async {
    if (_alben.isEmpty) {
      _laborOeffnen();
      return;
    }

    if (!_hatToken) {
      await _login(sammlungNachLogin: true);
      return;
    }

    _sammlungOeffnen();
  }

  void _laborOeffnen() {
    FocusScope.of(context).unfocus();

    setState(() {
      _appSeite = AppSeite.labor;
    });
  }

  Future<void> _tidalStatusVomStart() async {
    if (_hatToken) {
      _laborOeffnen();
      return;
    }

    await _login();
  }

  Future<void> _aktualisierenVonStart() async {
    if (_beschaeftigt || _hintergrundAktualisierung || _ladeAlben) {
      return;
    }

    if (_alben.isEmpty) {
      _laborOeffnen();
      return;
    }

    if (!_hatToken) {
      // Nach erfolgreicher Anmeldung wird bei vorhandenem Cache bereits
      // automatisch ein Hintergrundabgleich gestartet.
      await _login();
      return;
    }

    if (!await _onlineZugangPruefen() || !mounted) return;

    await _bibliothekImHintergrundAktualisieren();
  }

  void _zurStartseite() {
    FocusScope.of(context).unfocus();

    setState(() {
      _appSeite = AppSeite.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_appSeite) {
      AppSeite.start => _startseite(),
      AppSeite.labor => _laborSeite(),
      AppSeite.sammlung => _sammlungsseite(),
    };
  }

  Widget _startseite() {
    final letzteAktualisierung = _bibliothekGespeichertAm == null
        ? 'noch nicht vorhanden'
        : _cacheZeitText(_bibliothekGespeichertAm!);

    return StartPage(
      albumAnzahl: _alben.length,
      tidalAngemeldet: _auth.hasUsableAccessToken,
      tidalSitzungGespeichert: _hatToken,
      bibliothekVorhanden: _alben.isNotEmpty,
      aktualisierungLaeuft: _hintergrundAktualisierung || _ladeAlben,
      bedienungGesperrt: _beschaeftigt || _anmeldungWirdGeladen,
      letzteAktualisierung: letzteAktualisierung,
      onSammlungOeffnen: _sammlungVonStartOeffnen,
      onLaborOeffnen: _laborOeffnen,
      onAktualisieren: _aktualisierenVonStart,
      onTidalStatus: _tidalStatusVomStart,
    );
  }

  // BEGIN TIDAL2WIIM KUENSTLEREDITOR V1
  bool _sortierEditorOffen = false;

  Future<void> _kuenstlerSortiernamenOeffnen() async {
    if (_sortierEditorOffen || _alben.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sortierEditorOffen = true;
    });
    try {
      // Frisch lesen statt eine möglicherweise ältere UI-Kopie zu verwenden.
      final einstellungen = await LokaleDatenbank.instance
          .kuenstlerEinstellungenLaden();
      if (!mounted) {
        return;
      }
      final ordner = _kuenstlerOrdnerErstellen(
        List<Album>.of(_alben),
        '',
        einstellungen,
      );
      final zeilen = [
        for (final eintrag in ordner)
          KuenstlerSortierZeile(
            id: eintrag.kuenstler.id,
            tidalName: eintrag.kuenstler.name,
            anzeigename: eintrag.anzeigename,
            gespeicherterSortiername:
                einstellungen[eintrag.kuenstler.id]?.sortiername,
          ),
      ];
      setState(() {
        _kuenstlerEinstellungen = einstellungen;
        _kuenstlerEinstellungenGeladen = true;
      });
      final gespeichert = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => KuenstlerSortiernamenPage(
            kuenstler: zeilen,
            onSpeichern:
                LokaleDatenbank.instance.kuenstlerSortiernamenSpeichern,
          ),
        ),
      );
      if (!mounted || gespeichert != true) {
        return;
      }
      // Künstlerordner und A-Z-Index entstehen beim nächsten Aufbau aus den
      // neu geladenen Einstellungen. Die übrige Sammlung bleibt unverändert.
      await _kuenstlerEinstellungenLaden(erzwingen: true);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Künstler-Sortiernamen gespeichert.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Künstlerbearbeitung konnte nicht geöffnet oder aktualisiert werden: ${e.runtimeType}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sortierEditorOffen = false;
        });
      }
    }
  }
  // END TIDAL2WIIM KUENSTLEREDITOR V1

  Widget _laborSeite() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Startseite',
          onPressed: _zurStartseite,
          icon: const Icon(Icons.home_outlined),
        ),
        title: const Text('Labor · Tidal2WiiM'),
      ),
      bottomNavigationBar: _ladeAlben
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_alben.length} Alben · $_seitenGeladen Seiten'),
                    TextButton(
                      onPressed: _stoppVorgemerkt ? null : _anhalten,
                      child: Text(
                        _stoppVorgemerkt
                            ? 'Stopp vorgemerkt'
                            : 'Nach dieser Seite anhalten',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Labor – Verbindung & Sammlung',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hier werden TIDAL-Anmeldung, Verbindung und das Laden der '
                  'Sammlung verwaltet. Die eigentliche Musikverwaltung liegt '
                  'auf der separaten Sammlungsseite.',
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Status: $_status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_beschaeftigt) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: 12),
                        SelectableText(_apiErgebnis),
                        const SizedBox(height: 8),
                        Text(_albenStatus),
                        if (_alben.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_alben.length} Alben verfügbar'
                            '${_vollstaendig ? ' · TIDAL aktuell' : ' · lokal'}',
                          ),
                        ],
                        if (_bibliothekGespeichertAm != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Lokaler Stand: '
                            '${_cacheZeitText(_bibliothekGespeichertAm!)}',
                          ),
                        ],
                        if (_hintergrundAktualisierung) ...[
                          const SizedBox(height: 8),
                          const Text('TIDAL-Abgleich läuft im Hintergrund ...'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _authBedienungGesperrt
                          ? null
                          : () {
                              unawaited(_login());
                            },
                      icon: const Icon(Icons.login),
                      label: Text(
                        _hatToken ? 'Erneut anmelden' : 'Bei TIDAL anmelden',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          _beschaeftigt || _anmeldungWirdGeladen || !_hatToken
                          ? null
                          : _verbindungPruefen,
                      icon: const Icon(Icons.cloud_done_outlined),
                      label: const Text('TIDAL-Verbindung prüfen'),
                    ),
                    if (_alben.isEmpty)
                      ElevatedButton.icon(
                        onPressed:
                            _beschaeftigt ||
                                _hintergrundAktualisierung ||
                                !_hatToken
                            ? null
                            : _albenLaden,
                        icon: const Icon(Icons.library_music_outlined),
                        label: const Text('Alle Alben laden'),
                      ),
                    if (_alben.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed:
                            _beschaeftigt ||
                                _hintergrundAktualisierung ||
                                !_hatToken
                            ? null
                            : () {
                                unawaited(
                                  _bibliothekImHintergrundAktualisieren(),
                                );
                              },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Sammlung neu laden'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _auth.hasRefreshToken
                      ? 'Anmeldung bleibt auf diesem Tablet gespeichert.'
                      : 'Nach der nächsten Anmeldung wird der Zugang hier sicher gespeichert.',
                ),
                if (_auth.storageWarning != null) ...[
                  const SizedBox(height: 8),
                  Text(_auth.storageWarning!),
                ],
                if (_hatToken || _auth.storageWarning != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _authBedienungGesperrt
                          ? null
                          : _anmeldungVergessen,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Anmeldung auf diesem Tablet vergessen',
                      ),
                    ),
                  ),
                if (_alben.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _sammlungOeffnen,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Zur Sammlung'),
                  ),
                ],
                // BEGIN TIDAL2WIIM KUENSTLEREDITOR BUTTON V1
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const ValueKey('labor-kuenstler-sortiernamen'),
                  onPressed:
                      _alben.isEmpty || _sortierEditorOffen || _lokalLaedt
                      ? null
                      : _kuenstlerSortiernamenOeffnen,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Künstler-Sortiernamen bearbeiten'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mehrere Künstler direkt in einer Liste bearbeiten. '
                  'Verwendet die lokale Bibliothek; kein TIDAL-Login erforderlich.',
                  style: TextStyle(fontSize: 12),
                ),
                // END TIDAL2WIIM KUENSTLEREDITOR BUTTON V1
                if (_lokalLaedt) ...[
                  const SizedBox(height: 18),
                  const LinearProgressIndicator(),
                ],
                if (_lokalFehler != null) ...[
                  const SizedBox(height: 12),
                  Text(_lokalFehler!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sammlungsseite() {
    final albumListe = _ansichtErstellen(_alben, _suchtext, _sortierung);

    final kuenstlerListe = _kuenstlerOrdnerErstellen(
      _alben,
      _suchtext,
      _kuenstlerEinstellungen,
    );

    final kategorieListe =
        _kategorien.where((kategorie) {
          if (_suchtext.isEmpty) return true;
          return _vergleichstext(kategorie.name)
              .contains(_vergleichstext(_suchtext));
        }).toList()..sort(
          (a, b) => _vergleichstext(a.name).compareTo(_vergleichstext(b.name)),
        );

    final alphabetIndex = _kuenstlerAlphabetIndex(kuenstlerListe);

    final body = switch (_sammlungsAnsicht) {
      SammlungAnsicht.alben => _albumAnsicht(albumListe),
      SammlungAnsicht.kuenstler => _kuenstlerAnsicht(
        kuenstlerListe,
        alphabetIndex,
      ),
      SammlungAnsicht.kategorien => _kategorienAnsicht(kategorieListe),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Startseite',
          onPressed: _zurStartseite,
          icon: const Icon(Icons.home_outlined),
        ),
        title: Text('Meine Sammlung · ${_alben.length} Alben'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _sammlungsKopfbereich(),
                ),
                const Divider(height: 1),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sammlungsKopfbereich() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<SammlungAnsicht>(
          segments: const [
            ButtonSegment<SammlungAnsicht>(
              value: SammlungAnsicht.alben,
              icon: Icon(Icons.grid_view),
              label: Text('Alle Alben'),
            ),
            ButtonSegment<SammlungAnsicht>(
              value: SammlungAnsicht.kuenstler,
              icon: Icon(Icons.folder_outlined),
              label: Text('Künstler'),
            ),
            ButtonSegment<SammlungAnsicht>(
              value: SammlungAnsicht.kategorien,
              icon: Icon(Icons.folder_special_outlined),
              label: Text('Kategorien'),
            ),
          ],
          selected: {_sammlungsAnsicht},
          onSelectionChanged: (auswahl) {
            unawaited(_ansichtWechseln(auswahl.first));
          },
        ),
        const SizedBox(height: 12),
        if (_sammlungsAnsicht == SammlungAnsicht.kategorien) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _kategorieAnlegen,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Neue Kategorie'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_lokalLaedt) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],
        if (_lokalFehler != null) ...[
          Text(_lokalFehler!),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _suchController,
          enabled: _alben.isNotEmpty,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (wert) {
            setState(() {
              _suchtext = wert;
            });
          },
          decoration: InputDecoration(
            labelText: switch (_sammlungsAnsicht) {
              SammlungAnsicht.alben => 'Künstler oder Album suchen',
              SammlungAnsicht.kuenstler => 'Künstler suchen',
              SammlungAnsicht.kategorien => 'Kategorie suchen',
            },
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _suchtext.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Suche leeren',
                    onPressed: () {
                      _suchController.clear();
                      setState(() {
                        _suchtext = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        if (_sammlungsAnsicht == SammlungAnsicht.alben) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<Sortierung>(
            initialValue: _sortierung,
            decoration: const InputDecoration(
              labelText: 'Sortierung',
              border: OutlineInputBorder(),
            ),
            items: Sortierung.values.map((wert) {
              return DropdownMenuItem<Sortierung>(
                value: wert,
                child: Text(wert.bezeichnung),
              );
            }).toList(),
            onChanged: (wert) {
              if (wert == null) return;
              setState(() {
                _sortierung = wert;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _albumAnsicht(List<Album> alben) {
    if (alben.isEmpty) {
      return const Center(child: Text('Keine Alben gefunden.'));
    }

    return GridView.builder(
      controller: _albumScrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 310,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: alben.length,
      itemBuilder: (context, index) => _albumKachel(alben[index]),
    );
  }

  Widget _kuenstlerAnsicht(
    List<KuenstlerOrdner> ordner,
    Map<String, int> alphabetIndex,
  ) {
    if (ordner.isEmpty) {
      return const Center(child: Text('Keine Künstler gefunden.'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            controller: _kuenstlerScrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
            itemExtent: _kuenstlerZeilenHoehe,
            itemCount: ordner.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _kuenstlerKachel(ordner[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 4, 8),
          child: _alphabetLeiste(alphabetIndex),
        ),
      ],
    );
  }

  Widget _kategorienAnsicht(List<Kategorie> kategorien) {
    if (kategorien.isEmpty) {
      return const Center(child: Text('Noch keine Kategorien vorhanden.'));
    }

    return ListView.separated(
      controller: _kategorieScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: kategorien.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _kategorieKachel(kategorien[index]),
    );
  }

  Widget _albumKachel(Album album) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _albumOeffnen(album),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1, child: AlbumCover(album: album)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.titel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.kuenstler,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(album.jahr?.toString() ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kuenstlerKachel(KuenstlerOrdner ordner) {
    final anzahl = ordner.alben.length;

    final sortierHinweis =
        _vergleichstext(ordner.sortiername) !=
        _vergleichstext(ordner.anzeigename);

    final untertitel = <String>[
      anzahl == 1 ? '1 Album' : '$anzahl Alben',
      if (sortierHinweis) 'Sortierung: ${ordner.sortiername}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _kuenstlerOeffnen(ordner),
        leading: const CircleAvatar(child: Icon(Icons.folder_outlined)),
        title: Text(
          ordner.anzeigename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          untertitel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Name und Sortierung bearbeiten',
              onPressed: () => _kuenstlerBearbeiten(ordner),
              icon: const Icon(Icons.edit_outlined),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _kategorieKachel(Kategorie kategorie) {
    return Card(
      child: ListTile(
        onTap: () => _kategorieOeffnen(kategorie),
        leading: const CircleAvatar(child: Icon(Icons.folder_special_outlined)),
        title: Text(kategorie.name),
        subtitle: Text(
          kategorie.albumAnzahl == 1
              ? '1 Album'
              : '${kategorie.albumAnzahl} Alben',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Umbenennen',
              onPressed: () => _kategorieUmbenennen(kategorie),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Löschen',
              onPressed: () => _kategorieLoeschen(kategorie),
              icon: const Icon(Icons.delete_outline),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
