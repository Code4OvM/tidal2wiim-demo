part of '../main.dart';

// ============================================================================
// Visuelle Startseite
//
// Bild, Texte und Trefferflächen benutzen EIN gemeinsames Koordinatensystem.
// Die eingebundene PNG-Datei misst 1448 x 1086 Pixel (4:3).
// Erst die gesamte Zeichenfläche wird proportional auf den sicheren,
// tatsächlich nutzbaren Bildschirmbereich verkleinert/vergrößert.
// ============================================================================

class StartPage extends StatelessWidget {
  const StartPage({
    super.key,
    required this.albumAnzahl,
    required this.tidalAngemeldet,
    required this.bibliothekVorhanden,
    required this.aktualisierungLaeuft,
    required this.letzteAktualisierung,
    required this.onSammlungOeffnen,
    required this.onLaborOeffnen,
    required this.onAktualisieren,
    required this.onTidalStatus,
    this.bedienungGesperrt = false,
    this.tidalSitzungGespeichert = false,
  });

  static const double _designBreite = 1448;
  static const double _designHoehe = 1086;

  final int albumAnzahl;
  final bool tidalAngemeldet;
  final bool tidalSitzungGespeichert;
  final bool bibliothekVorhanden;
  final bool aktualisierungLaeuft;
  final String letzteAktualisierung;
  final bool bedienungGesperrt;

