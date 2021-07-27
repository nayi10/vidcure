import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:vidcure/models/Expert.dart';
import 'package:vidcure/models/User.dart' as mUser;

class ChatPage extends StatefulWidget {
  final Expert? expert;

  final mUser.User? user;

  const ChatPage({Key? key, this.expert, this.user}) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final fUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<DashChatState> _chatViewKey = GlobalKey<DashChatState>();
  List<ChatMessage> messages = <ChatMessage>[];
  var m = <ChatMessage>[];

  var i = 0;

  String? userDoctorRoom;
  String? title;

  @override
  void initState() {
    userDoctorRoom = widget.expert != null
        ? '${widget.expert!.email}_${fUser!.email}'
        : '${fUser!.email}_${widget.user!.email}';
    title = widget.expert != null
        ? 'Dr. ${widget.expert!.name.split(" ").first}'
        : widget.user!.fullName;
    super.initState();
  }

  void systemMessage() {
    Timer(Duration(milliseconds: 300), () {
      if (i < 6) {
        setState(() {
          messages = [...messages, m[i]];
        });
        i++;
      }
      Timer(Duration(milliseconds: 300), () {
        _chatViewKey.currentState!.scrollController
          ..animateTo(
            _chatViewKey
                .currentState!.scrollController.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
      });
    });
  }

  void onSend(ChatMessage message) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(userDoctorRoom)
        .collection('messages')
        .add(message.toJson());
  }

  @override
  Widget build(BuildContext context) {
    ChatUser user = ChatUser(
        uid: fUser!.uid, name: fUser!.displayName, avatar: fUser!.photoURL);
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with $title"),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(userDoctorRoom)
              .collection('messages')
              .orderBy("createdAt")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              );
            } else {
              List<DocumentSnapshot> items = snapshot.data!.docs;
              var messages = items
                  .map((i) => ChatMessage.fromJson(
                      (i.data() as Map<String, dynamic>?)!))
                  .toList();
              return DashChat(
                key: _chatViewKey,
                inverted: false,
                onSend: onSend,
                sendOnEnter: true,
                textInputAction: TextInputAction.send,
                user: user,
                inputDecoration: InputDecoration(
                    hintText: "Type your message...",
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8.0),
                    )),
                dateFormat: DateFormat('yyyy M, dd'),
                timeFormat: DateFormat('HH:mm'),
                messages: messages,
                showUserAvatar: false,
                showAvatarForEveryMessage: false,
                scrollToBottom: false,
                onPressAvatar: (ChatUser user) {
                  print("OnPressAvatar: ${user.name}");
                },
                onLongPressAvatar: (ChatUser user) {},
                inputMaxLines: 5,
                messageContainerPadding: EdgeInsets.only(left: 5.0, right: 5.0),
                alwaysShowSend: true,
                inputTextStyle: TextStyle(fontSize: 16.0),
                inputContainerStyle: BoxDecoration(
                  border: Border.all(width: 2.0),
                  color: Colors.white,
                ),
                onQuickReply: (Reply reply) {
                  setState(() {
                    messages.add(ChatMessage(
                        text: reply.value,
                        createdAt: DateTime.now(),
                        user: user));

                    messages = [...messages];
                  });

                  Timer(Duration(milliseconds: 300), () {
                    _chatViewKey.currentState!.scrollController
                      ..animateTo(
                        _chatViewKey.currentState!.scrollController.position
                            .maxScrollExtent,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 300),
                      );

                    if (i == 0) {
                      systemMessage();
                      Timer(Duration(milliseconds: 600), () {
                        systemMessage();
                      });
                    } else {
                      systemMessage();
                    }
                  });
                },
                onLoadEarlier: () {
                  print("laoding...");
                },
                shouldShowLoadEarlier: false,
                showTraillingBeforeSend: true,
                trailing: <Widget>[
                  IconButton(
                    icon: Icon(Icons.photo),
                    onPressed: () async {
                      final picker = ImagePicker();
                      PickedFile? result = await picker.getImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxHeight: 400,
                        maxWidth: 400,
                      );

                      if (result != null) {
                        final Reference storageRef =
                            FirebaseStorage.instance.ref().child("chat_images");

                        final taskSnapshot = await storageRef.putFile(
                          File(result.path),
                          SettableMetadata(
                            contentType: 'image/jpg',
                          ),
                        );

                        String url = await taskSnapshot.ref.getDownloadURL();

                        ChatMessage message =
                            ChatMessage(text: "", user: user, image: url);

                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(userDoctorRoom)
                            .collection('messages')
                            .add(message.toJson());
                      }
                    },
                  )
                ],
              );
            }
          }),
    );
  }
}
