import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/utils/signaling2.dart';
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
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _rnd = Random();

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  final signaling = Signaling2(localDisplayName: getRandomString(20));

  final localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, bool?> remoteRenderersLoading = {};

  bool localRenderOk = false;
  bool error = false;

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

    disposeRemoteRenderers();

    super.dispose();
  }

  Future<void> initCamera() async {
    await localRenderer.initialize();
    await doTry(runAsync: () => signaling.openUserMedia());
    await doTry(
      runSync: () => setState(() => signaling.muteMic()),
    );
    
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
    await signaling.join(widget.roomId);
  }

  Future<void> hangUp(bool exit) async {
    setState(() {
      error = false;

      // if (exit) {
      //   widget.roomId = '';
      // }
    });

    await signaling.hangUp(exit);

    setState(() {
      disposeRemoteRenderers();
    });
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
        widget.roomId,
        style: const TextStyle(fontSize: 12),
      )),
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
            if (widget.roomId.length > 2) ...[
              if (error) ...[
                FloatingActionButton(
                  tooltip: 'Retry call',
                  child: const Icon(Icons.add_call),
                  backgroundColor: Colors.green,
                  onPressed: () async => await doTry(
                    runAsync: () => join(),
                    onError: () => hangUp(false),
                  ),
                ),
              ],
              if (localRenderOk && signaling.isJoined()) ...[
                // FloatingActionButton(
                //   tooltip: signaling.isScreenSharing()
                //       ? 'Change screen sharing'
                //       : 'Start screen sharing',
                //   backgroundColor:
                //       signaling.isScreenSharing() ? Colors.amber : Colors.grey,
                //   child: const Icon(Icons.screen_share_outlined),
                //   onPressed: () async => await doTry(
                //     runAsync: () => signaling.screenSharing(),
                //   ),
                // ),
                // if (signaling.isScreenSharing()) ...[
                //   FloatingActionButton(
                //     tooltip: 'Stop screen sharing',
                //     backgroundColor: Colors.redAccent,
                //     child: const Icon(Icons.stop_screen_share_outlined),
                //     onPressed: () => signaling.stopScreenSharing(),
                //   ),
                // ],
                // if (cameraCountSnap.hasData &&
                //     cameraCountSnap.requireData > 1) ...[
                //   FloatingActionButton(
                //     tooltip: 'Switch camera',
                //     backgroundColor: Colors.grey,
                //     child: const Icon(Icons.switch_camera),
                //     onPressed: () async => await doTry(
                //       runAsync: () => signaling.switchCamera(),
                //     ),
                //   )
                // ],
                // FloatingActionButton(
                //   tooltip: isMicMuted() ? 'Un-mute mic' : 'Mute mic',
                //   backgroundColor:
                //       isMicMuted() ? Colors.redAccent : Colors.grey,
                //   child: isMicMuted()
                //       ? const Icon(Icons.mic_off)
                //       : const Icon(Icons.mic_outlined),
                //   onPressed: () => doTry(
                //     runSync: () => setState(() => signaling.muteMic()),
                //   ),
                // ),
                FloatingActionButton(
                  tooltip: 'Hangup',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () => hangUp(false),
                ),
                FloatingActionButton(
                  tooltip: 'Exit',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.exit_to_app),
                  onPressed: () => hangUp(true),
                ),
              ] else ...[
                // FloatingActionButton(
                //   tooltip: 'Start call',
                //   child: const Icon(Icons.call),
                //   backgroundColor: Colors.green,
                //   onPressed: () async => await doTry(
                //     runAsync: () => join(),
                //     onError: () => hangUp(false),
                //   ),
                // ),
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
            //           initialValue: widget.roomId,
            //           onChanged: (value) =>
            //               setState(() => widget.roomId = value),
            //         ),
            //       )
            //     ],
            //   ),
            // ),

            // streaming
            Expanded(
              child: view(
                children: [
                  // if (localRenderOk) ...[
                  //   Expanded(
                  //     child: Container(
                  //       margin: const EdgeInsets.all(4),
                  //       padding: const EdgeInsets.all(4),
                  //       decoration: BoxDecoration(
                  //         border: Border.all(
                  //           color: const Color(0XFF2493FB),
                  //         ),
                  //       ),
                  //       child: RTCVideoView(localRenderer,
                  //           mirror: !signaling.isScreenSharing()),
                  //     ),
                  //   ),
                  // ],
                  for (final remoteRenderer in remoteRenderers.entries) ...[
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
          ],
        ),
      ),
    );
  }
}
