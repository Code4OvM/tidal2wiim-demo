part of '../main.dart';

/// Liest einen konsistenten lokalen Snapshot. Ausschließlich SELECT-Abfragen;
/// weder die Tabelle noch persönliche Zuordnungen werden verändert.
Future<AlbumExportSnapshot> _albumExportSnapshotLesen() async {
  final db = await LokaleDatenbank.instance.datenbank;
  return db.transaction((txn) async {
    final alben = await txn.query(
      'album_cache',
      columns: [
        'album_id',
        'title',
        'artists_json',
        'release_date',
        'cached_at',
      ],
      orderBy: 'collection_position ASC',
    );
    final kategorien = await txn.rawQuery('''
      SELECT ca.album_id, c.name
      FROM category_albums AS ca
      INNER JOIN categories AS c ON c.id = ca.category_id
    ''');
    return albumExportAusDatenbankzeilen(alben, kategorien);
  });
}