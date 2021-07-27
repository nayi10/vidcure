import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vidcure/models/Expert.dart';
import 'package:vidcure/models/User.dart' as mUser;
import 'package:vidcure/pages/chat_page.dart';

import './video_call.dart';
import 'authentication.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();
}

class IndexState extends State<HomePage> {
  ClientRole _role = ClientRole.Audience;
  bool _isExpert = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (ctx) => Authentication()));
      }
    });
    _checkExpertStatus();
  }

  Future<QuerySnapshot<Expert>> _fetchExperts() async {
    return await FirebaseFirestore.instance
        .collection('experts')
        .withConverter<Expert>(
            fromFirestore: (snapshot, _) => Expert.fromMap(snapshot.data()!),
            toFirestore: (expert, _) => expert.toMap())
        .get();
  }

  Future<QuerySnapshot<mUser.User>> _fetchUsers() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .withConverter<mUser.User>(
            fromFirestore: (snapshot, _) =>
                mUser.User.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson())
        .get();
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
            onPressed: () =>
                _isExpert ? _displayUsersDialog() : _displayDialog(),
            icon: Icon(
              Icons.video_call_rounded,
            ),
          ),
          FloatingActionButton(
            elevation: 6,
            onPressed: () => _isExpert
                ? _displayUsersDialog(isChat: true)
                : _displayDialog(isChat: true),
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
            SizedBox(height: 35.0),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color.fromARGB(30, 50, 50, 50),
                      foregroundImage: NetworkImage(
                          user?.photoURL ?? "https://i.pravatar.cc/300"),
                    ),
                    title: Text(user?.displayName ?? ""),
                    trailing: TextButton.icon(
                        icon: Icon(Icons.logout),
                        label: Text('Logout'),
                        onPressed: () => FirebaseAuth.instance.signOut()))),
          ],
        ),
      ),
    );
  }

  Future<void> onJoin({Expert? expert, mUser.User? user}) async {
    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCall(
          channelName: 'public',
          user: user,
          expert: expert,
        ),
      ),
    );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }

  void _displayDialog({bool? isChat}) {
    final alert = AlertDialog(
        title: Text('Choose an expert'),
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.all(8),
        content: FutureBuilder<QuerySnapshot<Expert>>(
            future: _fetchExperts(),
            builder: (alertContext, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.size == 0) {
                  return Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: 300),
                    child: Center(
                      child: Text('No experts available'),
                    ),
                  );
                }
                return Container(
                  height: 500,
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                      maxHeight: 700),
                  child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (buildeContext, i) => ListTile(
                            leading: CircleAvatar(
                              foregroundImage:
                                  AssetImage('assets/images/healthcare.png'),
                            ),
                            title: Text(snapshot.data!.docs[i].data().name),
                            trailing: Text(
                              snapshot.data!.docs[i].data().isOnline
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                  color: snapshot.data!.docs[i].data().isOnline
                                      ? Colors.green[800]
                                      : Colors.grey),
                            ),
                            subtitle:
                                Text(snapshot.data!.docs[i].data().specialty),
                            onTap: () {
                              if (isChat == null) {
                                onJoin(expert: snapshot.data!.docs[i].data());
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (ctx) => ChatPage(
                                              expert:
                                                  snapshot.data!.docs[i].data(),
                                            )));
                              }
                            },
                          ),
                      separatorBuilder: (ctx, i) => Divider(
                            height: 0,
                          ),
                      itemCount: snapshot.data!.size),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  height: 300,
                  width: 400,
                  child: Center(
                    child: Text(snapshot.error.toString()),
                  ),
                );
              }
              return Container(
                height: 200,
                width: 400,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }));
    showDialog(context: context, builder: (context) => alert);
  }

  void _displayUsersDialog({bool? isChat}) {
    final alert = AlertDialog(
        title: Text('Choose an user'),
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.all(8),
        content: FutureBuilder<QuerySnapshot<mUser.User>>(
            future: _fetchUsers(),
            builder: (alertContext, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.size == 0) {
                  return Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: 300),
                    child: Center(
                      child: Text('No users available'),
                    ),
                  );
                }
                return Container(
                  height: 500,
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                      maxHeight: 700),
                  child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (buildeContext, i) => ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title:
                                Text(snapshot.data!.docs[i].data().fullName!),
                            subtitle: Text(
                              snapshot.data!.docs[i].data().isOnline!
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                  color: snapshot.data!.docs[i].data().isOnline!
                                      ? Colors.green[800]
                                      : Colors.grey),
                            ),
                            onTap: () {
                              if (isChat == null) {
                                onJoin(user: snapshot.data!.docs[i].data());
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (ctx) => ChatPage(
                                              user:
                                                  snapshot.data!.docs[i].data(),
                                            )));
                              }
                            },
                          ),
                      separatorBuilder: (ctx, i) => Divider(
                            height: 0,
                          ),
                      itemCount: snapshot.data!.size),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  height: 300,
                  width: 400,
                  child: Center(
                    child: Text(snapshot.error.toString()),
                  ),
                );
              }
              return Container(
                height: 200,
                width: 400,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }));
    showDialog(context: context, builder: (context) => alert);
  }

  void _checkExpertStatus() {
    final firestore = FirebaseFirestore.instance.collection('experts');
    final query = firestore.where('email', isEqualTo: user!.email).get();
    query.then((value) {
      if (value.docs.first.data()['email'] == user!.email) {
        setState(() {
          _isExpert = true;
        });
      }
    });
  }
}
