part of '../main.dart';

// Ergänzung zur vorhandenen Datenbankklasse. Keine Schemaänderung.
extension KuenstlerSortierungSpeichern on LokaleDatenbank {
  Future<void> kuenstlerSortiernamenSpeichern(
    List<KuenstlerSortierAenderung> aenderungen,
  ) async {
    if (aenderungen.isEmpty) {
      return;
    }
    // Gesamte Eingabe prüfen, BEVOR die Transaktion startet.
    final ids = <String>{};
    for (final eintrag in aenderungen) {
      if (eintrag.kuenstlerId.trim().isEmpty ||
          eintrag.tidalName.trim().isEmpty) {
        throw ArgumentError('Künstler-ID und TIDAL-Name fehlen.');
      }
      if (!ids.add(eintrag.kuenstlerId)) {
        throw ArgumentError('Künstler-ID mehrfach in der Änderungsliste.');
      }
    }

    final db = await datenbank;
    final jetzt = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final eintrag in aenderungen) {
        final name = eintrag.sortiername.trim();
        final sortiername = name.isEmpty ? eintrag.tidalName.trim() : name;
        final original = eintrag.tidalName.trim();

        if (sortiername == original) {
          // Ein leer eingegebenes Feld bedeutet: wieder den TIDAL-Namen
          // benutzen. Einen eigenen Anzeigenamen dabei NICHT entfernen.
          final vorhanden = await txn.query(
            'artist_preferences',
            columns: ['custom_name'],
            where: 'artist_id = ?',
            whereArgs: [eintrag.kuenstlerId],
            limit: 1,
          );
          if (vorhanden.isEmpty) {
            continue;
          }
          if (_text(vorhanden.first['custom_name']) == null) {
            await txn.delete(
              'artist_preferences',
              where: 'artist_id = ?',
              whereArgs: [eintrag.kuenstlerId],
            );
            continue;
          }
        }

        // Nur die Sortierung aktualisieren; custom_name bleibt bytegenau
        // erhalten. Es werden ausschließlich tatsächlich geänderte IDs berührt.
        final getroffen = await txn.update(
          'artist_preferences',
          {'sort_name': sortiername, 'updated_at': jetzt},
          where: 'artist_id = ?',
          whereArgs: [eintrag.kuenstlerId],
        );
        if (getroffen == 0) {
          await txn.insert('artist_preferences', {
            'artist_id': eintrag.kuenstlerId,
            'custom_name': null,
            'sort_name': sortiername,
            'updated_at': jetzt,
          });
        }
      }
    });
  }
}
