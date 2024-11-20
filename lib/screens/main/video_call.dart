import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling2.dart';
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
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _rnd = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  final signaling = Signaling2(localDisplayName: getRandomString(20));

  final localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, bool?> remoteRenderersLoading = {};

  late String roomId;
  Position? _currentPosition;

  bool localRenderOk = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    roomId = signaling.localDisplayName;
    _getCurrentLocation();
    signaling.onAddLocalStream = (peerUuid, displayName, stream) {
      setState(() {
        localRenderer.srcObject = stream;
        localRenderOk = stream != null;
      });
    };

    signaling.onAddRemoteStream = (peerUuid, displayName, stream) async {
      final remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize();
      remoteRenderer.srcObject = stream;

      setState(() => remoteRenderers[peerUuid] = remoteRenderer);
    };

    signaling.onRemoveRemoteStream = (peerUuid, displayName) {
      if (remoteRenderers.containsKey(peerUuid)) {
        remoteRenderers[peerUuid]!.srcObject = null;
        remoteRenderers[peerUuid]!.dispose();

        setState(() {
          remoteRenderers.remove(peerUuid);
          remoteRenderersLoading.remove(peerUuid);
        });
      }
    };

    signaling.onConnectionConnected = (peerUuid, displayName) {
      setState(() => remoteRenderersLoading[peerUuid] = false);
    };

    signaling.onConnectionLoading = (peerUuid, displayName) {
      setState(() => remoteRenderersLoading[peerUuid] = true);
    };

    signaling.onConnectionError = (peerUuid, displayName) {
      SnackMsg.showError(context, 'Connection failed with $displayName');
      error = true;
    };

    signaling.onGenericError = (errorText) {
      SnackMsg.showError(context, errorText);
      error = true;
    };

    initCamera();
    join();
  }

  @override
  void dispose() {
    localRenderer.dispose();
    _updateRoomStatus(false);
    disposeRemoteRenderers();
    signaling.stopUserMedia();
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
      setState(() => _currentPosition = position);

      // Save room data to Firebase
      await _saveRoomToFirebase();
    } catch (e) {
      SnackMsg.showError(context, 'Error getting location: $e');
    }
  }

  Future<void> _saveRoomToFirebase() async {
    if (_currentPosition != null) {
      try {
        await _firestore.collection('rooms').doc(roomId).set({
          'roomId': roomId,
          'createdAt': FieldValue.serverTimestamp(),
          'location': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          'userId': signaling.localDisplayName,
          'active': true,
        });
      } catch (e) {
        SnackMsg.showError(context, 'Error saving room data: $e');
      }
    }
  }

  Future<void> _updateRoomStatus(bool active) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'active': active,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      SnackMsg.showError(context, 'Error updating room status: $e');
    }
  }

  Future<void> initCamera() async {
    await localRenderer.initialize();
    await doTry(runAsync: () => signaling.openUserMedia());
  }

  void disposeRemoteRenderers() {
    for (final remoteRenderer in remoteRenderers.values) {
      remoteRenderer.dispose();
    }

    remoteRenderers.clear();
  }

  Flex view({required List<Widget> children}) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return isLandscape ? Row(children: children) : Column(children: children);
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

  Future<void> reJoin() async {
    await hangUp(false);
    await join();
  }

  Future<void> join() async {
    setState(() => error = false);

    await signaling.reOpenUserMedia();
    await signaling.join(roomId);
  }

  Future<void> hangUp(bool exit) async {
    try {
      await signaling.deleteRoom(roomId);

      // Close signaling and exit the room
      await signaling.hangUp(exit);
      setState(() {
        error = false;
        roomId = '';
        disposeRemoteRenderers();
      });
      // Pop the navigation if we're exiting
      Navigator.of(context).pop();
    } catch (e) {
      SnackMsg.showError(context, 'Error during hangup: $e');
    }
  }

  bool isMicMuted() {
    try {
      return signaling.isMicMuted();
    } catch (e) {
      SnackMsg.showError(context, 'Error: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Broadcast - ${signaling.localDisplayName}',
          style: const TextStyle(fontSize: 16),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FutureBuilder<int>(
        future: signaling.cameraCount(),
        initialData: 0,
        builder: (context, cameraCountSnap) => Wrap(
          spacing: 15,
          children: [
            if (!localRenderOk) ...[
              FloatingActionButton(
                tooltip: 'Open camera',
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.videocam_off_outlined),
                onPressed: () async => await doTry(
                  runAsync: () => signaling.reOpenUserMedia(),
                ),
              ),
            ],
            if (roomId.length > 2) ...[
              // if (error) ...[
              //   FloatingActionButton(
              //     tooltip: 'Retry call',
              //     backgroundColor: Colors.green,
              //     onPressed: () async => await doTry(
              //       runAsync: () => join(),
              //       onError: () => hangUp(false),
              //     ),
              //     child: const Icon(Icons.add_call),
              //   ),
              // ],
              if (localRenderOk && signaling.isJoined()) ...[
                if (cameraCountSnap.hasData &&
                    cameraCountSnap.requireData > 1) ...[
                  FloatingActionButton(
                    tooltip: 'Switch camera',
                    backgroundColor: Colors.grey,
                    child: const Icon(Icons.switch_camera),
                    onPressed: () async => await doTry(
                      runAsync: () => signaling.switchCamera(),
                    ),
                  )
                ],
                FloatingActionButton(
                  tooltip: isMicMuted() ? 'Un-mute mic' : 'Mute mic',
                  backgroundColor:
                      isMicMuted() ? Colors.redAccent : Colors.grey,
                  child: isMicMuted()
                      ? const Icon(Icons.mic_off)
                      : const Icon(Icons.mic_outlined),
                  onPressed: () => doTry(
                    runSync: () => setState(() => signaling.muteMic()),
                  ),
                ),
                FloatingActionButton(
                  tooltip: 'Hangup',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () => hangUp(false),
                ),
              ] else ...[
                FloatingActionButton(
                  tooltip: 'Start call',
                  backgroundColor: Colors.green,
                  onPressed: () async => await doTry(
                    runAsync: () => join(),
                    onError: () => hangUp(false),
                  ),
                  child: const Icon(Icons.call),
                ),
              ],
            ],
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // room
            // Container(
            //   margin: const EdgeInsets.all(8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       const Text("Room ID: "),
            //       Flexible(
            //         child: TextFormField(
            //           initialValue: roomId,
            //           onChanged: (value) => setState(() => roomId = value),
            //         ),
            //       )
            //     ],
            //   ),
            // ),

            // streaming
            Expanded(
              child: view(
                children: [
                  if (localRenderOk) ...[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        // padding: const EdgeInsets.all(4),

                        child: RTCVideoView(localRenderer,
                            mirror: !signaling.isScreenSharing()),
                      ),
                    ),
                  ],
                  // for (final remoteRenderer in remoteRenderers.entries) ...[
                  //   Expanded(
                  //     child: Container(
                  //       margin: const EdgeInsets.all(4),
                  //       padding: const EdgeInsets.all(4),
                  //       decoration: BoxDecoration(
                  //         border: Border.all(
                  //           color: const Color(0XFF2493FB),
                  //         ),
                  //       ),
                  //       child: false ==
                  //               remoteRenderersLoading[remoteRenderer
                  //                   .key] // && true == remoteRenderer.value.srcObject?.active
                  //           ? RTCVideoView(remoteRenderer.value)
                  //           : const Center(
                  //               child: CircularProgressIndicator(),
                  //             ),
                  //     ),
                  //   ),
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