  final Future<void> Function() onSammlungOeffnen;
  final VoidCallback onLaborOeffnen;
  final Future<void> Function() onAktualisieren;
  final Future<void> Function() onTidalStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B0B),
      body: SafeArea(
        // Berücksichtigt insbesondere die untere Android-Bedienleiste.
        // Keine feste Annahme über deren Höhe oder die Auflösung des Tablets.
        maintainBottomViewPadding: true,
        minimum: const EdgeInsets.all(4),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              key: const ValueKey('start-zeichenflaeche'),
              width: _designBreite,
              height: _designHoehe,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/startseite.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),

                  // Nur die Pixel der eingebrannten Beispielzahl verdecken.
                  // Die Textfläche daneben bleibt durchsichtig: kein dunkler
                  // Kasten über dem Plattenregal-Hintergrund.
                  const Positioned(
                    left: 903,
                    top: 565,
                    width: 175,
                    height: 39,
                    child: DecoratedBox(
                      key: ValueKey('start-albumzahl-flaeche'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0E0F0F), Color(0xFF0F1010)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 907,
                    top: 553,
                    width: 290,
                    height: 79,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          bibliothekVorhanden
                              ? '$albumAnzahl Alben'
                              : 'Noch keine Alben',
                          key: const ValueKey('start-albumzahl'),
                          style: const TextStyle(
                            color: Color(0xFFBDBAB5),
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Die bisherige komplette Fußleiste wird deckend ersetzt.
                  // Damit sind weder feste Beispielwerte noch alte Statussymbole
                  // sichtbar. Titel, Status und Datum werden nur einmal gezeichnet.
                  Positioned(
                    left: 35,
                    top: 930,
                    width: 1239,
                    height: 129,
                    child: _StartStatusLeiste(
                      albumAnzahl: albumAnzahl,
                      tidalAngemeldet: tidalAngemeldet,
                      tidalSitzungGespeichert: tidalSitzungGespeichert,
                      bibliothekVorhanden: bibliothekVorhanden,
                      aktualisierungLaeuft: aktualisierungLaeuft,
                      letzteAktualisierung: letzteAktualisierung,
                      bedienungGesperrt: bedienungGesperrt,
                      onAktualisieren: onAktualisieren,
                      onTidalStatus: onTidalStatus,
                    ),
                  ),

                  // Diese Flächen liegen über dem tatsächlichen Zahnrad bzw.
                  // dem goldenen Button in der unveränderten Grafik.
                  Positioned(
                    left: 1140,
                    top: 17,
                    width: 142,
                    height: 109,
                    child: _StartAktion(
                      key: const ValueKey('start-einstellungen'),
                      beschreibung: 'Einstellungen / Labor',
                      // Einstellungen bleiben auch während des Ladens erreichbar.
                      onTap: onLaborOeffnen,
                      radius: 14,
                    ),
                  ),
                  Positioned(
                    left: 904,
                    top: 691,
                    width: 480,
                    height: 76,
                    child: _StartAktion(
                      key: const ValueKey('start-sammlung-oeffnen'),
                      beschreibung: 'Sammlung öffnen',
                      onTap: bedienungGesperrt
                          ? null
                          : () => unawaited(onSammlungOeffnen()),
                      radius: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Eine tatsächlich flächige, auch für TalkBack beschriftete Schaltfläche.
// Der SizedBox.expand verhindert eine leere/zu kleine Trefferfläche.
class _StartAktion extends StatelessWidget {
  const _StartAktion({
    super.key,
    required this.beschreibung,
    required this.onTap,
    this.child,
    this.radius = 12,
  });

  final String beschreibung;
  final VoidCallback? onTap;
  final Widget? child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: beschreibung,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: beschreibung,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: const Color(0x44D3A15E),
            highlightColor: const Color(0x22D3A15E),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}

class _StartStatusLeiste extends StatelessWidget {
  const _StartStatusLeiste({
    required this.albumAnzahl,
    required this.tidalAngemeldet,
    required this.tidalSitzungGespeichert,
    required this.bibliothekVorhanden,
    required this.aktualisierungLaeuft,
    required this.letzteAktualisierung,
    required this.bedienungGesperrt,
    required this.onAktualisieren,
    required this.onTidalStatus,
  });

  final int albumAnzahl;
  final bool tidalAngemeldet;
  final bool tidalSitzungGespeichert;
  final bool bibliothekVorhanden;
  final bool aktualisierungLaeuft;
  final String letzteAktualisierung;
  final bool bedienungGesperrt;
  final Future<void> Function() onAktualisieren;
  final Future<void> Function() onTidalStatus;

  static const _hell = Color(0xFFE5E2DD);
  static const _gedaempft = Color(0xFF9C9892);
  static const _gruen = Color(0xFF25D980);
  static const _gold = Color(0xFFD1A25B);

  @override
  Widget build(BuildContext context) {
    final tidalStatus = tidalAngemeldet
        ? 'angemeldet'
        : tidalSitzungGespeichert
        ? 'gespeichert'
        : 'nicht angemeldet';
    final laden = aktualisierungLaeuft || bedienungGesperrt;

    return DecoratedBox(
      key: const ValueKey('start-statusleiste'),
      decoration: BoxDecoration(
        // Beide Farben sind vollständig undurchsichtig.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141514), Color(0xFF0C0E0D)],
        ),
        border: Border.all(color: const Color(0xFF42423C), width: 1.2),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 421,
            child: _StartAktion(
              key: const ValueKey('start-tidal'),
              beschreibung: tidalAngemeldet
                  ? 'TIDAL angemeldet. Einstellungen öffnen'
                  : 'Bei TIDAL anmelden',
              onTap: bedienungGesperrt
                  ? null
                  : () => unawaited(onTidalStatus()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 46,
                      height: 40,
                      child: CustomPaint(painter: _StartTidalZeichen()),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'TIDAL',
                      style: TextStyle(
                        color: _hell,
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  tidalAngemeldet
                                      ? Icons.check
                                      : Icons.circle_outlined,
                                  size: 24,
                                  color: tidalAngemeldet ? _gruen : _gold,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  tidalStatus,
                                  key: const ValueKey('start-tidal-status'),
                                  style: const TextStyle(
                                    color: _hell,
                                    fontSize: 21,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _kleinerText(
                            bedienungGesperrt
                                ? 'Bitte warten ...'
                                : tidalAngemeldet
                                ? 'TIDAL-Zugang aktiv'
                                : tidalSitzungGespeichert
                                ? 'Online-Prüfung ausstehend'
                                : 'Zum Anmelden tippen',
                            15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _trennlinie(),
          SizedBox(
            width: 391,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 41),
              child: Row(
                children: [
                  const SizedBox(
                    width: 45,
                    height: 52,
                    child: CustomPaint(painter: _StartBibliothekZeichen()),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Text(
                                'Bibliothek',
                                style: TextStyle(color: _hell, fontSize: 22),
                              ),
                              const SizedBox(width: 21),
                              Icon(
                                bibliothekVorhanden
                                    ? Icons.check
                                    : Icons.circle_outlined,
                                color: bibliothekVorhanden ? _gruen : _gold,
                                size: 25,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        _kleinerText(
                          bibliothekVorhanden
                              ? 'lokal verfügbar'
                              : 'noch nicht geladen',
                          16,
                        ),
                        const SizedBox(height: 4),
                        // Keine erfundene Gesamtzahl der Titel anzeigen.
                        _kleinerText('$albumAnzahl Alben', 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _trennlinie(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(42, 20, 40, 15),
              child: Column(
                children: [
                  SizedBox(
                    height: 57,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF666159)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _StartAktion(
                        key: const ValueKey('start-aktualisieren'),
                        beschreibung: 'Sammlung aktualisieren',
                        onTap: laden
                            ? null
                            : () => unawaited(onAktualisieren()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: aktualisierungLaeuft
                                    ? const CircularProgressIndicator(
                                        color: _gold,
                                        strokeWidth: 2,
                                      )
                                    : Icon(
                                        Icons.sync,
                                        size: 30,
                                        color: laden ? _gedaempft : _hell,
                                      ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    aktualisierungLaeuft
                                        ? 'Wird aktualisiert ...'
                                        : 'Sammlung aktualisieren',
                                    style: TextStyle(
                                      color: laden ? _gedaempft : _hell,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _kleinerText(
                    'Stand: $letzteAktualisierung',
                    13,
                    alignment: Alignment.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trennlinie() {
    return const SizedBox(
      width: 1,
      height: 70,
      child: ColoredBox(color: Color(0xFF3B3C36)),
    );
  }

  Widget _kleinerText(
    String text,
    double groesse, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(color: _gedaempft, fontSize: groesse, height: 1.15),
      ),
    );
  }
}

// Kleine Vektorzeichen: kein weiterer Bilddownload und kein zusätzliches Paket.
class _StartTidalZeichen extends CustomPainter {
  const _StartTidalZeichen();

  @override
  void paint(Canvas canvas, Size size) {
    final farbe = Paint()..color = const Color(0xFFF5F3EF);
    final kante = size.width / 3.2;
    final radius = kante / 2;
    for (final mitte in [
      Offset(radius, radius),
      Offset(radius + kante, radius),
      Offset(radius + 2 * kante, radius),
      Offset(radius + kante, radius + kante),
    ]) {
      final pfad = Path()
        ..moveTo(mitte.dx, mitte.dy - radius + 1)
        ..lineTo(mitte.dx + radius - 1, mitte.dy)
        ..lineTo(mitte.dx, mitte.dy + radius - 1)
        ..lineTo(mitte.dx - radius + 1, mitte.dy)
        ..close();
      canvas.drawPath(pfad, farbe);
    }
  }

  @override
  bool shouldRepaint(covariant _StartTidalZeichen oldDelegate) => false;
}

class _StartBibliothekZeichen extends CustomPainter {
  const _StartBibliothekZeichen();

  @override
  void paint(Canvas canvas, Size size) {
    final stift = Paint()
      ..color = const Color(0xFFE5E2DD)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    const links = 2.0;
    final rechts = size.width - 2;
    final breite = rechts - links;
    canvas.drawOval(Rect.fromLTWH(links, 2, breite, 16), stift);
    final pfad = Path()
      ..moveTo(links, 10)
      ..lineTo(links, 39)
      ..cubicTo(links, 52, rechts, 52, rechts, 39)
      ..lineTo(rechts, 10)
      ..moveTo(links, 23)
      ..cubicTo(links + 4, 34, rechts - 4, 34, rechts, 23)
      ..moveTo(links, 32)
      ..cubicTo(links + 4, 43, rechts - 4, 43, rechts, 32);
    canvas.drawPath(pfad, stift);
  }

  @override
  bool shouldRepaint(covariant _StartBibliothekZeichen oldDelegate) => false;
}
