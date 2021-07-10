import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';

import '../utils/settings.dart';

class VideoCall extends StatefulWidget {
  final String? channelName;
  const VideoCall({Key? key, this.channelName}) : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  int? _remoteUid;
  bool muted = false;
  late RtcEngine _engine;

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
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    var myToken = await getToken();
    await _engine.joinChannel(myToken, widget.channelName!, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));
    await _engine.enableVideo();
    _engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('Local user $uid joined success');
    }, userJoined: (int uid, int elapsed) {
      print('Remote user $uid joined');
      setState(() {
        _remoteUid = uid;
      });
    }, userOffline: (int uid, reason) {
      print('Remote user $uid left');
      setState(() {
        _remoteUid = null;
      });
    }));
  }

  Widget _remoteVideoPreview() {
    if (_remoteUid != null) {
      return Expanded(child: Container(child:RtcRemoteView.SurfaceView(uid: _remoteUid!)));
    } else {
      return Expanded(child: Container(child:Text(
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
            Align(alignment: Alignment.topRight,
            child: Container(
              width: 120,
              height: 120,
              margin: EdgeInsets.only(top: 40.0),
              alignment: Alignment.center,
              child: _renderLocalVideoPreview(),
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
}
