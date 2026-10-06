part of '../main.dart';

// ============================================================================
// Albumdetailseite
// ============================================================================

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({
    super.key,
    required this.album,
    required this.authService,
    required this.onAnmeldungUngueltig,
    required this.onKategorienGeaendert,
    this.land,
  });

  final Album album;
  final TidalAuthService authService;
  final String? land;
  final VoidCallback onAnmeldungUngueltig;
  final Future<void> Function() onKategorienGeaendert;

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final List<AlbumTitel> _titel = [];

  List<Kategorie> _alleKategorien = [];
  Set<int> _albumKategorieIds = {};

  bool _titelLaedt = true;
  bool _kategorienLaedt = true;

  String? _titelFehler;
  String? _kategorienFehler;

  List<Kategorie> get _zugeordneteKategorien {
    final liste = _alleKategorien.where((kategorie) {
      return _albumKategorieIds.contains(kategorie.id);
    }).toList();

    liste.sort(
      (a, b) => _vergleichstext(a.name).compareTo(_vergleichstext(b.name)),
    );

    return liste;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_titelLaden());
    unawaited(_albumKategorienLaden());
  }

  Future<void> _albumKategorienLaden({bool mitLadeanzeige = true}) async {
    if (mitLadeanzeige && mounted) {
      setState(() {
        _kategorienLaedt = true;
        _kategorienFehler = null;
      });
    }

    try {
      final kategorien = await LokaleDatenbank.instance.kategorienLaden();
      final ids = await LokaleDatenbank.instance.kategorieIdsFuerAlbum(
        widget.album.id,
      );

      if (!mounted) return;

      setState(() {
        _alleKategorien = kategorien;
        _albumKategorieIds = ids;
        _kategorienLaedt = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _kategorienFehler =
            'Kategorien konnten nicht geladen werden: ${e.runtimeType}';
        _kategorienLaedt = false;
      });
    }
  }

  Future<void> _titelLaden() async {
    final client = http.Client();

    try {
      String? cursor;
      final cursorGesehen = <String>{};

      do {
        final parameter = <String, String>{'include': 'items'};

        if (widget.land != null) {
          parameter['countryCode'] = widget.land!;
        }

        if (cursor != null) {
          parameter['page[cursor]'] = cursor;
        }

        final dokument = await _apiLesen(client, widget.authService, [
          'v2',
          'albums',
          widget.album.id,
          'relationships',
          'items',
        ], parameter);

        final ressourcen = <String, Json>{};

        for (final ressource in _liste(dokument['included'] ?? [])) {
          final typ = _text(ressource['type']);
          final id = _text(ressource['id']);

          if (typ == null || id == null) continue;
          ressourcen['$typ:$id'] = ressource;
        }

        final seite = <AlbumTitel>[];

        for (final verweis in _liste(dokument['data'])) {
          final id = _text(verweis['id']);
          final typ = _text(verweis['type']);

          if (id == null || typ == null) continue;

          final resource = ressourcen['$typ:$id'];
          final attr = _optionalObjekt(resource?['attributes']);
          final meta = _optionalObjekt(verweis['meta']);

          seite.add(
            AlbumTitel(
              id: id,
              typ: typ,
              titel: _text(attr['title']) ?? 'Titel nicht übermittelt',
              nummer: meta['trackNumber'] is int
                  ? meta['trackNumber'] as int
                  : null,
              teil: meta['volumeNumber'] is int
                  ? meta['volumeNumber'] as int
                  : null,
              dauer: _dauerLesen(attr['duration']),
            ),
          );
        }

        final weiter = _cursorLesen(dokument);

        if (weiter != null && !cursorGesehen.add(weiter)) {
          throw const FormatException('Wiederholter Titellisten-Cursor.');
        }

        if (!mounted) return;

        setState(() {
          _titel.addAll(seite);
        });

        cursor = weiter;
      } while (cursor != null);

      if (!mounted) return;

      setState(() {
        _titelLaedt = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _titelFehler = _fehlerText(e);
        _titelLaedt = false;
      });

      if (_istAnmeldeFehler(e)) {
        widget.onAnmeldungUngueltig();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _kategorienBearbeiten() async {
    await _albumKategorienLaden(mitLadeanzeige: false);

    if (!mounted) return;

    if (_alleKategorien.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Noch keine Kategorie vorhanden. '
            'Bitte zuerst in der Kategorienansicht eine anlegen.',
          ),
        ),
      );
      return;
    }

    final auswahl = await showDialog<Set<int>>(
      context: context,
      builder: (_) => _AlbumKategorienDialog(
        kategorien: _alleKategorien,
        auswahl: _albumKategorieIds,
      ),
    );

    if (!mounted || auswahl == null) return;

    await LokaleDatenbank.instance.albumKategorienSetzen(
      widget.album.id,
      auswahl,
    );

    await _albumKategorienLaden();
    await widget.onKategorienGeaendert();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Kategorien gespeichert.')));
  }

  Future<void> _inTidalOeffnen() async {
    final uri = Uri(
      scheme: 'https',
      host: 'tidal.com',
      pathSegments: ['album', widget.album.id],
    );

    try {
      final gestartet = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!gestartet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TIDAL konnte nicht geöffnet werden.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TIDAL konnte nicht geöffnet werden: ${e.runtimeType}'),
        ),
      );
    }
  }

  Future<void> _titelInTidalOeffnen(AlbumTitel titel) async {
    final inhaltTyp = titel.typ == 'videos' ? 'video' : 'track';

    final uri = Uri(
      scheme: 'https',
      host: 'tidal.com',
      pathSegments: ['browse', inhaltTyp, titel.id],
    );

    try {
      final gestartet = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!gestartet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Der Titel konnte nicht in TIDAL geöffnet werden.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Der Titel konnte nicht in TIDAL geöffnet werden: ${e.runtimeType}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final teile = _titel.map((titel) => titel.teil).whereType<int>().toSet();
    final mehrteilig = teile.length > 1 || teile.any((teil) => teil > 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Albumdetails')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final infos = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.titel,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      album.kuenstler,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erscheinungsjahr: '
                      '${album.jahr?.toString() ?? 'nicht übermittelt'}',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _inTidalOeffnen,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('In TIDAL öffnen'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'In TIDAL auf ▶ tippen, um die Wiedergabe zu starten.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kategorien',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _kategorienAnzeige(),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _kategorienBearbeiten,
                      icon: const Icon(Icons.folder_special_outlined),
                      label: const Text('Kategorien zuordnen'),
                    ),
                  ],
                );

                final cover = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AlbumCover(album: album),
                  ),
                );

                if (constraints.maxWidth >= 680) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 300, child: cover),
                      const SizedBox(width: 24),
                      Expanded(child: infos),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: SizedBox(width: 340, child: cover)),
                    const SizedBox(height: 20),
                    infos,
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            Text('Titelliste', style: Theme.of(context).textTheme.titleLarge),

            if (_titelLaedt) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],

            if (_titelFehler != null) ...[
              const SizedBox(height: 10),
              Text(_titelFehler!),
            ],

            const SizedBox(height: 8),

            for (final titel in _titel)
              Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _titelInTidalOeffnen(titel),
                    leading: SizedBox(
                      width: 48,
                      child: Text(
                        mehrteilig
                            ? '${titel.teil ?? '–'}.${titel.nummer ?? '–'}'
                            : '${titel.nummer ?? '–'}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    title: Text(titel.titel),
                    subtitle: Text(
                      titel.typ == 'videos'
                          ? 'Video in TIDAL öffnen'
                          : 'Titel in TIDAL öffnen',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_dauerAnzeige(titel.dauer)),
                        const SizedBox(width: 8),
                        const Icon(Icons.open_in_new, size: 18),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _kategorienAnzeige() {
    if (_kategorienLaedt) {
      return const SizedBox(width: 180, child: LinearProgressIndicator());
    }

    if (_kategorienFehler != null) {
      return Text(_kategorienFehler!);
    }

    final zugeordnet = _zugeordneteKategorien;

    if (zugeordnet.isEmpty) {
      return const Text(
        'Keine Zuordnung',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: zugeordnet.map((kategorie) {
        return Chip(
          avatar: const Icon(Icons.folder_special_outlined, size: 18),
          label: Text(kategorie.name),
        );
      }).toList(),
    );
  }
}
