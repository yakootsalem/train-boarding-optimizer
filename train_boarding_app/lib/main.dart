import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // keep this
import 'screens/stations_page.dart';
import 'screens/train_page.dart';
import 'screens/route_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // <-- no options needed on Android
  runApp(const TrainLineApp());
}

class TrainLineApp extends StatelessWidget {
  const TrainLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Train Line',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF146C94)),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({super.key});
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _index = 0;

  static const _titles = ['Stations', 'Train', 'Route'];
  final _pages = const [StationsPage(), TrainPage(), RoutePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.location_on_outlined), label: 'Stations'),
          NavigationDestination(icon: Icon(Icons.train_outlined), label: 'Train'),
          NavigationDestination(icon: Icon(Icons.alt_route_outlined), label: 'Route'),
        ],
      ),
    );
  }
}
