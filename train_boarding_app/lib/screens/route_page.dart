import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> with SingleTickerProviderStateMixin {
  // Display names (UI)
  final List<String> _stations = const [
    'Nahariya','Akko','Haifa Merkaz HaShmona','Haifa Hof HaCarmel','Binyamina',
    'Hadera West','Netanya','Herzliya','Tel Aviv University','Tel Aviv Savidor Center',
    'Tel Aviv HaShalom','Tel Aviv HaHagana','Lod','Ben Gurion Airport',
    'Modi’in Center','Jerusalem Yitzhak Navon','Ashkelon','Be’er Sheva Center','Dimona',
  ];

  // IDs matching DB keys (same order as _stations)
  final List<String> _stationIds = const [
    'nahariya','akko','haifa_merkaz','haifa_hof','binyamina',
    'hadera_west','netanya','herzliya','tlv_university','tlv_savidor',
    'tlv_hashalom','tlv_hagana','lod','ben_gurion',
    'modiin','jerusalem_navon','ashkelon','beer_sheva_center','dimona',
  ];

  static const Duration _legDuration = Duration(seconds: 20);

  late AnimationController _controller;
  late Animation<double> _progress;
  final _scrollCtrl = ScrollController();
  int _currentIndex = 0;
  static const _itemExtent = 104.0;

  Timer? _advanceTimer;

  // Firebase refs
  final DatabaseReference _cabinsRef = FirebaseDatabase.instance.ref('train/cabins');
  DatabaseReference _stationRef(String stationId) =>
      FirebaseDatabase.instance.ref('stations/$stationId');

  final List<String> _keys = const ['A','B','C','D','E','F'];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _legDuration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _startLeg();
  }

  void _startLeg() {
    _controller
      ..reset()
      ..forward();
    _advanceTimer?.cancel();
    _advanceTimer = Timer(_legDuration, () async {
      if (!mounted) return;

      // Next station the train arrives to
      final nextIndex = (_currentIndex + 1) % _stations.length;
      final stationId = _stationIds[nextIndex];

      // Process arrival: 20% alight randomly, board all lines to matching cabins, reset lines to 0
      await _processArrival(stationId);

      if (!mounted) return;
      setState(() => _currentIndex = nextIndex);
      _scrollToCurrent();
      _startLeg();
    });
  }

  Future<void> _processArrival(String stationId) async {
    // 1) Read the station lines once
    final stationSnap = await _stationRef(stationId).get();
    final stationLines = _normalizeLines(stationSnap.value);

    // 2) Transaction on /train/cabins:
    //    - randomly drop ~20% of total train passengers
    //    - then add everyone from stationLines to matching cabins
    await _cabinsRef.runTransaction((current) {
      final cabins = _normalizeCabins(current);

      // total and 20% to drop
      final total = cabins.values.fold<int>(0, (a, b) => a + b);
      int toDrop = (total * 0.20).floor();

      // Randomly remove across cabins while we have people to drop
      // (avoid infinite loop if all zeros)
      int safety = 5000;
      while (toDrop > 0 && safety-- > 0) {
        // Pick a random cabin that currently has > 0
        final candidates = _keys.where((k) => cabins[k]! > 0).toList();
        if (candidates.isEmpty) break;
        final pick = candidates[_rng.nextInt(candidates.length)];
        cabins[pick] = cabins[pick]! - 1;
        toDrop--;
      }

      // Board all waiting lines into matching cabins
      for (final k in _keys) {
        cabins[k] = (cabins[k] ?? 0) + (stationLines[k] ?? 0);
      }

      return Transaction.success(cabins);
    });

    // 3) Reset the station lines to 0 (post-transaction)
    await _stationRef(stationId).update({for (final k in _keys) k: 0});
  }

  Map<String, int> _normalizeCabins(dynamic raw) {
    final m = {for (final k in _keys) k: 0};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (m.containsKey(k)) {
          m[k] = (v is int) ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
        }
      });
    }
    return Map<String, int>.from(m);
  }

  Map<String, int> _normalizeLines(dynamic raw) {
    final m = {for (final k in _keys) k: 0};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (m.containsKey(k)) {
          m[k] = (v is int) ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
        }
      });
    }
    return Map<String, int>.from(m);
  }

  void _scrollToCurrent() {
    if (!_scrollCtrl.hasClients) return;
    final target = (_currentIndex * _itemExtent) -
        (MediaQuery.of(context).size.width / 2) +
        (_itemExtent / 2);
    _scrollCtrl.animateTo(
      target.clamp(0, (_stations.length * _itemExtent).toDouble()),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _stations[_currentIndex];
    final next = _stations[(_currentIndex + 1) % _stations.length];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Train Route Simulation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Auto-driving through all stations', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),

        // Current / Next info + progress
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current: $current', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('Next: $next', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 4),
              const Text('~20s/leg'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => LinearProgressIndicator(value: _progress.value),
          ),
        ),
        const SizedBox(height: 12),

        // Route dots
        SizedBox(
          height: 88,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            itemExtent: _itemExtent,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stations.length,
            itemBuilder: (context, i) {
              final isCurrent = i == _currentIndex;
              return _StationDot(label: _stations[i], isCurrent: isCurrent);
            },
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              _LegendDot(active: true),
              SizedBox(width: 6),
              Text('Current'),
              SizedBox(width: 16),
              _LegendDot(active: false),
              SizedBox(width: 6),
              Text('Upcoming'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _StationDot extends StatelessWidget {
  final String label;
  final bool isCurrent;
  const _StationDot({required this.label, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = isCurrent ? colorScheme.primary : colorScheme.outlineVariant;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCurrent ? 16 : 10,
            height: isCurrent ? 16 : 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCurrent ? 12 : 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final bool active;
  const _LegendDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : colorScheme.outlineVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}
