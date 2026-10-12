import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidal2wiim/models/album_export.dart';
import 'package:tidal2wiim/services/album_excel_export.dart';
import 'package:tidal2wiim/services/album_export_metadaten.dart';

AlbumExportZeile album(
  String id, {
  String title = 'Testalbum',
  List<String> artists = const ['Testkünstler'],
  String? version,
  List<String> cats = const [],
  DateTime? date,
  List<String> tags = const [],
}) => AlbumExportZeile(
  id: id,
  titel: title,
  kuenstler: artists,
  version: version,
  kategorien: cats,
  erscheinungsdatum: date,
  mediaTags: tags,
);

Uint8List xlsx(List<AlbumExportZeile> alben) => albumExcelErzeugen(
  AlbumExcelDokument(alben: alben, exportiertAm: DateTime.utc(2026, 10, 12)),
);

String part(Uint8List bytes, String path) {
  final file = ZipDecoder().decodeBytes(bytes).findFile(path);
  expect(file, isNotNull, reason: path);
  return utf8.decode(file!.content);
}

void main() {
  test('Zehn vereinbarte Spalten in richtiger Reihenfolge', () {
    expect(albumExcelSpalten, [
      'Künstler',
      'Albumname inkl. Versionsangabe',
      'Erscheinungsdatum',
      'Audioqualität',
      'Kategorien',
      'TIDAL-Link',
      'TIDAL-Album-ID',
      'Genre-Vorschläge',
      'Sicherheit der Zuordnung',
      'Anmerkung',
    ]);
  });
  test(
    'Eine Zeile je ID, mehrere Ausgaben desselben Titels bleiben getrennt',
    () {
      expect(
        albumExportSortieren([album('a'), album('a'), album('b')])
            .map((a) => a.id),
        ['a', 'b'],
      );
    },
  );
  test('Mehrere Künstler und Kategorien erzeugen keine doppelten Zeilen', () {
    final xml = part(
      xlsx([
        album('a', artists: ['A', 'B'], cats: ['Jazz', 'Live']),
      ]),
      'xl/worksheets/sheet1.xml',
    );
    expect(RegExp(r'<row ').allMatches(xml).length, 2);
    expect(xml, contains('A; B'));
    expect(xml, contains('Jazz; Live'));
  });
  test('Versionszusatz wird angehängt', () {
    expect(
      album('a', title: 'Album', version: 'Deluxe Edition').albumname,
      'Album (Deluxe Edition)',
    );
  });
  for (final suffix in [
    '(Deluxe Edition)',
    '[Deluxe Edition]',
    '- Deluxe Edition',
  ]) {
    test('Vorhandener Versionszusatz bleibt einmalig: $suffix', () {
      expect(
        album('a', title: 'Album $suffix', version: 'Deluxe Edition').albumname,
        'Album $suffix',
      );
    });
  }
  test('Fehlende Version und Qualitätsangaben werden nicht geraten', () {
    final a = album('a').mitTidalAttributen({'title': 'Album'});
    expect(a.albumname, 'Album');
    expect(a.mediaTags, isEmpty);
  });
  test('Qualität bleibt Katalogangabe; unbekannte Tags bleiben erhalten', () {
    final a = album('a').mitTidalAttributen({
      'mediaTags': ['HIRES_LOSSLESS', 'DOLBY_ATMOS', 'NEW_TAG', 'NEW_TAG'],
    });
    expect(a.mediaTags, ['HIRES_LOSSLESS', 'DOLBY_ATMOS', 'NEW_TAG']);
  });
  test('Kategorien und Datum bleiben bei der Zusatzabfrage unverändert', () {
    final date = DateTime(1990, 1, 2);
    final a = album('a', date: date, cats: ['Eigene Kategorie'])
        .mitTidalAttributen({
          'releaseDate': '2026-01-01',
          'genres': ['Ignored'],
        });
    expect(a.erscheinungsdatum, date);
    expect(a.kategorien, ['Eigene Kategorie']);
  });
  test('IDs werden nicht numerisch normalisiert', () {
    expect(albumExportSortieren([album('001'), album('1')]).length, 2);
    final xml = part(xlsx([album('001')]), 'xl/worksheets/sheet1.xml');
    expect(xml, contains('<c r="G2" s="3" t="inlineStr">'));
    expect(xml, contains('>001</t>'));
  });
  test('TIDAL-Link kodiert die Album-ID als einzelnes Pfadsegment', () {
    final uri = Uri.parse(album('a/b?c&d').link);
    expect(uri.scheme, 'https');
    expect(uri.host, 'tidal.com');
    expect(uri.pathSegments, ['album', 'a/b?c&d']);
  });
  test('XML-Sonderzeichen und Umlaute bleiben gültige Texte', () {
    final xml = part(
      xlsx([album('a', title: 'Öl & <Jazz> "Live"')]),
      'xl/worksheets/sheet1.xml',
    );
    expect(xml, contains('Öl &amp; &lt;Jazz&gt; &quot;Live&quot;'));
  });
  test('Formelähnliche Texte werden niemals als Formeln exportiert', () {
    final xml = part(
      xlsx([
        album('a', title: '=1+1', artists: ['@SUM(A1)']),
      ]),
      'xl/worksheets/sheet1.xml',
    );
    expect(xml, isNot(contains('<f>')));
    expect(xml, contains('>=1+1</t>'));
    expect(xml, contains('t="inlineStr"'));
  });
  test('Literal _xHHHH_ wird vor Excel-Sonderbehandlung geschützt', () {
    final xml = part(
      xlsx([album('a', title: '_x0041_')]),
      'xl/worksheets/sheet1.xml',
    );
    expect(xml, contains('_x005F_x0041_'));
  });
  test('Datum ist numerischer Excel-Datumswert mit eigenem Format', () {
    final bytes = xlsx([album('a', date: DateTime(2024, 1, 1))]);
    expect(
      part(bytes, 'xl/worksheets/sheet1.xml'),
      contains('<c r="C2" s="5"><v>45292</v></c>'),
    );
    expect(part(bytes, 'xl/styles.xml'), contains('formatCode="dd.mm.yyyy"'));
  });
  test('Unbekanntes Datum bleibt leer statt 1900 oder null als Text', () {
    expect(
      part(xlsx([album('a')]), 'xl/worksheets/sheet1.xml'),
      contains('<c r="C2" s="5"/>'),
    );
  });
  test('Alle drei Genre-Arbeitsfelder bleiben leer', () {
    final xml = part(xlsx([album('a')]), 'xl/worksheets/sheet1.xml');
    for (final col in ['H', 'I', 'J']) {
      expect(xml, contains('<c r="${col}2" s="7"/>'));
    }
    expect(xml, contains('"hoch,mittel,unklar"'));
  });
  test('Filter und eingefrorene Kopfzeile samt ersten zwei Spalten', () {
    final xml = part(
      xlsx([album('a'), album('b')]),
      'xl/worksheets/sheet1.xml',
    );
    expect(xml, contains('<autoFilter ref="A1:J3"/>'));
    expect(xml, contains('xSplit="2" ySplit="1" topLeftCell="C2"'));
  });
  test(
    'Verlinkung verwendet nur TIDAL, keine Formel oder fremde Zieladresse',
    () {
      final xml = part(
        xlsx([album('001')]),
        'xl/worksheets/_rels/sheet1.xml.rels',
      );
      expect(xml, contains('Target="https://tidal.com/album/001"'));
    },
  );
  test('Zwei Arbeitsblätter, keine Makros', () {
    final bytes = xlsx([album('a')]);
    final workbook = part(bytes, 'xl/workbook.xml');
    expect(workbook, contains('name="Alben"'));
    expect(workbook, contains('name="Hinweise"'));
    expect(
      ZipDecoder()
          .decodeBytes(bytes)
          .files
          .any((f) => f.name.contains('vbaProject')),
      isFalse,
    );
  });
  test(
    'Leere Liste ergibt gültige Struktur ohne ungültige I2:I1-Validierung',
    () {
      final xml = part(xlsx([]), 'xl/worksheets/sheet1.xml');
      expect(xml, contains('A1:J1'));
      expect(xml, isNot(contains('dataValidations')));
    },
  );
  test(
    'Ungültige Steuerzeichen werden nicht still in die Datei geschrieben',
    () {
      expect(
        () => xlsx([album('a', title: 'abc\u0001')]),
        throwsFormatException,
      );
    },
  );
  test('Dateiname ist zeitgestempelt und Windows-tauglich', () {
    expect(
      albumExcelDateiname(DateTime(2026, 10, 12, 9, 4, 3)),
      'Tidal2WiiM_Alben_2026-10-12_090403.xlsx',
    );
  });
  test(
    'SQLite-Abbildung erhält Kategorien und fasst Mehrfachzuordnung zusammen',
    () {
      final snapshot = albumExportAusDatenbankzeilen(
        [
          {
            'album_id': '001',
            'title': 'Album',
            'artists_json': jsonEncode([
              {'id': 'a', 'name': 'A'},
              {'id': 'b', 'name': 'B'},
            ]),
            'release_date': '2020-01-02',
            'cached_at': 0,
          },
        ],
        [
          {'album_id': '001', 'name': 'Live'},
          {'album_id': '001', 'name': 'Jazz'},
          {'album_id': '001', 'name': 'Jazz'},
        ],
      );
      expect(snapshot.alben.single.kuenstler, ['A', 'B']);
      expect(snapshot.alben.single.kategorien, ['Jazz', 'Live']);
      expect(snapshot.cacheStand!.millisecondsSinceEpoch, 0);
    },
  );
  test('Defektes Künstler-JSON bricht kontrolliert ab', () {
    expect(
      () => albumExportAusDatenbankzeilen([
        {'album_id': '1', 'title': 'Album', 'artists_json': '{}'},
      ], []),
      throwsFormatException,
    );
  });
  test('Ohne Anmeldung erfolgt keine Zusatzabfrage', () async {
    final result = await albumExportMetadatenErgaenzen(
      alben: [album('1')],
      abbruch: AlbumExportAbbruch(),
    );
    expect(result.ergaenzt, 0);
    expect(result.hinweis, contains('Nur lokaler Stand'));
  });
  test(
    '45 Alben werden in drei Gruppen gelesen; keine Genres angefragt',
    () async {
      var requests = 0;
      final result = await albumExportMetadatenErgaenzen(
        alben: [for (var i = 0; i < 45; i++) album('$i')],
        abbruch: AlbumExportAbbruch(),
        land: 'DE',
        lesen: (uri) async {
          requests++;
          expect(uri.host, 'openapi.tidal.com');
          expect(uri.path, '/v2/albums');
          expect(uri.queryParameters['countryCode'], 'DE');
          final ids = uri.queryParameters['filter[id]']!.split(',');
          expect(ids.length, lessThanOrEqualTo(20));
          return {
            'data': [
              for (final id in ids)
                {
                  'id': id,
                  'type': 'albums',
                  'attributes': {
                    'title': 'Album $id',
                    'version': 'Deluxe',
                    'mediaTags': ['LOSSLESS'],
                  },
                },
            ],
          };
        },
      );
      expect(requests, 3);
      expect(result.ergaenzt, 45);
      expect(result.alben.length, 45);
    },
  );
  test(
    'Folgeseiten werden per Cursor gelesen und fremde Ressourcen ignoriert',
    () async {
      var requests = 0;
      final result = await albumExportMetadatenErgaenzen(
        alben: [album('1'), album('2')],
        abbruch: AlbumExportAbbruch(),
        lesen: (uri) async {
          requests++;
          if (requests == 1) {
            return {
              'data': [
                {
                  'id': '1',
                  'type': 'albums',
                  'attributes': {'title': 'A'},
                },
              ],
              'links': {
                'next':
                    'https://openapi.tidal.com/v2/albums?page%5Bcursor%5D=next',
              },
            };
          }
          expect(uri.queryParameters['page[cursor]'], 'next');
          return {
            'data': [
              {
                'id': '2',
                'type': 'albums',
                'attributes': {'title': 'B'},
              },
              {
                'id': 'foreign',
                'type': 'albums',
                'attributes': {'title': 'Wrong'},
              },
            ],
          };
        },
      );
      expect(result.ergaenzt, 2);
      expect(result.alben.length, 2);
      expect(requests, 2);
    },
  );
  test(
    'Ausfall bewahrt alle Albumzeilen und beendet weitere Zusatzabfragen',
    () async {
      var count = 0;
      final result = await albumExportMetadatenErgaenzen(
        alben: [for (var i = 0; i < 45; i++) album('$i')],
        abbruch: AlbumExportAbbruch(),
        lesen: (_) async {
          count++;
          throw StateError('simulierter Ausfall');
        },
      );
      expect(count, 1);
      expect(result.alben.length, 45);
      expect(result.ergaenzt, 0);
      expect(result.hinweis, contains('nicht vollständig'));
    },
  );
  test('Wiederholter Cursor erzeugt keine Endlosschleife', () async {
    var count = 0;
    final result = await albumExportMetadatenErgaenzen(
      alben: [album('1')],
      abbruch: AlbumExportAbbruch(),
      lesen: (_) async {
        count++;
        return {
          'data': [],
          'links': {
            'meta': {'nextCursor': 'same'},
          },
        };
      },
    );
    expect(count, 2);
    expect(result.hinweis, isNotNull);
  });
  test(
    'Abbruch während einer Zusatzabfrage wird nicht als Teilerfolg behandelt',
    () async {
      final cancel = AlbumExportAbbruch();
      await expectLater(
        albumExportMetadatenErgaenzen(
          alben: [album('1')],
          abbruch: cancel,
          lesen: (_) async {
            cancel.abbrechen();
            return {'data': []};
          },
        ),
        throwsA(isA<AlbumExportAbgebrochen>()),
      );
    },
  );
}