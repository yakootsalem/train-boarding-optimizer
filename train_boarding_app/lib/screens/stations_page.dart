import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});
  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  // 🟩 Realistic Israeli stations (north → south)
  final Map<String, String> _stationLabels = const {
    'nahariya': 'Nahariya',
    'akko': 'Akko',
    'haifa_merkaz': 'Haifa Merkaz HaShmona',
    'haifa_hof': 'Haifa Hof HaCarmel',
    'binyamina': 'Binyamina',
    'hadera_west': 'Hadera West',
    'netanya': 'Netanya',
    'herzliya': 'Herzliya',
    'tlv_university': 'Tel Aviv University',
    'tlv_savidor': 'Tel Aviv Savidor Center',
    'tlv_hashalom': 'Tel Aviv HaShalom',
    'tlv_hagana': 'Tel Aviv HaHagana',
    'lod': 'Lod',
    'ben_gurion': 'Ben Gurion Airport',
    'modiin': 'Modi’in Center',
    'jerusalem_navon': 'Jerusalem Yitzhak Navon',
    'ashkelon': 'Ashkelon',
    'beer_sheva_center': 'Be’er Sheva Center',
    'dimona': 'Dimona',
  };

  String _selectedStation = 'tlv_savidor';
  static const List<String> _lineOrder = ['A', 'B', 'C', 'D', 'E', 'F'];

  DatabaseReference get _stationRef =>
      FirebaseDatabase.instance.ref('stations/$_selectedStation');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 Station dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select station',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStation,
                items: _stationLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedStation = v);
                },
              ),
            ),
          ),
        ),

        // 🔹 Live grid of lines (A–F) from Realtime DB
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<DatabaseEvent>(
              stream: _stationRef.onValue,
              builder: (context, snap) {
                final counts = _normalizeLines(snap.data?.snapshot.value);

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5, // smaller cards
                  children: _lineOrder.map((line) {
                    final n = counts[line] ?? 0;
                    return Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Line $line',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                '$n',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              const Text('waiting'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),

        // 🔹 "Get Line" button (choose shortest + atomic +1 + popup)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: const Text('Get Line'),
                onPressed: _assignLinePopup,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Normalize snapshot into {A..F: int}, default 0 if missing
  Map<String, int> _normalizeLines(dynamic raw) {
    final m = {for (final l in _lineOrder) l: 0};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (m.containsKey(k)) {
          m[k] = (v is int) ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
        }
      });
    }
    return m;
  }

  /// Choose shortest line, increment atomically, and show a dialog.
  Future<void> _assignLinePopup() async {
    try {
      // Read once to decide
      final snap = await _stationRef.get();
      final counts = _normalizeLines(snap.value);

      String best = _lineOrder.first;
      int bestVal = counts[best]!;
      for (final l in _lineOrder.skip(1)) {
        final v = counts[l]!;
        if (v < bestVal) {
          best = l;
          bestVal = v;
        }
      }

      // Atomic increment with transaction
      await _stationRef.child(best).runTransaction((current) {
        final n = (current as int?) ?? 0;
        return Transaction.success(n + 1);
      });

      if (!mounted) return;
      final stationName = _stationLabels[_selectedStation] ?? _selectedStation;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assigned Line'),
          content: Text('Please go to Line $best at $stationName.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to assign a line: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
