import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
import 'package:vidcure/models/Expert.dart';
import 'package:vidcure/models/User.dart';

import '../utils/settings.dart';

class VideoCall extends StatefulWidget {
  final String? channelName;
  final Expert? expert;
  final User? user;
  const VideoCall({Key? key, this.channelName, this.expert, this.user})
      : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  int? _remoteUid;
  bool muted = false;
  late RtcEngine _engine;

  bool _isExpert = false;

  String? userDoctorRoom;

  @override
  void dispose() {
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    userDoctorRoom = widget.expert != null
        ? '${widget.expert!.email}_${fire.FirebaseAuth.instance.currentUser!.email}'
        : '${fire.FirebaseAuth.instance.currentUser?.email}_${widget.user?.email}';
    // initialize agora sdk
    checkExpertStatus();
    initialize();
  }

  Future<void> onCallStarted(int elapsed) async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(userDoctorRoom)
        .collection('logs')
        .add({
      'message': 'You attempted to video call ${widget.expert!.name}',
      'elapsedTime': elapsed * 0.001,
      'timestamp': Timestamp.now()
    });
  }

  Future<void> onRemoteUserJoined(RtcStats stats) async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(userDoctorRoom)
        .collection('logs')
        .add({
      'message': 'You called ${widget.expert!.name}',
      'elapsedTime': stats.totalDuration,
      'timestamp': Timestamp.now()
    });
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    var myToken = await getToken();
    if (_isExpert) {
      await _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      await _engine.setClientRole(ClientRole.Audience);
    }
    await _engine.joinChannel(myToken, widget.channelName!, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));
    await _engine.enableVideo();
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        _makeUserOnline();
        onCallStarted(elapsed);
      },
      userJoined: (int uid, int elapsed) {
        setState(() {
          _remoteUid = uid;
        });
      },
      userOffline: (int uid, reason) {
        _makeUserOffline();
        setState(() {
          _remoteUid = null;
        });
      },
      leaveChannel: (stats) {
        onRemoteUserJoined(stats);
        _makeUserOffline();
      },
    ));
  }

  void _makeUserOffline() {
    if (_isExpert) {
      final ref = FirebaseFirestore.instance.collection('experts');
      ref.where('email', isEqualTo: widget.expert!.email).get().then((value) {
        ref.doc(value.docs.first.id).set({'isOnline': false});
      });
    } else {
      final ref = FirebaseFirestore.instance.collection('users');
      ref.where('email', isEqualTo: widget.user!.email).get().then((value) {
        ref.doc(value.docs.first.id).set({'isOnline': false});
      });
    }
  }

  void _makeUserOnline() {
    if (_isExpert) {
      final ref = FirebaseFirestore.instance.collection('experts');
      ref.where('email', isEqualTo: widget.expert!.email).get().then((value) {
        ref.doc(value.docs.first.id).set({'isOnline': true});
      });
    } else {
      final ref = FirebaseFirestore.instance.collection('users');
      ref.where('email', isEqualTo: widget.user!.email).get().then((value) {
        ref.doc(value.docs.first.id).set({'isOnline': true});
      });
    }
  }

  Widget _remoteVideoPreview() {
    if (_remoteUid != null) {
      return Expanded(
          child: Container(child: RtcRemoteView.SurfaceView(uid: _remoteUid!)));
    } else {
      return Expanded(
          child: Container(
              child: Text(
        'Waiting for a patient to join...',
        style: TextStyle(fontSize: 18.0),
      )));
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            Container(
                child: Column(
              children: <Widget>[_remoteVideoPreview()],
            )),
            _toolbar(),
            Align(
              alignment: Alignment.topLeft,
              widthFactor: 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15)))),
                    constraints: BoxConstraints(
                        maxHeight: 80,
                        maxWidth: MediaQuery.of(context).size.width * 0.5),
                    child: ListTile(
                      leading: Icon(
                        Icons.person_rounded,
                        color: Colors.blueGrey,
                      ),
                      title: Text(widget.expert != null
                          ? widget.expert?.name ?? ''
                          : widget.user?.fullName ?? ''),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    margin: EdgeInsets.only(top: 40.0),
                    alignment: Alignment.center,
                    child: _renderLocalVideoPreview(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _renderLocalVideoPreview() {
    return RtcLocalView.SurfaceView();
  }

  void checkExpertStatus() {
    final user = fire.FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance.collection('experts');
    final query = firestore.where('email', isEqualTo: user!.email).get();
    query.then((value) {
      if (value.docs.first.data()['email'] == user.email) {
        setState(() {
          _isExpert = true;
        });
      }
    });
  }
}
