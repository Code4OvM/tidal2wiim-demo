// Die Anmeldung liegt jetzt im Labor, nicht mehr direkt auf der Startseite.
// Diese Tests prüfen die aktuelle Oberfläche und ihre Trefferflächen.
// SQLite, TIDAL, der Cover-Download und Android werden dabei nicht aufgerufen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidal2wiim/main.dart';
import 'package:tidal2wiim/services/tidal_auth_service.dart';

import 'support/memory_session_store.dart';

void _bildschirm(
  WidgetTester tester,
  Size groesse, {
  double unten = 48,
  double rechts = 0,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = groesse;
  final abstand = FakeViewPadding(top: 24, bottom: unten, right: rechts);
  tester.view.padding = abstand;
  tester.view.viewPadding = abstand;
  addTearDown(tester.view.reset);
}

Finder _key(String name) => find.byKey(ValueKey<String>(name));

// getSize allein berücksichtigt die FittedBox-Skalierung nicht.
Rect _bildschirmRechteck(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return Rect.fromPoints(
    box.localToGlobal(Offset.zero),
    box.localToGlobal(Offset(box.size.width, box.size.height)),
  );
}

StartPage _startseite({
  int alben = 473,
  bool angemeldet = true,
  bool aktualisierung = false,
  bool gesperrt = false,
  String zeit = '30.09.2026 16:00',
  VoidCallback? labor,
  Future<void> Function()? sammlung,
  Future<void> Function()? aktualisieren,
  Future<void> Function()? tidal,
}) {
  return StartPage(
    albumAnzahl: alben,
    tidalAngemeldet: angemeldet,
    bibliothekVorhanden: alben > 0,
    aktualisierungLaeuft: aktualisierung,
    bedienungGesperrt: gesperrt,
    letzteAktualisierung: zeit,
    onLaborOeffnen: labor ?? () {},
    onSammlungOeffnen: sammlung ?? () async {},
    onAktualisieren: aktualisieren ?? () async {},
    onTidalStatus: tidal ?? () async {},
  );
}

void main() {
  testWidgets('Zahnrad öffnet das Labor; dort wartet die Anmeldung', (
    tester,
  ) async {
    _bildschirm(tester, const Size(1280, 800));
    final auth = TidalAuthService(
      clientId: 'test-client',
      store: MemorySessionStore(),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      Tidal2WiiMApp(bibliothekLaden: () async => null, authService: auth),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StartPage), findsOneWidget);
    expect(_key('start-einstellungen'), findsOneWidget);
    expect(find.text('nicht angemeldet'), findsOneWidget);

    // Auf die sichtbare Zahnradposition im Bild tippen, nicht auf einen
    // beliebigen Punkt innerhalb einer eventuell falsch platzierten Fläche.
    final zeichenflaeche = tester.renderObject<RenderBox>(
      _key('start-zeichenflaeche'),
    );
    await tester.tapAt(zeichenflaeche.localToGlobal(const Offset(1207, 53)));
    await tester.pumpAndSettle();

    expect(find.text('Labor · Tidal2WiiM'), findsOneWidget);
    expect(find.text('Status: Nicht angemeldet'), findsOneWidget);

    ButtonStyleButton schaltflaeche(String beschriftung) {
      return tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(beschriftung),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
    }

    expect(schaltflaeche('Bei TIDAL anmelden').onPressed, isNotNull);
    expect(schaltflaeche('TIDAL-Verbindung prüfen').onPressed, isNull);
    expect(schaltflaeche('Alle Alben laden').onPressed, isNull);

    await tester.tap(find.byTooltip('Startseite'));
    await tester.pumpAndSettle();
    expect(find.byType(StartPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Neustart übernimmt die gespeicherte Anmeldung ohne Anmeldedialog',
    (tester) async {
      _bildschirm(tester, const Size(1280, 800));
      final store = MemorySessionStore();
      final first = TidalAuthService(clientId: 'test-client', store: store);
      await first.acceptLogin(
        TidalSession(
          accessToken: 'test-access',
          refreshToken: 'test-refresh',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      first.dispose();
      final restored = TidalAuthService(clientId: 'test-client', store: store);
      addTearDown(restored.dispose);
      await tester.pumpWidget(
        Tidal2WiiMApp(bibliothekLaden: () async => null, authService: restored),
      );
      await tester.pumpAndSettle();
      expect(find.text('angemeldet'), findsOneWidget);
      expect(restored.hasSession, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Anmeldung lässt sich im Labor ausdrücklich vergessen', (
    tester,
  ) async {
    _bildschirm(tester, const Size(1280, 800));
    final store = MemorySessionStore();
    final auth = TidalAuthService(clientId: 'test-client', store: store);
    await auth.acceptLogin(
      TidalSession(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      Tidal2WiiMApp(bibliothekLaden: () async => null, authService: auth),
    );
    await tester.pumpAndSettle();
    await tester.tap(_key('start-einstellungen'));
    await tester.pumpAndSettle();
    final button = find.text('Anmeldung auf diesem Tablet vergessen');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anmeldung vergessen'));
    await tester.pumpAndSettle();
    expect(auth.hasSession, isFalse);
    expect(store.value, isNull);
    expect(find.text('Bei TIDAL anmelden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Alle vier Startseiten-Aktionen sind antippbar', (tester) async {
    _bildschirm(tester, const Size(1280, 800));
    var labor = 0;
    var sammlung = 0;
    var tidal = 0;
    var aktualisieren = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: _startseite(
          labor: () => labor++,
          sammlung: () async {
            sammlung++;
          },
          tidal: () async {
            tidal++;
          },
          aktualisieren: () async {
            aktualisieren++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final name in [
      'start-einstellungen',
      'start-sammlung-oeffnen',
      'start-tidal',
      'start-aktualisieren',
    ]) {
      await tester.tap(_key(name));
      await tester.pumpAndSettle();
    }

    expect(labor, 1);
    expect(sammlung, 1);
    expect(tidal, 1);
    expect(aktualisieren, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Albumzahl, Status und Zeitpunkt werden aus den Daten angezeigt', (
    tester,
  ) async {
    _bildschirm(tester, const Size(1280, 800));
    await tester.pumpWidget(MaterialApp(home: _startseite()));
    await tester.pumpAndSettle();

    // Die Anzahl erscheint an genau zwei Stellen: Sammlungskarte und Fußleiste.
    expect(find.text('473 Alben'), findsNWidgets(2));
    expect(find.text('angemeldet'), findsOneWidget);
    expect(find.text('Stand: 30.09.2026 16:00'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: _startseite(
          alben: 512,
          angemeldet: false,
          zeit: '30.09.2026 17:30',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('473 Alben'), findsNothing);
    expect(find.text('512 Alben'), findsNWidgets(2));
    expect(find.text('angemeldet'), findsNothing);
    expect(find.text('nicht angemeldet'), findsOneWidget);
    expect(find.text('Stand: 30.09.2026 17:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Während eines Abgleichs bleibt Einstellungen erreichbar', (
    tester,
  ) async {
    _bildschirm(tester, const Size(1280, 800));
    var labor = 0;
    var aktualisieren = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _startseite(
          aktualisierung: true,
          labor: () => labor++,
          aktualisieren: () async {
            aktualisieren++;
          },
        ),
      ),
    );
    // Kein pumpAndSettle: Ein laufender Fortschrittsindikator animiert dauerhaft.
    await tester.pump();
    expect(find.text('Wird aktualisiert ...'), findsOneWidget);
    final aktualisierenInkWell = tester.widget<InkWell>(
      find.descendant(
        of: _key('start-aktualisieren'),
        matching: find.byType(InkWell),
      ),
    );
    expect(aktualisierenInkWell.onTap, isNull);
    await tester.tap(_key('start-einstellungen'));
    await tester.pump();
    expect(labor, 1);
    expect(aktualisieren, 0);
    expect(tester.takeException(), isNull);
  });

  // Beispielgrößen zum Testen, keine Behauptung über die Hardwareauflösung.
  for (final groesse in [
    const Size(1280, 800),
    const Size(1024, 600),
    const Size(800, 1280),
  ]) {
    testWidgets(
      'Bild und Aktionen bleiben oberhalb der Bedienleiste: $groesse',
      (tester) async {
        _bildschirm(tester, groesse, unten: 56);
        await tester.pumpWidget(MaterialApp(home: _startseite()));
        await tester.pumpAndSettle();

        final bild = _bildschirmRechteck(tester, _key('start-zeichenflaeche'));
        expect(bild.width / bild.height, closeTo(1448 / 1086, 0.001));
        expect(bild.top, greaterThanOrEqualTo(24 - 0.1));
        expect(bild.bottom, lessThanOrEqualTo(groesse.height - 56 + 0.1));
        expect(bild.left, greaterThanOrEqualTo(0));
        expect(bild.right, lessThanOrEqualTo(groesse.width));

        for (final name in [
          'start-einstellungen',
          'start-sammlung-oeffnen',
          'start-tidal',
          'start-aktualisieren',
          'start-statusleiste',
        ]) {
          final flaeche = _bildschirmRechteck(tester, _key(name));
          expect(flaeche.left, greaterThanOrEqualTo(bild.left - 0.1));
          expect(flaeche.right, lessThanOrEqualTo(bild.right + 0.1));
          expect(flaeche.bottom, lessThanOrEqualTo(bild.bottom + 0.1));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
