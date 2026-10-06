part of '../main.dart';

// ============================================================================
// Cover-Widget
// ============================================================================

class AlbumCover extends StatefulWidget {
  const AlbumCover({super.key, required this.album});

  final Album album;

  @override
  State<AlbumCover> createState() => _AlbumCoverState();
}

class _AlbumCoverState extends State<AlbumCover> {
  late Future<File?> _coverDatei;

  @override
  void initState() {
    super.initState();
    _coverDatei = LokalerCoverCache.instance.dateiFuer(widget.album);
  }

  @override
  void didUpdateWidget(covariant AlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.album.id != widget.album.id ||
        oldWidget.album.coverUrl != widget.album.coverUrl) {
      _coverDatei = LokalerCoverCache.instance.dateiFuer(widget.album);
    }
  }

  Widget _platzhalter() {
    return const ColoredBox(
      color: Colors.black12,
      child: Center(child: Icon(Icons.album_outlined, size: 48)),
    );
  }

  Widget _ladeAnzeige() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _netzFallback(String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      cacheWidth: 640,
      loadingBuilder: (context, child, fortschritt) {
        if (fortschritt == null) return child;
        return _ladeAnzeige();
      },
      errorBuilder: (context, error, stackTrace) => _platzhalter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.album.coverUrl;
    if (url == null) return _platzhalter();

    return FutureBuilder<File?>(
      future: _coverDatei,
      builder: (context, snapshot) {
        final datei = snapshot.data;

        if (datei != null) {
          return Image.file(
            datei,
            fit: BoxFit.contain,
            cacheWidth: 640,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return _netzFallback(url);
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ladeAnzeige();
        }

        return _netzFallback(url);
      },
    );
  }
}
