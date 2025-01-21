import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling4.dart';
import 'package:safetynet/utils/snack_message.dart';

typedef ExecuteCallback = void Function();
typedef ExecuteFutureCallback = Future<void> Function();

class RoomWidget extends StatefulWidget {
  const RoomWidget({super.key});

  @override
  State<RoomWidget> createState() => _RoomWidgetState();
}

String generateRoomId() {
  final random = Random();
  String roomId = '';

  // Generate 4 random digits
  for (var i = 0; i < 4; i++) {
    roomId += random.nextInt(10).toString();
  }

  return roomId;
}

class _RoomWidgetState extends State<RoomWidget> {
  static const _chars = '1234567890';
  static final _rnd = Random();

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  final signaling = Signaling4(localDisplayName: getRandomString(5));

  final localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, bool?> remoteRenderersLoading = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String roomId = generateRoomId();
  Position? _currentPosition;
  bool localRenderOk = false;
  bool error = false;
  bool _initStatusLoading = true;

  @override
  void initState() {
    super.initState();

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
      //SnackMsg.showError(context, 'Connection failed with $displayName');
      error = true;
    };

    signaling.onGenericError = (errorText) {
      //SnackMsg.showError(context, errorText);
      error = true;
    };

    initCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    localRenderer.dispose();

    disposeRemoteRenderers();

    super.dispose();
  }

  Future<void> initCamera() async {
    await localRenderer.initialize();
    await doTry(runAsync: () => signaling.openUserMedia());
  }

  Future<void> _saveRoomToFirebase() async {
    if (_currentPosition != null) {
      try {
        await _firestore.collection('room').doc(roomId).set({
          'roomId': roomId,
          'createdAt': FieldValue.serverTimestamp(),
          'location': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          'userId': signaling.localDisplayName,
          'active': true,
        });
        setState(() {
          _initStatusLoading = false;
        });
      } catch (e) {
        SnackMsg.showError(context, 'Error saving room data: $e');
      }
    }
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
      await join();
    } catch (e) {
      SnackMsg.showError(context, 'Error getting location: $e');
    }
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
      //SnackMsg.showError(context, 'Error: $e');
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
    setState(() {
      error = false;
    });

    print('About to delete room: $roomId');

    try {
      await _firestore.collection('room').doc(roomId).delete();
      print('Successfully deleted room: $roomId');
      await signaling.hangUp(exit);

      if (exit) {
        setState(() {
          roomId = '';
        });
      }
    } catch (e) {
      print('Error deleting room: $e');
    }

    setState(() {
      disposeRemoteRenderers();
    });
    Navigator.of(context).pop();
  }

  bool isMicMuted() {
    try {
      return signaling.isMicMuted();
    } catch (e) {
      //SnackMsg.showError(context, 'Error: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        // elevation: 1,
        title: Text(
          'SafetyNet - ${signaling.localDisplayName}',
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255), fontSize: 18),
        ),
      ),
      body: _initStatusLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Room ID Input
                  // Video Grid
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: view(
                          children: [
                            if (localRenderOk) ...[
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      width: 0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: Stack(
                                      children: [
                                        RTCVideoView(
                                          localRenderer,
                                          mirror: !signaling.isScreenSharing(),
                                        ),
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'You',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder<int>(
          future: signaling.cameraCount(),
          initialData: 0,
          builder: (context, cameraCountSnap) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!localRenderOk) ...[
                  FloatingActionButton(
                    heroTag: 'openCamera',
                    elevation: 0,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.videocam_off_outlined,
                        color: Colors.white),
                    onPressed: () async => await doTry(
                      runAsync: () => signaling.reOpenUserMedia(),
                    ),
                  ),
                ],
                if (roomId.length > 2) ...[
                  if (localRenderOk && signaling.isJoined()) ...[
                    if (signaling.isScreenSharing()) ...[
                      FloatingActionButton(
                        heroTag: 'stopScreenShare',
                        elevation: 0,
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.stop_screen_share_outlined,
                            color: Colors.white),
                        onPressed: () => signaling.stopScreenSharing(),
                      ),
                    ],
                    if (cameraCountSnap.hasData &&
                        cameraCountSnap.requireData > 1) ...[
                      FloatingActionButton(
                        heroTag: 'switchCamera',
                        elevation: 0,
                        backgroundColor: const Color(0xFF95A5A6),
                        child: const Icon(Icons.switch_camera,
                            color: Colors.white),
                        onPressed: () async => await doTry(
                          runAsync: () => signaling.switchCamera(),
                        ),
                      )
                    ],
                    FloatingActionButton(
                      heroTag: 'toggleMic',
                      elevation: 0,
                      backgroundColor: isMicMuted()
                          ? Colors.redAccent
                          : const Color(0xFF95A5A6),
                      child: Icon(
                        isMicMuted() ? Icons.mic_off : Icons.mic_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => doTry(
                        runSync: () => setState(() => signaling.muteMic()),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'hangup',
                      elevation: 0,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: () => hangUp(true),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
