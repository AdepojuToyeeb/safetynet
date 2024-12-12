import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling.dart';
import 'package:safetynet/utils/snack_message.dart';

typedef ExecuteCallback = void Function();
typedef ExecuteFutureCallback = Future<void> Function();

class VideoJoinRoom extends StatefulWidget {
  final String roomId;

  const VideoJoinRoom({super.key, required this.roomId});

  @override
  VideoCallRoomState createState() => VideoCallRoomState();
}

class VideoCallRoomState extends State<VideoJoinRoom> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool localRenderOk = true;
  bool isInitialized = false;

  @override
  void initState() {
    signaling.openUserMedia(_localRenderer, _remoteRenderer);
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    // Set up stream callback
    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    initializeVideoCall();
    super.initState();
  }

  Future<void> initializeVideoCall() async {
    try {
      // Join the room
      await signaling.joinRoom(
        widget.roomId,
        _remoteRenderer,
      );

      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print("faileddddddddddddd,$e");
      // Handle initialization errors
      SnackMsg.showError(context, 'Failed to initialize video call: $e');
    }
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> doTry(
      {ExecuteCallback? runSync,
      ExecuteFutureCallback? runAsync,
      ExecuteCallback? onError}) async {
    try {
      runSync?.call();
      await runAsync?.call();
    } catch (e) {
      SnackMsg.showError(context, 'Error: $e');
      onError?.call();
    }
  }

  Flex view({required List<Widget> children}) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return isLandscape ? Row(children: children) : Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Broadcast ',
          style: TextStyle(fontSize: 16),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FutureBuilder<int>(
        future: signaling.cameraCount(),
        initialData: 0,
        builder: (context, cameraCountSnap) {
          if (cameraCountSnap.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (!cameraCountSnap.hasData) {
            return const Text('No data available');
          }
          return Wrap(
            spacing: 15,
            children: [
              if (localRenderOk) ...[
                FloatingActionButton(
                  tooltip: 'Hangup',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () => {Navigator.of(context).pop()},
                ),
              ],
            ],
          );
        },
      ),
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // streaming
            Expanded(
              child: view(
                children: [
                  // if (localRenderOk) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child:
                                Expanded(child: RTCVideoView(_remoteRenderer)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
