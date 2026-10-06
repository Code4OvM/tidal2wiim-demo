part of '../main.dart';

// ============================================================================
// Allgemeines Albumraster
// ============================================================================

class AlbumGrid extends StatelessWidget {
  const AlbumGrid({
    super.key,
    required this.alben,
    required this.authService,
    required this.onAnmeldungUngueltig,
    required this.onKategorienGeaendert,
    this.land,
  });

  final List<Album> alben;
  final TidalAuthService authService;
  final String? land;
  final VoidCallback onAnmeldungUngueltig;
  final Future<void> Function() onKategorienGeaendert;

  @override
  Widget build(BuildContext context) {
    if (alben.isEmpty) {
      return const Center(child: Text('Keine Alben in diesem Ordner.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 310,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: alben.length,
      itemBuilder: (context, index) {
        final album = alben[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AlbumDetailPage(
                    album: album,
                    authService: authService,
                    land: land,
                    onAnmeldungUngueltig: onAnmeldungUngueltig,
                    onKategorienGeaendert: onKategorienGeaendert,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 1, child: AlbumCover(album: album)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.titel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.kuenstler,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(album.jahr?.toString() ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
