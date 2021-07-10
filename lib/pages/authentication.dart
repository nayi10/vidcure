import 'package:google_sign_in/google_sign_in.dart';
import 'package:vidcure/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vidcure/pages/home_page.dart';


class Authentication extends StatefulWidget {
  Authentication({Key? key}) : super(key: key);

  @override
  _AuthenticationState createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  bool _isProgress = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (ctx) => HomePage()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 50.0),
                ),
                if (_isProgress)
                  SizedBox(
                      height: 85,
                      width: 85,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      ))
              ],
            ),
            SizedBox(height: 30.0),
            TextButton.icon(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    padding: EdgeInsets.all(20.0)),
                onPressed: () => signInWithGoogle(),
                icon: Image(
                  image: AssetImage("assets/google.png"),
                  height: 20,
                  width: 20,
                  color: null,
                ),
                label: Text("Login with Google")),
          ],
        ),
      ),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    setState(() {
      _isProgress = true;
    });
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
    await googleUser!.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);
    setState(() {
      _isProgress = false;
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
    return userCredential;
  }
}
