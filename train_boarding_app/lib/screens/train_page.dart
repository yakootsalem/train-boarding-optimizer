import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reference to your Firebase Realtime Database path
    final DatabaseReference cabinsRef =
        FirebaseDatabase.instance.ref().child('train/cabins');

    return StreamBuilder<DatabaseEvent>(
      stream: cabinsRef.onValue, // listens for live updates
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }
        if (!snapshot.hasData ||
            snapshot.data!.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Convert the data from Firebase into a usable Map
        final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map);

        // Make sure every cabin exists (A–F)
        final cabins = {
          'A': data['A'] ?? 0,
          'B': data['B'] ?? 0,
          'C': data['C'] ?? 0,
          'D': data['D'] ?? 0,
          'E': data['E'] ?? 0,
          'F': data['F'] ?? 0,
        };

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final crossAxisCount = width >= 600 ? 3 : 2;
            final childAspectRatio = width >= 600 ? 1.2 : 1.3;

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Train Map — Cabin Occupancy',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GridView.builder(
                      itemCount: cabins.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final cabin = cabins.keys.elementAt(index);
                        final count = cabins[cabin] ?? 0;
                        return _CabinCard(cabin: cabin, count: count);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CabinCard extends StatelessWidget {
  final String cabin;
  final int count;

  const _CabinCard({required this.cabin, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_railway, size: 28),
            const SizedBox(height: 6),
            Text(
              'Cabin $cabin',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('people', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
