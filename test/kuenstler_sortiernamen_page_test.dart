// Korrektur der Test-Reihenfolge: Nach enterText vor dem Speichern pumpen.
// Nur Testcode; keine Änderung an App, Datenbank oder Anmeldeverwaltung.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidal2wiim/main.dart';
import 'package:tidal2wiim/models/kuenstler_sortierung.dart';

const _daten = [
  KuenstlerSortierZeile(
    id: 'kate',
    tidalName: 'Kate Bush',
    anzeigename: 'Kate Bush',
    gespeicherterSortiername: 'Bush, Kate',
  ),
  KuenstlerSortierZeile(
    id: 'peter',
    tidalName: 'Peter Gabriel',
    anzeigename: 'Peter Gabriel',
  ),
  KuenstlerSortierZeile(
    id: 'band',
    tidalName: 'Pet Shop Boys',
    anzeigename: 'Pet Shop Boys',
  ),
];
Finder _feld(String id) => find.byKey(ValueKey('sortiername-$id'));
Finder _taste(String name) => find.byKey(ValueKey('sortierung-$name'));

Future<void> _oeffnen(
  WidgetTester tester, {
  List<KuenstlerSortierZeile> daten = _daten,
  Future<void> Function(List<KuenstlerSortierAenderung>)? speichern,
  void Function(bool?)? zurueck,
  Size groesse = const Size(1280, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = groesse;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                final ergebnis = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => KuenstlerSortiernamenPage(
                      kuenstler: daten,
                      onSpeichern: speichern ?? (_) async {},
                    ),
                  ),
                );
                zurueck?.call(ergebnis);
              },
              child: const Text('Editor öffnen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Editor öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Eingabefelder übernehmen Werte; ohne Änderung ist Speichern deaktiviert',
    (tester) async {
      await _oeffnen(tester);
      expect(
        tester.widget<TextField>(_feld('kate')).controller!.text,
        'Bush, Kate',
      );
      expect(
        tester.widget<TextField>(_feld('peter')).controller!.text,
        'Peter Gabriel',
      );
      expect(
        tester.widget<FilledButton>(_taste('speichern')).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mehrere Änderungen werden erst bei Speichern gemeinsam übergeben',
    (tester) async {
      List<KuenstlerSortierAenderung>? ergebnis;
      bool? rueckgabe;
      await _oeffnen(
        tester,
        speichern: (werte) async {
          ergebnis = werte;
        },
        zurueck: (wert) {
          rueckgabe = wert;
        },
      );
      await tester.enterText(_feld('peter'), 'Gabriel, Peter');
      await tester.enterText(_feld('kate'), '');
      await tester.pump();
      expect(ergebnis, isNull);
      expect(find.text('2 Änderungen speichern'), findsOneWidget);
      await tester.tap(_taste('speichern'));
      await tester.pumpAndSettle();
      expect(ergebnis, hasLength(2));
      expect(
        ergebnis!.firstWhere((z) => z.kuenstlerId == 'kate').sortiername,
        'Kate Bush',
      );
      expect(rueckgabe, isTrue);
      expect(find.byType(KuenstlerSortiernamenPage), findsNothing);
    },
  );

  testWidgets(
    'Abbrechen fragt nach; Weiter bearbeiten behält Text; Verwerfen speichert nichts',
    (tester) async {
      var speicherAufrufe = 0;
      await _oeffnen(
        tester,
        speichern: (_) async {
          speicherAufrufe++;
        },
      );
      await tester.enterText(_feld('peter'), 'Gabriel, Peter');
      await tester.tap(_taste('abbrechen'));
      await tester.pumpAndSettle();
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Weiter bearbeiten'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_feld('peter')).controller!.text,
        'Gabriel, Peter',
      );
      await tester.tap(_taste('abbrechen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verwerfen'));
      await tester.pumpAndSettle();
      expect(speicherAufrufe, 0);
      expect(find.byType(KuenstlerSortiernamenPage), findsNothing);
    },
  );

  testWidgets('Android-Zurück schützt ebenfalls ungespeicherte Änderungen', (
    tester,
  ) async {
    await _oeffnen(tester);
    await tester.enterText(_feld('peter'), 'Gabriel, Peter');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Änderungen verwerfen?'), findsOneWidget);
    expect(find.byType(KuenstlerSortiernamenPage), findsOneWidget);
  });

  testWidgets('Filter blendet Zeilen nur aus, Eingaben bleiben erhalten', (
    tester,
  ) async {
    await _oeffnen(tester);
    await tester.enterText(_feld('peter'), 'Gabriel, Peter');
    await tester.enterText(_taste('suche'), 'Kate');
    await tester.pumpAndSettle();
    expect(_feld('peter'), findsNothing);
    expect(_feld('kate'), findsOneWidget);
    await tester.tap(find.byTooltip('Suche leeren'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_feld('peter')).controller!.text,
      'Gabriel, Peter',
    );
  });

  testWidgets('Tab und Shift+Tab bewegen zwischen Sortierfeldern', (
    tester,
  ) async {
    await _oeffnen(tester);
    await tester.tap(_feld('kate'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_feld('band')).focusNode!.hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_feld('kate')).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weiter auf der Bildschirmtastatur bewegt zum nächsten Feld', (
    tester,
  ) async {
    await _oeffnen(tester);
    await tester.showKeyboard(_feld('kate'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_feld('band')).focusNode!.hasFocus, isTrue);
  });

  testWidgets(
    'Viele Zeilen: Text bleibt nach Wegscrollen und Rückkehr bestehen',
    (tester) async {
      final daten = List.generate(
        240,
        (i) => KuenstlerSortierZeile(
          id: '$i',
          tidalName: 'Künstler ${i.toString().padLeft(3, '0')}',
          anzeigename: 'Künstler ${i.toString().padLeft(3, '0')}',
        ),
      );
      await _oeffnen(tester, daten: daten);
      await tester.enterText(_feld('0'), 'Null, Künstler');
      await tester.drag(_taste('liste'), const Offset(0, -2400));
      await tester.pumpAndSettle();
      await tester.drag(_taste('liste'), const Offset(0, 5000));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_feld('0')).controller!.text,
        'Null, Künstler',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Speicherfehler behält Eingaben und erlaubt einen erneuten Versuch',
    (tester) async {
      var speicherVersuche = 0;
      List<KuenstlerSortierAenderung>? erfolgreichGespeichert;
      bool? rueckgabe;

      await _oeffnen(
        tester,
        speichern: (werte) async {
          speicherVersuche++;
          if (speicherVersuche == 1) {
            throw StateError('simulierter Fehler');
          }
          erfolgreichGespeichert = werte;
        },
        zurueck: (wert) {
          rueckgabe = wert;
        },
      );

      await tester.enterText(_feld('peter'), 'Gabriel, Peter');

      // enterText löst onChanged/setState aus, baut den Speichern-Button
      // aber noch nicht neu. Erst dieser Frame aktiviert den Button.
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_taste('speichern')).onPressed,
        isNotNull,
      );

      await tester.tap(_taste('speichern'));
      await tester.pumpAndSettle();

      expect(speicherVersuche, 1);
      expect(find.textContaining('Speichern fehlgeschlagen.'), findsOneWidget);
      expect(find.byType(KuenstlerSortiernamenPage), findsOneWidget);
      expect(
        tester.widget<TextField>(_feld('peter')).controller!.text,
        'Gabriel, Peter',
      );
      expect(
        tester.widget<FilledButton>(_taste('speichern')).onPressed,
        isNotNull,
      );
      expect(erfolgreichGespeichert, isNull);
      expect(rueckgabe, isNull);
      expect(tester.takeException(), isNull);

      // Den angekündigten zweiten Versuch wirklich durchführen.
      // Dieselben Eingaben müssen ohne erneutes Eintippen speicherbar sein.
      await tester.tap(_taste('speichern'));
      await tester.pumpAndSettle();

      expect(speicherVersuche, 2);
      expect(erfolgreichGespeichert, hasLength(1));
      expect(erfolgreichGespeichert!.single.kuenstlerId, 'peter');
      expect(erfolgreichGespeichert!.single.sortiername, 'Gabriel, Peter');
      expect(rueckgabe, isTrue);
      expect(find.byType(KuenstlerSortiernamenPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Während des Speicherns keine zweite Speicherung und kein Schließen',
    (tester) async {
      final ende = Completer<void>();
      var aufrufe = 0;

      await _oeffnen(
        tester,
        speichern: (_) {
          aufrufe++;
          return ende.future;
        },
      );

      await tester.enterText(_feld('peter'), 'Gabriel, Peter');

      // Auch hier muss die geänderte Oberfläche vor dem Klick aufgebaut sein.
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_taste('speichern')).onPressed,
        isNotNull,
      );

      await tester.tap(_taste('speichern'));
      // Kein pumpAndSettle: Solange ende offen ist, läuft die Ladeanimation.
      await tester.pump();

      expect(aufrufe, 1);
      expect(
        tester.widget<FilledButton>(_taste('speichern')).onPressed,
        isNull,
      );
      expect(tester.widget<TextButton>(_taste('abbrechen')).onPressed, isNull);
      expect(tester.widget<TextField>(_feld('peter')).enabled, isFalse);

      // Echte weitere Klicks sowie Android-Zurück dürfen weder nochmals
      // speichern noch den Editor während des laufenden Vorgangs schließen.
      await tester.tap(_taste('speichern'));
      await tester.tap(_taste('abbrechen'));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(KuenstlerSortiernamenPage), findsOneWidget);
      expect(aufrufe, 1);
      expect(tester.takeException(), isNull);

      ende.complete();
      await tester.pumpAndSettle();
      expect(find.byType(KuenstlerSortiernamenPage), findsNothing);
      expect(aufrufe, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final groesse in [const Size(1280, 800), const Size(800, 1280)]) {
    testWidgets(
      'Systemleiste und Tastatur lassen Speichern sichtbar: $groesse',
      (tester) async {
        await _oeffnen(tester, groesse: groesse);
        await tester.enterText(_feld('peter'), 'Gabriel, Peter');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        tester.view.padding = const FakeViewPadding(top: 24);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(_taste('speichern')).bottom,
          lessThanOrEqualTo(groesse.height - 300),
        );
        expect(
          tester.getRect(_taste('speichern')).right,
          lessThanOrEqualTo(groesse.width),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
