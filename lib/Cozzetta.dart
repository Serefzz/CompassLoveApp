import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';


class CozzettaPage extends StatefulWidget {
  const CozzettaPage({super.key});

  @override
  State<CozzettaPage> createState() => _CozzettaPageState();
  }



class _CozzettaPageState extends State<CozzettaPage> with TickerProviderStateMixin {

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  // Controller per il cuore pulsante
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;

  // Controller per le onde radar
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // --- Configurazione Animazione Cuore ---
    // Dura 800ms per un battito realistico
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );



    // Definisce la scala: da dimensione normale (1.0) a un po' più grande (1.2)
    // Usiamo Curves.easeInOut per un movimento più naturale
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // Ripete l'animazione avanti e indietro all'infinito
    _heartController.repeat(reverse: true);


    // --- Configurazione Animazione Onde Radar ---
    // Dura 2 secondi per un'espansione lenta e continua
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Ripete l'animazione dall'inizio alla fine continuamente
    _waveController.repeat();
  }

  @override
  void dispose() {
    // È fondamentale disporre i controller per evitare memory leaks
    _heartController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void updateLocationData() async{
    if (user != null) {
      // 1. Verifica i permessi prima di iniziare
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
              try {
                // Ottieni la posizione attuale singola
                Position position = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.best,
                      distanceFilter: 1,
                    )
                );

                // Invia al tuo nodo "tracking/$uid"
                await _dbRef.child('tracking').child(user!.uid).set({
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'last_update': ServerValue.timestamp,
                });
                print('DATI INVIATI');

              } catch (e) {
                print("Errore durante l'invio della posizione: $e");
              }
      }
    }
  }

  void startPeriodicTracking() async {
    Timer? _locationTimer; // Variabile per gestire il timer


    // 2. Cancella eventuali timer precedenti per sicurezza
    _locationTimer?.cancel();

    // 3. Avvia il Timer ogni 2 minuti
    _locationTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
          try {
            updateLocationData();
            print('DATI INVIATI');

          } catch (e) {
            print("Errore durante l'invio della posizione: $e");
          }
        });


  }




  @override
  Widget build(BuildContext context) {


    startPeriodicTracking();



    return Material(
      color: Colors.black,
      child: Column(
        //backgroundColor: Colors.black.withOpacity(0.9), // Sfondo scuro per risaltare
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 80),
            child: Material(
              color: Colors.transparent,
              child: Text(
                'Fatti trovare!',
                style: TextStyle(
                  fontFamily: 'Lemon',
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 80),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. LE ONDE RADAR (Sotto il cuore)
                // Usiamo AnimatedBuilder per ridisegnare il CustomPaint ad ogni tick del controller
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      // Passiamo il valore corrente dell'animazione (da 0.0 a 1.0) al painter
                      painter: RadarWavesPainter(_waveController.value),
                      // Definiamo un'area abbastanza grande per le onde
                      child: const SizedBox(
                        width: 300,
                        height: 300,
                      ),
                    );
                  },
                ),
      
                // 2. IL CUORE PULSANTE (Sopra le onde)
                // ScaleTransition è il widget perfetto per ridimensionare basandosi su un'animazione
                ScaleTransition(
                  scale: _heartScaleAnimation,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red[800],
                    size: 80.0, // Dimensione base del cuore
                    // Aggiungiamo un'ombra leggera per staccarlo dallo sfondo
                    shadows: [
                      Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4)
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(0, 80, 0, 0),
            child: Material(
              color: Colors.transparent,
              child: Text(
                'codice partner:',
                style: TextStyle(
                  fontFamily: 'Lemon',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Text(
                user!.uid,
                style: TextStyle(
                fontFamily: 'Lemon',
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- IL CUSTOM PAINTER PER LE ONDE ---
class RadarWavesPainter extends CustomPainter {
  // Il progresso attuale dell'animazione principale (da 0.0 a 1.0)
  final double animationValue;
  // Numero di onde simultanee che vogliamo vedere
  final int waveCount = 3;

  RadarWavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Calcoliamo il centro dell'area di disegno e il raggio massimo
    final Offset center = Offset(size.width / 2, size.height / 2);
    // Il raggio massimo è metà della larghezza o altezza (il lato più corto)
    final double maxRadius = math.min(size.width, size.height) / 2;

    // Definiamo lo stile del pennello
    final Paint paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke // Solo i bordi, non riempito
      ..strokeWidth = 4.0; // Spessore dell'onda

    // Ciclo per disegnare più onde
    for (int i = 0; i < waveCount; i++) {
      // --- LOGICA CHIAVE PER ONDE MULTIPLE ---
      // Per avere più onde che non partono tutte insieme, dobbiamo sfasarle.
      // Calcoliamo un offset basato sull'indice dell'onda.
      // Esempio con 3 onde: offset 0.0, 0.33, 0.66.
      double offset = (i * (1.0 / waveCount));

      // Sommiamo l'offset al valore dell'animazione principale.
      // Usiamo l'operatore modulo (%) 1.0 per far ripartire l'onda da 0 quando arriva a 1.
      double waveProgress = (animationValue + offset) % 1.0;

      // --- Calcolo Raggio e Opacità ---
      // Il raggio corrente cresce in base al progresso
      double currentRadius = maxRadius * waveProgress;

      // L'opacità diminuisce man mano che il progresso aumenta (da 1.0 a 0.0)
      // Usiamo pow(..., 2) per farla svanire più velocemente verso la fine (effetto estetico)
      double opacity = math.pow(1.0 - waveProgress, 2).toDouble();

      // Applichiamo l'opacità al colore del pennello
      paint.color = Colors.redAccent.withOpacity(opacity);

      // Disegniamo il cerchio
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(RadarWavesPainter oldDelegate) {
    // Ridisegna ogni volta che il valore dell'animazione cambia
    return oldDelegate.animationValue != animationValue;
  }
}