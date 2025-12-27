import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


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

  Future<void> linkPartner(String uidPartner) async {
    // 1. Prendi l'utente attualmente loggato
    final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // 2. Scrivi nel nodo users/auth.uid
        await _dbRef.child('users').child(user.uid).update({
          'partner_id': uidPartner,
          'last_login': ServerValue.timestamp,
        });
      } catch (e) {
        print("Errore durante il collegamento: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                      if((loginSucces == true) && _partnerCode.text.trim().isNotEmpty){
                        Navigator.pushNamed(
                        context,
                        '/Tapina',
                        );
                        linkPartner(_partnerCode.text.trim());
                      }else{
                        print('Login non riuscito');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[200],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('  Tapina  '),
                  ),
                  ElevatedButton(
                    onPressed: () async{
                      bool loginSucces = await login();
                      (loginSucces == true)
                          ? Navigator.pushNamed(
                              context,
                              '/Cozzetta',
                            )
                          : print('Login non riuscito');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Cozzetta'),
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
