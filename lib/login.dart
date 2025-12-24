import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mail = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _partnerCode = TextEditingController();

  Future<bool> login() async {
    //Validazione minima dei dati
    if(_mail.text.trim().isEmpty || _password.text.trim().isEmpty) return false;
    //Accesso al Database con le proprie credenziali
    try {
      // Sostituisci con le credenziali inserite nella console
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _mail.text.trim(),
        password: _password.text.trim(),
      );
      return true;
    } catch (e) {
      print("Errore di login: $e");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'TROVA IL TUO AMORE',
          style: TextStyle(
            fontFamily: 'Lemon',
            fontSize: 48,
            color: Colors.red[800],

          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Chi sei?',
            style: TextStyle(
              fontFamily: 'Lemon',
              fontSize: 18,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(60, 20, 60, 20),
                child: TextField(
                  controller: _mail,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.red.shade800,
                      ),
                    ),
                    hintText: 'Mail',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(60, 0, 60, 20),
                child: TextField(
                  controller: _password,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.red.shade800,
                      ),
                    ),
                    hintText: 'Password',
                  ),
                  obscureText: true,
                ),
              ),
              Text(
                'Chi cerchi?',
                style: TextStyle(
                  fontFamily: 'Lemon',
                  fontSize: 18,
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(60, 20, 60, 20),
                child: TextField(
                  controller: _partnerCode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.red.shade800,
                      ),
                    ),
                    hintText: 'Codice Partner',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 20),
                child: Text(
                  'Sei una tapina o una cozzetta?',
                  style: TextStyle(
                    fontFamily: 'Lemon',
                    fontSize: 18,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuisce lo spazio
                children: [
                  ElevatedButton(
                    onPressed: () async{
                      bool loginSucces = await login();
                      (loginSucces == true) && _partnerCode.text.trim().isNotEmpty
                          ? Navigator.pushNamed(
                              context,
                              '/Tapina',
                              arguments: {
                                'myId': FirebaseAuth.instance.currentUser!.uid, // UID personale
                                'partnerId': _partnerCode.text.trim(), // UID del partner
                              },
                            )
                          : print(_partnerCode.text);
                    },
                    child: Text('  Tapina  '),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[200],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async{
                      login();
                    },
                    child: Text('Cozzetta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Image.asset(
            'assets/Milk_and_Mocha_characters.png'
          )
        ],
      ),
    );
  }
}
