import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PlacesDemoPage());
  }
}

class PlacesDemoPage extends StatefulWidget {
  const PlacesDemoPage({super.key});

  @override
  State<PlacesDemoPage> createState() => _PlacesDemoPageState();
}

class _PlacesDemoPageState extends State<PlacesDemoPage> {
  final _queryController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  PlaceDetails? _details;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _details = null;
    });
    try {
      final list = await searchPlace(
        query: _queryController.text,
        limit: 5,
      );
      setState(() => _predictions = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDetails(String placeId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await getPlaceDetails(placeId: placeId);
      setState(() => _details = d);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Places Flutter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _search,
              child: const Text('Search places'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, i) {
                  final p = _predictions[i];
                  return ListTile(
                    title: Text(p.primaryText),
                    subtitle: Text(p.secondaryText),
                    onTap: () => _loadDetails(p.placeId),
                  );
                },
              ),
            ),
            if (_details != null)
              Text(
                '${_details!.name}\n${_details!.formattedAddress}\n'
                '${_details!.latitude}, ${_details!.longitude}',
              ),
          ],
        ),
      ),
    );
  }
}
