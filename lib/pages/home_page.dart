import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vidcure/pages/chat_page.dart';

import './video_call.dart';
import 'authentication.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();
}

class IndexState extends State<HomePage> {
  ClientRole _role = ClientRole.Broadcaster;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (ctx) => Authentication()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
  final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton.extended(
            heroTag: 'VideoFab',
            label: Text('Video'),
            elevation: 6,
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            onPressed: onJoin,
            icon: Icon(
              Icons.video_call_rounded,
            ),
          ),
          FloatingActionButton(
            elevation: 6,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx)=>ChatPage())),
            child: Icon(Icons.chat_bubble_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 80),
              alignment: Alignment.topCenter,
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/vidcall.jpg'),
                radius: 80,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Get medical assistance'.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Call or chat with our medical experts online for a quick treatment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height:35.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              	child: ListTile(
              	leading: CircleAvatar(
                	backgroundColor: Color.fromARGB(30, 50, 50, 50),
                	foregroundImage: NetworkImage(
                    	user?.photoURL ?? "https://i.pravatar.cc/300"),
                	),
              	title: Text(user?.displayName ?? ""),
              	trailing: TextButton.icon(icon: Icon(Icons.logout), label: Text('Logout'), onPressed: () => FirebaseAuth.instance.signOut())
              )
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCall(
          channelName: 'public',
        ),
      ),
    );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }
}
