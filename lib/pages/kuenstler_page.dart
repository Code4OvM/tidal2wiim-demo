part of '../main.dart';

// ============================================================================
// Künstlerseite
// ============================================================================

class KuenstlerPage extends StatelessWidget {
  const KuenstlerPage({
    super.key,
    required this.ordner,
    required this.authService,
    required this.onAnmeldungUngueltig,
    required this.onKategorienGeaendert,
    this.land,
  });

  final KuenstlerOrdner ordner;
  final TidalAuthService authService;
  final String? land;
  final VoidCallback onAnmeldungUngueltig;
  final Future<void> Function() onKategorienGeaendert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ordner.anzeigename)),
      body: AlbumGrid(
        alben: ordner.alben,
        authService: authService,
        land: land,
        onAnmeldungUngueltig: onAnmeldungUngueltig,
        onKategorienGeaendert: onKategorienGeaendert,
      ),
    );
  }
}
