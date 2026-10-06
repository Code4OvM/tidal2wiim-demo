import 'package:flutter_test/flutter_test.dart';
import 'package:tidal2wiim/models/kuenstler_sortierung.dart';

const _zeilen = [
  KuenstlerSortierZeile(
    id: 'peter',
    tidalName: 'Peter Gabriel',
    anzeigename: 'Peter Gabriel',
  ),
  KuenstlerSortierZeile(
    id: 'kate',
    tidalName: 'Kate Bush',
    anzeigename: 'Kate Bush',
    gespeicherterSortiername: 'Bush, Kate',
  ),
  KuenstlerSortierZeile(
    id: 'band',
    tidalName: 'Pet Shop Boys',
    anzeigename: 'Pet Shop Boys',
  ),
  KuenstlerSortierZeile(
    id: 'nils',
    tidalName: 'Nils Wülker',
    anzeigename: 'Nils Wülker',
  ),
];

void main() {
  test(
    'Startwerte übernehmen vorhandene Sortiernamen; noch keine Änderungen',
    () {
      final entwurf = KuenstlerSortierEntwurf(_zeilen);
      expect(entwurf.wertFuer('peter'), 'Peter Gabriel');
      expect(entwurf.wertFuer('kate'), 'Bush, Kate');
      expect(entwurf.hatAenderungen, isFalse);
    },
  );

  test('Nur geänderte Künstler werden zum Speichern übergeben', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    entwurf.setzen('peter', 'Gabriel, Peter');
    expect(entwurf.anzahlAenderungen, 1);
    expect(entwurf.aenderungen.single.kuenstlerId, 'peter');
    expect(entwurf.aenderungen.single.tidalName, 'Peter Gabriel');
    expect(entwurf.aenderungen.single.sortiername, 'Gabriel, Peter');
  });

  test(
    'Leer bedeutet ursprünglicher TIDAL-Name, auch bei eigenem Anzeigenamen',
    () {
      final entwurf = KuenstlerSortierEntwurf(const [
        KuenstlerSortierZeile(
          id: 'kate',
          tidalName: 'Kate Bush',
          anzeigename: 'Meine Kate',
          gespeicherterSortiername: 'Bush, Kate',
        ),
      ]);
      entwurf.setzen('kate', '   ');
      expect(entwurf.aenderungen.single.sortiername, 'Kate Bush');
      expect(entwurf.zeilen.single.anzeigename, 'Meine Kate');
    },
  );

  test('Leer ohne bisherige Anpassung bewirkt keine unnötige Änderung', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    entwurf.setzen('peter', '');
    expect(entwurf.anzahlAenderungen, 0);
  });

  test(
    'Rand-Leerzeichen ändern nicht die Bedeutung; Rohtext bleibt erhalten',
    () {
      final entwurf = KuenstlerSortierEntwurf(_zeilen);
      entwurf.setzen('kate', ' Bush, Kate  ');
      expect(entwurf.wertFuer('kate'), ' Bush, Kate  ');
      expect(entwurf.hatAenderungen, isFalse);
      entwurf.setzen('peter', ' Gabriel, Peter  ');
      expect(entwurf.aenderungen.single.sortiername, 'Gabriel, Peter');
    },
  );

  test('Änderung rückgängig machen entfernt den Änderungsmarker', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    entwurf.setzen('peter', 'Gabriel, Peter');
    entwurf.setzen('peter', 'Peter Gabriel');
    expect(entwurf.hatAenderungen, isFalse);
  });

  test(
    'Änderungen und Filter verändern niemals die anfängliche Reihenfolge',
    () {
      final entwurf = KuenstlerSortierEntwurf(_zeilen);
      final vorher = entwurf.zeilen.map((e) => e.id).toList();
      entwurf.setzen('peter', 'AAA, Peter');
      entwurf.filtern('Peter');
      expect(entwurf.zeilen.map((e) => e.id).toList(), vorher);
      expect(entwurf.filtern('').last.id, 'peter');
    },
  );

  test('Filtern und Wiederanzeigen verlieren keine Eingaben', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    entwurf.setzen('peter', 'Gabriel, Peter');
    expect(entwurf.filtern('Kate').single.id, 'kate');
    expect(entwurf.filtern('').length, 4);
    expect(entwurf.wertFuer('peter'), 'Gabriel, Peter');
  });

  test('Aktives Feld fällt beim Bearbeiten des gespeicherten Suchnamens nicht heraus', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    expect(entwurf.filtern('Bush,').single.id, 'kate');
    entwurf.setzen('kate', 'Kate Bush');
    expect(entwurf.filtern('Bush,').single.id, 'kate');
  });

  test('Suche berücksichtigt Umlaute, Großschreibung und mehrere Wörter', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    expect(entwurf.filtern('WULKER  nils').single.id, 'nils');
    expect(entwurf.filtern('unbekannt'), isEmpty);
  });

  test('Bandnamen werden nicht automatisch umgedreht', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    expect(entwurf.wertFuer('band'), 'Pet Shop Boys');
    expect(entwurf.aenderungen, isEmpty);
  });

  test('Gleiche Namen mit verschiedenen IDs bleiben getrennte Künstler', () {
    final entwurf = KuenstlerSortierEntwurf(const [
      KuenstlerSortierZeile(
        id: 'a',
        tidalName: 'John Smith',
        anzeigename: 'John Smith',
      ),
      KuenstlerSortierZeile(
        id: 'b',
        tidalName: 'John Smith',
        anzeigename: 'John Smith',
      ),
    ]);
    entwurf.setzen('a', 'Smith, John');
    expect(entwurf.aenderungen.single.kuenstlerId, 'a');
    expect(entwurf.wertFuer('b'), 'John Smith');
  });

  test('Doppelte IDs, leere Identität und unbekannte Eingabeziele werden abgewiesen', () {
    expect(
      () => KuenstlerSortierEntwurf([_zeilen.first, _zeilen.first]),
      throwsArgumentError,
    );
    expect(
      () => KuenstlerSortierEntwurf(const [
        KuenstlerSortierZeile(id: '', tidalName: 'Test', anzeigename: 'Test'),
      ]),
      throwsArgumentError,
    );
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    expect(() => entwurf.setzen('fremd', 'Name'), throwsArgumentError);
    expect(() => entwurf.wertFuer('fremd'), throwsArgumentError);
  });

  test('Ausgabelisten sind nicht von außen veränderbar', () {
    final entwurf = KuenstlerSortierEntwurf(_zeilen);
    entwurf.setzen('peter', 'Gabriel, Peter');
    expect(() => entwurf.zeilen.clear(), throwsUnsupportedError);
    expect(() => entwurf.aenderungen.clear(), throwsUnsupportedError);
  });
}
