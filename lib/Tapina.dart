import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';





//PARTE FUNZIONALE E DI LAYOUT
class TapinaPage extends StatefulWidget {
  const TapinaPage({super.key});

  @override
  State<TapinaPage> createState() => _TapinaPageState();
}


class _TapinaPageState extends State<TapinaPage> {
  double? _heading; // la direzione a cui punta il dispositivo in gradi (0 quando si apre l'app)
  Position? _position; // la posizione GPS corrente del dispositivo
  StreamSubscription<CompassEvent?>? _compassSub;
  StreamSubscription<Position>? _positionSub;


  //BISOGNA INSERIRE LE COORDINATE DI COZZETTA
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
    // Richiede i permessi
    await Permission.location.request();
    if (!await Permission.location.isGranted) return;

    // Verifica che il servizio di Geolocalizzazione sia attivo
    if (!await Geolocator.isLocationServiceEnabled()) {
      // Il servizio di Geolocalizzazione non e' attivo
      return;
    }

    // Verifica che i permessi di Geolocalizzazione siano stati dati
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Ascolta i movimenti del telefono
    _compassSub = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading;
      });
    });

    // Ascolta i cambi di posizione del telefono
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      setState(() {
        _position = pos;
      });
    });
  }

  // Funzioni ausiliari
  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  // Calcola la direzione dalla posizione attuale alla destinazione in gradi
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String my_Id = args['myId'];
    final String partner_Id = args['partnerId'];

    final bearing = (_position != null)
        ? _bearingTo(_position!.latitude, _position!.longitude, destLat, destLon)
        : null;

    // Angolo di rotazione della freccia: differenza tra dove il telefono punta (_heading) e la direzione della destinazione (bearing)
    double? angleToDest;
    if (_heading != null && bearing != null) {
      // Convert to radians, and invert for UI rotation (clockwise)
      final diff = (bearing - _heading!) % 360;
      angleToDest = _degToRad(diff);
    }

    double dialAngle = (_heading ?? 0) * (math.pi / 180) * -1;
    double? fixedHeading;
    String directionHint = '---';

    if (bearing != null && _heading != null) {
      fixedHeading = (bearing - _heading!) ;
      if ((fixedHeading > 10 && fixedHeading < 170) || fixedHeading < -190) {
        directionHint = 'A destra Amore! 🥺';
      } else if ((fixedHeading < -10 && fixedHeading > -170) || fixedHeading > 190) {
        directionHint = 'A sinistra Amore! 🥺';
      } else if (fixedHeading >= -10 && fixedHeading <= 10){
        directionHint = 'Di qua Amore! 🥰';
      }else{
        directionHint = 'Indietro Amore! 😭';
      }
    }
    return Scaffold(
      //backgroundColor: Color.fromARGB(255, 253, 244, 245),
      appBar: AppBar(
        //backgroundColor: Color.fromARGB(255, 253, 244, 245),
        automaticallyImplyLeading: false,
        title: Text(
          'DOV\'E\' LA MIA COZZETTA?',
          style: TextStyle(
              fontSize: 35.0,
              fontFamily: 'Lemon',
              letterSpacing: 2,
              color: Color.fromARGB(
                  255, 252, 170, 208)
          ),
        ),
        centerTitle: true,
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
                  Padding(
                    padding: EdgeInsetsGeometry.all(0),
                    child: Text(
                      fixedHeading != null
                          ? directionHint
                          : 'Sto cercando il tuo Amore...',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Lemon'
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 500,
                    height: 500,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sfondo della bussola
                        Transform.rotate(
                          angle: dialAngle ?? 0,
                          child: SizedBox(
                            width: 2000,
                            height: 2000,
                            /*
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 4),
                            ),
                            */
                            child: Image(
                              image: AssetImage('assets/Punti Cardinali Bussola.png'),
                            ),
                          ),
                        ),
                        // La freccia punta verso la destinazione desiderata
                        Transform.rotate(
                          angle: angleToDest ?? 0,
                          child: Column(
                            spacing: 0,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.flip(
                                flipY: true,
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.red[800],
                                  size: 70,
                                ),
                              ),
                              Icon(
                                Icons.more_vert,
                                size: 67.2,
                                color: Colors.red[800],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],


              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // request permissions again and get current position once
                await _initSensors();
                final pos = await Geolocator.getCurrentPosition();
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