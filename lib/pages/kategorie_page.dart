part of '../main.dart';

// ============================================================================
// Kategorie-Seite
// ============================================================================

class KategoriePage extends StatefulWidget {
  const KategoriePage({
    super.key,
    required this.kategorieId,
    required this.kategorieName,
    required this.alleAlben,
    required this.authService,
    required this.onAnmeldungUngueltig,
    required this.onKategorienGeaendert,
    this.land,
  });

  final int kategorieId;
  final String kategorieName;
  final List<Album> alleAlben;
  final TidalAuthService authService;
  final String? land;
  final VoidCallback onAnmeldungUngueltig;
  final Future<void> Function() onKategorienGeaendert;

  @override
  State<KategoriePage> createState() => _KategoriePageState();
}

class _KategoriePageState extends State<KategoriePage> {
  List<Album> _alben = [];
  int _gespeicherteAnzahl = 0;
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    unawaited(_neuLaden());
  }

  Future<void> _neuLaden() async {
    final kategorien = await LokaleDatenbank.instance.kategorienLaden();

    Kategorie? kategorie;

    for (final eintrag in kategorien) {
      if (eintrag.id == widget.kategorieId) {
        kategorie = eintrag;
        break;
      }
    }

    if (!mounted) return;

    if (kategorie == null) {
      Navigator.pop(context);
      return;
    }

    final alben = widget.alleAlben.where((album) {
      return kategorie!.albumIds.contains(album.id);
    }).toList();

    alben.sort((a, b) {
      final jahr = _jahreVergleichen(a.jahr, b.jahr);
      if (jahr != 0) return jahr;

      return _vergleichstext(a.titel).compareTo(_vergleichstext(b.titel));
    });

    setState(() {
      _alben = alben;
      _gespeicherteAnzahl = kategorie!.albumAnzahl;
      _laedt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.kategorieName)),
      body: _laedt
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${_alben.length} von $_gespeicherteAnzahl '
                    'zugeordneten Alben sind aktuell geladen.',
                  ),
                ),
                Expanded(
                  child: AlbumGrid(
                    alben: _alben,
                    authService: widget.authService,
                    land: widget.land,
                    onAnmeldungUngueltig: widget.onAnmeldungUngueltig,
                    onKategorienGeaendert: () async {
                      await _neuLaden();
                      await widget.onKategorienGeaendert();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
