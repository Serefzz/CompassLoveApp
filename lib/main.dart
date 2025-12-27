import 'package:compass_web_app/Cozzetta.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'Tapina.dart';





// Il main runna la nostra app
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });

}

//PARTE DI INTERFACCIA
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapi&Cozzetta',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 252, 170, 208)),
      ),
      //home: const CompassPage(),
      initialRoute: '/login',
      routes: {
        '/login' : (context) => LoginPage(),
        '/Tapina' : (context) => TapinaPage(),
        '/Cozzetta' : (context) => CozzettaPage()
      },
    );
  }
}








