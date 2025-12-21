import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compass Navigator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const CompassPage(),
    );
  }
}

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  double? _heading; // device heading in degrees
  Position? _position; // current GPS position
  StreamSubscription<CompassEvent?>? _compassSub;
  StreamSubscription<Position>? _positionSub;

  // Example destination: Colosseum, Rome
  final double destLat = 41.8902;
  final double destLon = 12.4922;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _initSensors() async {
    // Request permissions
    await Permission.location.request();
    if (!await Permission.location.isGranted) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Subscribe to compass updates
    _compassSub = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading;
      });
    });

    // Subscribe to position updates
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      setState(() {
        _position = pos;
      });
    });
  }

  // Calculate bearing from current position to destination (degrees)
  double _bearingTo(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = _degToRad(lat1);
    final phi2 = _degToRad(lat2);
    final deltaLambda = _degToRad(lon2 - lon1);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    return (_radToDeg(theta) + 360) % 360;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  @override
  Widget build(BuildContext context) {
    final bearing = (_position != null)
        ? _bearingTo(_position!.latitude, _position!.longitude, destLat, destLon)
        : null;

    // Angle to rotate the arrow: difference between device heading and bearing
    double? angleToDest;
    if (_heading != null && bearing != null) {
      // Convert to radians, and invert for UI rotation (clockwise)
      final diff = (bearing - _heading!) % 360;
      angleToDest = _degToRad(diff);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compass Navigator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Compass background
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 4),
                          ),
                        ),
                        // Arrow pointing to destination
                        Transform.rotate(
                          angle: angleToDest ?? 0,
                          child: Icon(
                            Icons.arrow_upward,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                        ),
                        // Small indicator for device heading (top)
                        Positioned(
                          top: 8,
                          child: Column(
                            children: [
                              Icon(Icons.navigation, color: Colors.blueGrey),
                              const SizedBox(height: 4),
                              Text(
                                _heading != null
                                    ? '${_heading!.toStringAsFixed(0)}°'
                                    : '---',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Destination: Colosseum, Rome'),
                  const SizedBox(height: 8),
                  if (_position != null) ...[
                    Text('Your position: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'),
                    const SizedBox(height: 4),
                    Text('Bearing to dest: ${bearing!.toStringAsFixed(0)}°'),
                  ] else ...[
                    const Text('Retrieving position...')
                  ],
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // request permissions again and get current position once
                await _initSensors();
                final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
                setState(() {
                  _position = pos;
                });
              },
              child: const Text('Refresh / Request Permissions'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}


