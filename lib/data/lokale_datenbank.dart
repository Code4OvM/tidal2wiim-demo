part of '../main.dart';

// ============================================================================
// Lokale SQLite-Datenbank
// ============================================================================

class LokaleDatenbank {
  LokaleDatenbank._();

  static final LokaleDatenbank instance = LokaleDatenbank._();
  static const int _version = 3;

  Database? _db;

  Future<Database> get datenbank async {
    final vorhanden = _db;
    if (vorhanden != null) return vorhanden;

    final db = await _oeffnen();
    _db = db;
    return db;
  }

  Future<Database> _oeffnen() async {
    final basis = await getDatabasesPath();
    final pfad = p.join(basis, 'tidal2wiim.db');

    return openDatabase(
      pfad,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _artistPreferencesAnlegen(db);
        await _kategorieTabellenAnlegen(db);
        await _albumCacheTabelleAnlegen(db);
      },
      onUpgrade: (db, alteVersion, neueVersion) async {
        if (alteVersion < 2) {
          await _kategorieTabellenAnlegen(db);
        }
        if (alteVersion < 3) {
          await _albumCacheTabelleAnlegen(db);
        }
      },
    );
  }

  Future<void> _artistPreferencesAnlegen(Database db) async {
    await db.execute('''
      CREATE TABLE artist_preferences (
        artist_id   TEXT PRIMARY KEY NOT NULL,
        custom_name TEXT,
        sort_name   TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _kategorieTabellenAnlegen(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT NOT NULL COLLATE NOCASE UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_albums (
        category_id INTEGER NOT NULL,
        album_id    TEXT NOT NULL,
        PRIMARY KEY (category_id, album_id),
        FOREIGN KEY (category_id)
          REFERENCES categories(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_category_albums_album
      ON category_albums(album_id)
    ''');
  }

  Future<void> _albumCacheTabelleAnlegen(Database db) async {
    await db.execute('''
      CREATE TABLE album_cache (
        album_id            TEXT PRIMARY KEY NOT NULL,
        collection_position INTEGER NOT NULL,
        title               TEXT NOT NULL,
        artists_json        TEXT NOT NULL,
        release_date        TEXT,
        cover_url           TEXT,
        metadata_missing    INTEGER NOT NULL DEFAULT 0,
        cached_at           INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_album_cache_position
      ON album_cache(collection_position)
    ''');
  }

  Future<LokaleBibliothekCache?> albumCacheLaden() async {
    final db = await datenbank;
    final zeilen = await db.query(
      'album_cache',
      orderBy: 'collection_position ASC',
    );

    if (zeilen.isEmpty) return null;

    final alben = <Album>[];

    for (final zeile in zeilen) {
      final kuenstler = <Kuenstler>[];
      final kuenstlerJson = jsonDecode(zeile['artists_json'] as String);

      for (final eintrag in _liste(kuenstlerJson)) {
        final id = _text(eintrag['id']);
        final name = _text(eintrag['name']);

        if (id != null && name != null) {
          kuenstler.add(Kuenstler(id: id, name: name));
        }
      }

      final datumText = _text(zeile['release_date']);

      alben.add(
        Album(
          id: zeile['album_id'] as String,
          titel: zeile['title'] as String,
          kuenstlerListe: kuenstler,
          erscheinungsdatum: datumText == null
              ? null
              : DateTime.tryParse(datumText),
          coverUrl: _text(zeile['cover_url']),
          metadatenFehlen: (zeile['metadata_missing'] as int? ?? 0) == 1,
        ),
      );
    }

    final gespeichertAm = DateTime.fromMillisecondsSinceEpoch(
      zeilen.first['cached_at'] as int,
    );

    return LokaleBibliothekCache(alben: alben, gespeichertAm: gespeichertAm);
  }

  Future<void> albumCacheSpeichern(
    List<Album> alben, {
    required DateTime gespeichertAm,
  }) async {
    final db = await datenbank;
    final zeitstempel = gespeichertAm.millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete('album_cache');

      final batch = txn.batch();

      for (var index = 0; index < alben.length; index++) {
        final album = alben[index];

        batch.insert('album_cache', {
          'album_id': album.id,
          'collection_position': index,
          'title': album.titel,
          'artists_json': jsonEncode(
            album.kuenstlerListe
                .map(
                  (kuenstler) => {'id': kuenstler.id, 'name': kuenstler.name},
                )
                .toList(),
          ),
          'release_date': album.erscheinungsdatum?.toIso8601String(),
          'cover_url': album.coverUrl,
          'metadata_missing': album.metadatenFehlen ? 1 : 0,
          'cached_at': zeitstempel,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, KuenstlerEinstellung>>
  kuenstlerEinstellungenLaden() async {
    final db = await datenbank;
    final zeilen = await db.query('artist_preferences');

    return {
      for (final zeile in zeilen)
        zeile['artist_id'] as String: KuenstlerEinstellung.ausMap(zeile),
    };
  }

  Future<void> kuenstlerEinstellungSpeichern(
    KuenstlerEinstellung einstellung,
  ) async {
    final db = await datenbank;
    await db.insert(
      'artist_preferences',
      einstellung.zuMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> kuenstlerEinstellungLoeschen(String kuenstlerId) async {
    final db = await datenbank;
    await db.delete(
      'artist_preferences',
      where: 'artist_id = ?',
      whereArgs: [kuenstlerId],
    );
  }

  Future<List<Kategorie>> kategorienLaden() async {
    final db = await datenbank;

    final kategorienZeilen = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE',
    );

    final zuordnungen = await db.query('category_albums');

    final map = <int, Kategorie>{};

    for (final zeile in kategorienZeilen) {
      final id = zeile['id'] as int;
      map[id] = Kategorie(id: id, name: zeile['name'] as String);
    }

    for (final zeile in zuordnungen) {
      final id = zeile['category_id'] as int;
      final albumId = zeile['album_id'] as String;
      map[id]?.albumIds.add(albumId);
    }

    final liste = map.values.toList();
    liste.sort(
      (a, b) => _vergleichstext(a.name).compareTo(_vergleichstext(b.name)),
    );

    return liste;
  }

  Future<int> kategorieAnlegen(String name) async {
    final db = await datenbank;
    final jetzt = DateTime.now().millisecondsSinceEpoch;

    return db.insert('categories', {
      'name': name.trim(),
      'created_at': jetzt,
      'updated_at': jetzt,
    });
  }

  Future<void> kategorieUmbenennen(int id, String name) async {
    final db = await datenbank;
    await db.update(
      'categories',
      {
        'name': name.trim(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> kategorieLoeschen(int id) async {
    final db = await datenbank;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<int>> kategorieIdsFuerAlbum(String albumId) async {
    final db = await datenbank;
    final zeilen = await db.query(
      'category_albums',
      columns: ['category_id'],
      where: 'album_id = ?',
      whereArgs: [albumId],
    );

    return {for (final zeile in zeilen) zeile['category_id'] as int};
  }

  Future<void> albumKategorienSetzen(
    String albumId,
    Set<int> kategorieIds,
  ) async {
    final db = await datenbank;

    await db.transaction((txn) async {
      await txn.delete(
        'category_albums',
        where: 'album_id = ?',
        whereArgs: [albumId],
      );

      for (final kategorieId in kategorieIds) {
        await txn.insert('category_albums', {
          'category_id': kategorieId,
          'album_id': albumId,
        });
      }
    });
  }
}
