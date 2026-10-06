part of '../main.dart';

// ============================================================================
// Lokaler Cover-Cache
// ============================================================================

class LokalerCoverCache {
  LokalerCoverCache._();

  static final LokalerCoverCache instance = LokalerCoverCache._();

  static const int _paralleleDownloads = 4;

  final Map<String, Future<File?>> _laufendeDownloads = {};
  Directory? _verzeichnis;

  Future<Directory> _cacheVerzeichnis() async {
    final vorhanden = _verzeichnis;
    if (vorhanden != null) return vorhanden;

    final basis = await getDatabasesPath();
    final verzeichnis = Directory(p.join(basis, 'cover_cache'));
    await verzeichnis.create(recursive: true);
    _verzeichnis = verzeichnis;
    return verzeichnis;
  }

  int _stabilerHash(String text) {
    var hash = 0x811C9DC5;

    for (final byte in utf8.encode(text)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    return hash;
  }

  String _dateiname(Album album, String url) {
    final sichereId = album.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final hash = _stabilerHash(url).toRadixString(16).padLeft(8, '0');
    return '${sichereId}_$hash.img';
  }

  Uri? _gueltigeUri(String? url) {
    if (url == null) return null;

    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    return uri;
  }

  Future<File?> dateiFuer(Album album, {http.Client? client}) async {
    final url = album.coverUrl;
    final uri = _gueltigeUri(url);
    if (url == null || uri == null) return null;

    final verzeichnis = await _cacheVerzeichnis();
    final datei = File(p.join(verzeichnis.path, _dateiname(album, url)));

    if (await datei.exists()) {
      final laenge = await datei.length();
      if (laenge > 0) return datei;
      await datei.delete();
    }

    final schluessel = datei.path;
    final laufend = _laufendeDownloads[schluessel];
    if (laufend != null) return laufend;

    final download = _herunterladen(uri, datei, client: client);

    _laufendeDownloads[schluessel] = download;

    try {
      return await download;
    } finally {
      _laufendeDownloads.remove(schluessel);
    }
  }

  Future<File?> _herunterladen(
    Uri uri,
    File ziel, {
    http.Client? client,
  }) async {
    final eigenerClient = client == null;
    final verwendeterClient = client ?? http.Client();
    final temp = File('${ziel.path}.tmp');

    try {
      final antwort = await verwendeterClient
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (antwort.statusCode != 200 || antwort.bodyBytes.isEmpty) {
        return null;
      }

      final inhaltstyp = antwort.headers['content-type']?.toLowerCase();
      if (inhaltstyp != null && !inhaltstyp.startsWith('image/')) {
        return null;
      }

      if (await temp.exists()) {
        await temp.delete();
      }

      await temp.writeAsBytes(antwort.bodyBytes, flush: true);

      if (await ziel.exists()) {
        await ziel.delete();
      }

      return await temp.rename(ziel.path);
    } catch (_) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {
          // Aufräumen ist nur Best Effort.
        }
      }
      return null;
    } finally {
      if (eigenerClient) {
        verwendeterClient.close();
      }
    }
  }

  Future<void> synchronisieren(List<Album> alben) async {
    final mitCover = alben
        .where((album) => _gueltigeUri(album.coverUrl) != null)
        .toList(growable: false);

    if (mitCover.isEmpty) return;

    final verzeichnis = await _cacheVerzeichnis();
    final erwarteteDateien = <String>{
      for (final album in mitCover) _dateiname(album, album.coverUrl!),
    };

    try {
      await for (final eintrag in verzeichnis.list()) {
        if (eintrag is! File) continue;

        final name = p.basename(eintrag.path);
        final istCacheDatei = name.endsWith('.img') || name.endsWith('.tmp');

        if (istCacheDatei && !erwarteteDateien.contains(name)) {
          try {
            await eintrag.delete();
          } catch (_) {
            // Eine gerade benutzte Datei darf bis zum nächsten Lauf bleiben.
          }
        }
      }
    } catch (_) {
      // Ein fehlgeschlagenes Aufräumen darf die Cover-Anzeige nie blockieren.
    }

    final client = http.Client();
    var naechsterIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = naechsterIndex;
        naechsterIndex++;

        if (index >= mitCover.length) return;

        try {
          await dateiFuer(mitCover[index], client: client);
        } catch (_) {
          // Einzelne Cover dürfen den restlichen Cache-Aufbau nicht stoppen.
        }
      }
    }

    final anzahlWorker = mitCover.length < _paralleleDownloads
        ? mitCover.length
        : _paralleleDownloads;

    try {
      await Future.wait(List.generate(anzahlWorker, (_) => worker()));
    } finally {
      client.close();
    }
  }
}
