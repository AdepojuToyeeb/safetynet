import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling.dart';
import 'package:safetynet/utils/snack_message.dart';
import 'package:geolocator/geolocator.dart';

typedef ExecuteCallback = void Function();
typedef ExecuteFutureCallback = Future<void> Function();

class VideoCallRoom extends StatefulWidget {
  const VideoCallRoom({super.key});

  @override
  VideoCallRoomState createState() => VideoCallRoomState();
}

class VideoCallRoomState extends State<VideoCallRoom> {
  String? roomId;
  Position? currentPosition;
  bool _isUsingFrontCamera = true;
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool localRenderOk = true;

  @override
  void initState() {
    _getCurrentLocation();
    signaling.openUserMedia(_localRenderer, _remoteRenderer);
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
      localRenderOk = stream as bool;
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackMsg.showError(context, 'Location permissions are denied');
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });
      roomId = await signaling.createRoom(_localRenderer, currentPosition);
      setState(() {
        roomId = roomId;
      });
    } catch (e) {
      SnackMsg.showError(context, 'Error getting location: $e');
    }
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

  Future<void> initCamera() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await doTry(
        runAsync: () =>
            signaling.openUserMedia(_localRenderer, _remoteRenderer));
  }

  Flex view({required List<Widget> children}) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return isLandscape ? Row(children: children) : Column(children: children);
  }

  Future<void> hangUp() async {
    try {
      await signaling.deleteRoom(roomId!);
      // Close signaling and exit the room
      await signaling.hangUp(_localRenderer);
      // Pop the navigation if we're exiting
      Navigator.of(context).pop();
    } catch (e) {
      SnackMsg.showError(context, 'Error during hangup: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      // Assuming you're using flutter_webrtc or similar package
      final videoTrack = _localRenderer.srcObject?.getVideoTracks().first;
      // signaling.switchCamera();

      if (videoTrack != null) {
        if (!kIsWeb && _localRenderer != null) {
          await Helper.switchCamera(
              _localRenderer.srcObject!.getVideoTracks().first);
          setState(() {
            _isUsingFrontCamera = !_isUsingFrontCamera;
          });
        }
        // Toggle the camera flag
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Broadcast ',
          style: const TextStyle(fontSize: 16),
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
          final cameraCount = cameraCountSnap.data;

          return Wrap(
            spacing: 15,
            children: [
              if (localRenderOk) ...[
                if (cameraCount != null && cameraCount > 1) ...[
                  FloatingActionButton(
                    tooltip: 'Switch camera',
                    backgroundColor: Colors.grey,
                    child: const Icon(Icons.switch_camera),
                    onPressed: () async => await doTry(
                      runAsync: () => switchCamera(),
                    ),
                  )
                ],
                FloatingActionButton(
                  tooltip: 'Hangup',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () => hangUp(),
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
                  if (localRenderOk) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: RTCVideoView(_localRenderer,
                                  mirror: _isUsingFrontCamera),
                            ),
                          
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
