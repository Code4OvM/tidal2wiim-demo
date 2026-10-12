import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidal2wiim/models/album_export.dart';
import 'package:tidal2wiim/pages/album_excel_export_page.dart';
import 'package:tidal2wiim/services/album_excel_export.dart';

final _speichern = find.byKey(const ValueKey('excel-speichern'));
AlbumExportSnapshot _snapshot() => AlbumExportSnapshot(
  alben: [
    AlbumExportZeile(id: '1', titel: 'Album', kuenstler: ['Künstler']),
  ],
  cacheStand: DateTime(2026, 10, 12),
);

Future<void> _aufbauen(
  WidgetTester tester, {
  Future<AlbumExportSnapshot> Function()? laden,
  AlbumExcelSpeichern? speichern,
  AlbumExportJsonLesen? lesen,
  AlbumExcelErzeugen? erzeugen,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AlbumExcelExportPage(
        albumAnzahl: 1,
        snapshotLaden: laden ?? () async => _snapshot(),
        jsonLesen: lesen,
        speichern: speichern ?? (_, _) async => '/fake/Alben.xlsx',
        erzeugen: erzeugen ?? (_) async => Uint8List.fromList([1, 2, 3]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _starten(WidgetTester tester) async {
  await tester.ensureVisible(_speichern);
  await tester.pump();
  await tester.tap(_speichern);
  await tester.pump();
}

void main() {
  testWidgets(
    'Lokaler Export benötigt keinen Login und schreibt genau einmal',
    (tester) async {
      var gespeichert = 0;
      AlbumExcelDokument? dokument;
      await _aufbauen(
        tester,
        erzeugen: (d) async {
          dokument = d;
          return Uint8List.fromList([1]);
        },
        speichern: (bytes, name) async {
          gespeichert++;
          expect(bytes, [1]);
          expect(name, endsWith('.xlsx'));
          return '/fake/Alben.xlsx';
        },
      );
      await _starten(tester);
      await tester.pumpAndSettle();
      expect(gespeichert, 1);
      expect(dokument!.alben.length, 1);
      expect(
        find.textContaining('1 Alben als Excel-Datei gespeichert.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('Abbruch des Systemdialogs ist keine Erfolgsmeldung', (
    tester,
  ) async {
    await _aufbauen(tester, speichern: (_, _) async => null);
    await _starten(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Speichern abgebrochen.'), findsOneWidget);
    expect(
      find.textContaining('Alben als Excel-Datei gespeichert.'),
      findsNothing,
    );
  });
  testWidgets('Speicherfehler erlaubt erneuten Versuch', (tester) async {
    var versuche = 0;
    await _aufbauen(
      tester,
      speichern: (_, _) async {
        if (++versuche == 1) {
          throw StateError('Test');
        }
        return '/fake/Alben.xlsx';
      },
    );
    await _starten(tester);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Export oder Speichern fehlgeschlagen.'),
      findsOneWidget,
    );
    await _starten(tester);
    await tester.pumpAndSettle();
    expect(versuche, 2);
    expect(
      find.textContaining('1 Alben als Excel-Datei gespeichert.'),
      findsOneWidget,
    );
  });
  testWidgets('Während des Exports kein zweiter Start', (tester) async {
    final pending = Completer<AlbumExportSnapshot>();
    await _aufbauen(tester, laden: () => pending.future);
    await _starten(tester);
    expect(tester.widget<FilledButton>(_speichern).onPressed, isNull);
    expect(
      tester.widget<PopScope>(find.byType(PopScope).first).canPop,
      isFalse,
    );
    pending.complete(_snapshot());
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_speichern).onPressed, isNotNull);
  });
  testWidgets('Abbruch vor Dateierzeugung ruft keinen Speicherdialog auf', (
    tester,
  ) async {
    final pending = Completer<AlbumExportSnapshot>();
    var speichern = 0;
    await _aufbauen(
      tester,
      laden: () => pending.future,
      speichern: (_, _) async {
        speichern++;
        return '/fake';
      },
    );
    await _starten(tester);
    final cancel = find.byKey(const ValueKey('excel-abbrechen'));
    await tester.ensureVisible(cancel);
    await tester.pump();
    await tester.tap(cancel);
    await tester.pump();
    pending.complete(_snapshot());
    await tester.pumpAndSettle();
    expect(speichern, 0);
    expect(find.textContaining('Export abgebrochen.'), findsOneWidget);
  });
  testWidgets(
    'Leerer lokaler Cache führt nicht zu einer falschen Erfolgsmeldung',
    (tester) async {
      var gespeichert = 0;
      await _aufbauen(
        tester,
        laden: () async => AlbumExportSnapshot(alben: [], cacheStand: null),
        speichern: (_, _) async {
          gespeichert++;
          return '/fake';
        },
      );
      await _starten(tester);
      await tester.pumpAndSettle();
      expect(gespeichert, 0);
      expect(
        find.textContaining('Noch keine vollständige lokale Bibliothek'),
        findsOneWidget,
      );
    },
  );
  testWidgets('Online-Zusatzabfrage kann vor Export ausgeschaltet werden', (
    tester,
  ) async {
    var anfragen = 0;
    await _aufbauen(
      tester,
      lesen: (_) async {
        anfragen++;
        return {'data': []};
      },
    );
    final option = find.byKey(const ValueKey('excel-zusatzangaben'));
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();
    await _starten(tester);
    await tester.pumpAndSettle();
    expect(anfragen, 0);
  });
  testWidgets('Netzausfall verhindert den lokalen Excel-Export nicht', (
    tester,
  ) async {
    var gespeichert = 0;
    await _aufbauen(
      tester,
      lesen: (_) async => throw StateError('offline'),
      speichern: (_, _) async {
        gespeichert++;
        return '/fake';
      },
    );
    await _starten(tester);
    await tester.pumpAndSettle();
    expect(gespeichert, 1);
    expect(find.byKey(const ValueKey('excel-hinweis')), findsOneWidget);
    expect(
      find.textContaining('1 Alben als Excel-Datei gespeichert.'),
      findsOneWidget,
    );
  });
}