part of '../main.dart';

// ============================================================================
// Dialoge
// ============================================================================

class _KategorieNameDialog extends StatefulWidget {
  const _KategorieNameDialog({required this.titel, this.startwert = ''});

  final String titel;
  final String startwert;

  @override
  State<_KategorieNameDialog> createState() => _KategorieNameDialogState();
}

class _KategorieNameDialogState extends State<_KategorieNameDialog> {
  late final TextEditingController _controller;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.startwert);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _speichern() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _fehler = 'Bitte einen Namen eingeben.';
      });
      return;
    }

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titel),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _speichern(),
        decoration: InputDecoration(
          labelText: 'Name',
          errorText: _fehler,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _speichern, child: const Text('Speichern')),
      ],
    );
  }
}

class _KuenstlerDialogErgebnis {
  const _KuenstlerDialogErgebnis({
    this.einstellung,
    this.zuruecksetzen = false,
  });

  final KuenstlerEinstellung? einstellung;
  final bool zuruecksetzen;
}

class _KuenstlerBearbeitenDialog extends StatefulWidget {
  const _KuenstlerBearbeitenDialog({
    required this.kuenstlerId,
    required this.tidalName,
    this.bestehend,
  });

  final String kuenstlerId;
  final String tidalName;
  final KuenstlerEinstellung? bestehend;

  @override
  State<_KuenstlerBearbeitenDialog> createState() =>
      _KuenstlerBearbeitenDialogState();
}

class _KuenstlerBearbeitenDialogState
    extends State<_KuenstlerBearbeitenDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _sortierController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.bestehend?.eigenerName ?? '',
    );

    _sortierController = TextEditingController(
      text: widget.bestehend?.sortiername ?? widget.tidalName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortierController.dispose();
    super.dispose();
  }

  void _speichern() {
    final eigenerName = _nameController.text.trim();
    var sortiername = _sortierController.text.trim();

    if (sortiername.isEmpty) {
      sortiername = widget.tidalName;
    }

    Navigator.pop(
      context,
      _KuenstlerDialogErgebnis(
        einstellung: KuenstlerEinstellung(
          kuenstlerId: widget.kuenstlerId,
          eigenerName: eigenerName.isEmpty ? null : eigenerName,
          sortiername: sortiername,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Künstler lokal anpassen'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TIDAL-Name: ${widget.tidalName}'),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Eigener Anzeigename (optional)',
                hintText: 'Leer = TIDAL-Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sortierController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _speichern(),
              decoration: const InputDecoration(
                labelText: 'Sortiername',
                hintText: 'z. B. Gabriel, Peter',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              const _KuenstlerDialogErgebnis(zuruecksetzen: true),
            );
          },
          child: const Text('Zurücksetzen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _speichern, child: const Text('Speichern')),
      ],
    );
  }
}

class _AlbumKategorienDialog extends StatefulWidget {
  const _AlbumKategorienDialog({
    required this.kategorien,
    required this.auswahl,
  });

  final List<Kategorie> kategorien;
  final Set<int> auswahl;

  @override
  State<_AlbumKategorienDialog> createState() => _AlbumKategorienDialogState();
}

class _AlbumKategorienDialogState extends State<_AlbumKategorienDialog> {
  late final Set<int> _auswahl;

  @override
  void initState() {
    super.initState();
    _auswahl = Set<int>.from(widget.auswahl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kategorien zuordnen'),
      content: SizedBox(
        width: 460,
        child: ListView(
          shrinkWrap: true,
          children: widget.kategorien.map((kategorie) {
            return CheckboxListTile(
              value: _auswahl.contains(kategorie.id),
              title: Text(kategorie.name),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (aktiv) {
                setState(() {
                  if (aktiv == true) {
                    _auswahl.add(kategorie.id);
                  } else {
                    _auswahl.remove(kategorie.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _auswahl),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
