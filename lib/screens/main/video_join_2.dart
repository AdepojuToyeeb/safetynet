import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling4.dart';

typedef ExecuteCallback = void Function();
typedef ExecuteFutureCallback = Future<void> Function();

class JoinRoomWidget extends StatefulWidget {
  final String userId;
  const JoinRoomWidget({required this.userId, super.key});

  @override
  State<JoinRoomWidget> createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<JoinRoomWidget> {
  static const _chars = '1234567890';
  static final _rnd = Random();

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  final signaling = Signaling4(localDisplayName: getRandomString(5));

  final localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, bool?> remoteRenderersLoading = {};

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
    setState(() {
      _initStatusLoading = false;
    });
    join();
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
    await signaling.join(widget.userId);
  }

  Future<void> hangUp(bool exit) async {
    setState(() {
      error = false;
    });

    await signaling.hangUp(exit);

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
                            for (final remoteRenderer
                                in remoteRenderers.entries) ...[
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0XFF2493FB),
                                    ),
                                  ),
                                  child: false ==
                                          remoteRenderersLoading[remoteRenderer
                                              .key] // && true == remoteRenderer.value.srcObject?.active
                                      ? RTCVideoView(remoteRenderer.value)
                                      : const Center(
                                          child: CircularProgressIndicator(),
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
                if (widget.userId.length > 2) ...[
                  if (error) ...[
                    FloatingActionButton(
                      heroTag: 'retryCall',
                      elevation: 0,
                      backgroundColor: Colors.green,
                      onPressed: () async => await doTry(
                        runAsync: () => join(),
                        onError: () => hangUp(false),
                      ),
                      child: const Icon(Icons.add_call, color: Colors.white),
                    ),
                  ],
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
