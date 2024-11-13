// import 'dart:math';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:safetynet/utils/signaling.dart';
// import 'package:safetynet/utils/snack_message.dart';
// import 'package:safetynet/utils/webrtc.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// typedef ExecuteCallback = void Function();
// typedef ExecuteFutureCallback = Future<void> Function();

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   static const _chars =
//       'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
//   static final _rnd = Random();

//   static String getRandomString(int length) =>
//       String.fromCharCodes(Iterable.generate(
//           length, (index) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

//   final signaling = Signaling(localDisplayName: getRandomString(20));

//   final localRenderer = RTCVideoRenderer();
//   final Map<String, RTCVideoRenderer> remoteRenderers = {};
//   final Map<String, bool?> remoteRenderersLoading = {};

//   String roomId = '';

//   bool localRenderOk = false;
//   bool error = false;

//   @override
//   void initState() {
//     super.initState();

//     signaling.onAddLocalStream = (peerUuid, displayName, stream) {
//       setState(() {
//         localRenderer.srcObject = stream;
//         localRenderOk = stream != null;
//       });
//     };

//     signaling.onAddRemoteStream = (peerUuid, displayName, stream) async {
//       final remoteRenderer = RTCVideoRenderer();
//       await remoteRenderer.initialize();
//       remoteRenderer.srcObject = stream;

//       setState(() => remoteRenderers[peerUuid] = remoteRenderer);
//     };

//     signaling.onRemoveRemoteStream = (peerUuid, displayName) {
//       if (remoteRenderers.containsKey(peerUuid)) {
//         remoteRenderers[peerUuid]!.srcObject = null;
//         remoteRenderers[peerUuid]!.dispose();

//         setState(() {
//           remoteRenderers.remove(peerUuid);
//           remoteRenderersLoading.remove(peerUuid);
//         });
//       }
//     };

//     signaling.onConnectionConnected = (peerUuid, displayName) {
//       setState(() => remoteRenderersLoading[peerUuid] = false);
//     };

//     signaling.onConnectionLoading = (peerUuid, displayName) {
//       setState(() => remoteRenderersLoading[peerUuid] = true);
//     };

//     signaling.onConnectionError = (peerUuid, displayName) {
//       SnackMsg.showError(context, 'Connection failed with $displayName');
//       error = true;
//     };

//     signaling.onGenericError = (errorText) {
//       SnackMsg.showError(context, errorText);
//       error = true;
//     };

//     initCamera();
//   }

//   @override
//   void dispose() {
//     localRenderer.dispose();

//     disposeRemoteRenderers();

//     super.dispose();
//   }

//   Future<void> initCamera() async {
//     await localRenderer.initialize();
//     await doTry(runAsync: () => signaling.openUserMedia());
//   }

//   void disposeRemoteRenderers() {
//     for (final remoteRenderer in remoteRenderers.values) {
//       remoteRenderer.dispose();
//     }

//     remoteRenderers.clear();
//   }

//   Flex view({required List<Widget> children}) {
//     final isLandscape =
//         MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
//     return isLandscape ? Row(children: children) : Column(children: children);
//   }

//   Future<void> doTry(
//       {ExecuteCallback? runSync,
//       ExecuteFutureCallback? runAsync,
//       ExecuteCallback? onError}) async {
//     try {
//       runSync?.call();
//       await runAsync?.call();
//     } catch (e) {
//       SnackMsg.showError(context, 'Error: $e');
//       onError?.call();
//     }
//   }

//   Future<void> reJoin() async {
//     await hangUp(false);
//     await join();
//   }

//   Future<void> join() async {
//     setState(() => error = false);

//     await signaling.reOpenUserMedia();
//     await signaling.join(roomId);
//   }

//   Future<void> hangUp(bool exit) async {
//     setState(() {
//       error = false;

//       if (exit) {
//         roomId = '';
//       }
//     });

//     await signaling.hangUp(exit);

//     setState(() {
//       disposeRemoteRenderers();
//     });
//   }

//   bool isMicMuted() {
//     try {
//       return signaling.isMicMuted();
//     } catch (e) {
//       SnackMsg.showError(context, 'Error: $e');
//       return true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('WebRTC - ${signaling.localDisplayName}')),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: FutureBuilder<int>(
//         future: signaling.cameraCount(),
//         initialData: 0,
//         builder: (context, cameraCountSnap) => Wrap(
//           spacing: 15,
//           children: [
//             if (!localRenderOk) ...[
//               FloatingActionButton(
//                 tooltip: 'Open camera',
//                 backgroundColor: Colors.redAccent,
//                 child: const Icon(Icons.videocam_off_outlined),
//                 onPressed: () async => await doTry(
//                   runAsync: () => signaling.reOpenUserMedia(),
//                 ),
//               ),
//             ],
//             if (roomId.length > 2) ...[
//               if (error) ...[
//                 FloatingActionButton(
//                   tooltip: 'Retry call',
//                   backgroundColor: Colors.green,
//                   onPressed: () async => await doTry(
//                     runAsync: () => join(),
//                     onError: () => hangUp(false),
//                   ),
//                   child: const Icon(Icons.add_call),
//                 ),
//               ],
//               if (localRenderOk && signaling.isJoined()) ...[
//                 FloatingActionButton(
//                   tooltip: signaling.isScreenSharing()
//                       ? 'Change screen sharing'
//                       : 'Start screen sharing',
//                   backgroundColor:
//                       signaling.isScreenSharing() ? Colors.amber : Colors.grey,
//                   child: const Icon(Icons.screen_share_outlined),
//                   onPressed: () async => await doTry(
//                     runAsync: () => signaling.screenSharing(),
//                   ),
//                 ),
//                 if (signaling.isScreenSharing()) ...[
//                   FloatingActionButton(
//                     tooltip: 'Stop screen sharing',
//                     backgroundColor: Colors.redAccent,
//                     child: const Icon(Icons.stop_screen_share_outlined),
//                     onPressed: () => signaling.stopScreenSharing(),
//                   ),
//                 ],
//                 if (cameraCountSnap.hasData &&
//                     cameraCountSnap.requireData > 1) ...[
//                   FloatingActionButton(
//                     tooltip: 'Switch camera',
//                     backgroundColor: Colors.grey,
//                     child: const Icon(Icons.switch_camera),
//                     onPressed: () async => await doTry(
//                       runAsync: () => signaling.switchCamera(),
//                     ),
//                   )
//                 ],
//                 FloatingActionButton(
//                   tooltip: isMicMuted() ? 'Un-mute mic' : 'Mute mic',
//                   backgroundColor:
//                       isMicMuted() ? Colors.redAccent : Colors.grey,
//                   child: isMicMuted()
//                       ? const Icon(Icons.mic_off)
//                       : const Icon(Icons.mic_outlined),
//                   onPressed: () => doTry(
//                     runSync: () => setState(() => signaling.muteMic()),
//                   ),
//                 ),
//                 FloatingActionButton(
//                   tooltip: 'Hangup',
//                   backgroundColor: Colors.red,
//                   child: const Icon(Icons.call_end),
//                   onPressed: () => hangUp(false),
//                 ),
//                 FloatingActionButton(
//                   tooltip: 'Exit',
//                   backgroundColor: Colors.red,
//                   child: const Icon(Icons.exit_to_app),
//                   onPressed: () => hangUp(true),
//                 ),
//               ] else ...[
//                 FloatingActionButton(
//                   tooltip: 'Start call',
//                   child: const Icon(Icons.call),
//                   backgroundColor: Colors.green,
//                   onPressed: () async => await doTry(
//                     runAsync: () => join(),
//                     onError: () => hangUp(false),
//                   ),
//                 ),
//               ],
//             ],
//           ],
//         ),
//       ),
//       body: Container(
//         margin: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             // room
//             Container(
//               margin: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Room ID: "),
//                   Flexible(
//                     child: TextFormField(
//                       initialValue: roomId,
//                       onChanged: (value) => setState(() => roomId = value),
//                     ),
//                   )
//                 ],
//               ),
//             ),

//             // streaming
//             Expanded(
//               child: view(
//                 children: [
//                   if (localRenderOk) ...[
//                     Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.all(96),
//                         padding: const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: const Color(0XFF2493FB),
//                           ),
//                         ),
//                         child: RTCVideoView(localRenderer,
//                             mirror: !signaling.isScreenSharing()),
//                       ),
//                     ),
//                   ],
//                   for (final remoteRenderer in remoteRenderers.entries) ...[
//                     Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.all(4),
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: const Color(0XFF2493FB),
//                           ),
//                         ),
//                         child: false ==
//                                 remoteRenderersLoading[remoteRenderer
//                                     .key] // && true == remoteRenderer.value.srcObject?.active
//                             ? RTCVideoView(remoteRenderer.value)
//                             : const Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class VideoChatRoom extends StatefulWidget {
//   final String roomId;

//   const VideoChatRoom({super.key, required this.roomId});

//   @override
//   VideoChatRoomState createState() => VideoChatRoomState();
// }

// class VideoChatRoomState extends State<VideoChatRoom> {
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   MediaStream? _localStream;
//   RTCPeerConnection? _peerConnection;
//   bool _isInit = false;

//   @override
//   void initState() {
//     super.initState();
//     _initRenderers();
//   }

//   Future<void> _initRenderers() async {
//     try {
//       await _localRenderer.initialize();
//       await _remoteRenderer.initialize();
//       await _initLocalStream();
//       await _createPeerConnection();
//       if (mounted) {
//         setState(() {
//           _isInit = true;
//         });
//       }
//     } catch (e) {
//       print('Failed to initialize renderers: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Failed to initialize video: $e',
//               style: const TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _initLocalStream() async {
//     final Map<String, dynamic> mediaConstraints = {
//       'audio': true,
//       'video': {
//         'mandatory': {
//           'minWidth': '640',
//           'minHeight': '480',
//           'minFrameRate': '30',
//         },
//         'facingMode': 'user',
//         'optional': [],
//       }
//     };

//     try {
//       _localStream =
//           await navigator.mediaDevices.getUserMedia(mediaConstraints);
//       _localRenderer.srcObject = _localStream;
//     } catch (e) {
//       print('Failed to get local stream: $e');
//       rethrow;
//     }
//   }

//   Future<void> _createPeerConnection() async {
//     final Map<String, dynamic> configuration = {
//       'iceServers': [
//         {
//           'urls': [
//             'stun:stun1.l.google.com:19302',
//             'stun:stun2.l.google.com:19302'
//           ]
//         }
//       ]
//     };

//     final Map<String, dynamic> offerSdpConstraints = {
//       'mandatory': {
//         'OfferToReceiveAudio': true,
//         'OfferToReceiveVideo': true,
//       },
//       'optional': [],
//     };

//     try {
//       _peerConnection =
//           await createPeerConnection(configuration, offerSdpConstraints);

//       _localStream?.getTracks().forEach((track) {
//         _peerConnection?.addTrack(track, _localStream!);
//       });

//       _peerConnection?.onTrack = (RTCTrackEvent event) {
//         if (event.track.kind == 'video') {
//           _remoteRenderer.srcObject = event.streams[0];
//         }
//       };

//       // Here you would implement signaling and ICE candidate handling
//       // based on your backend implementation
//     } catch (e) {
//       print('Failed to create peer connection: $e');
//       rethrow;
//     }
//   }

//   @override
//   void dispose() {
//     _localStream?.getTracks().forEach((track) => track.stop());
//     _localStream?.dispose();
//     _peerConnection?.close();
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInit) {
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Room: ${widget.roomId}'),
//       ),
//       body: Stack(
//         children: [
//           RTCVideoView(
//             _remoteRenderer,
//             objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//           ),
//           Positioned(
//             right: 16,
//             bottom: 16,
//             child: Container(
//               width: 120,
//               height: 160,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: RTCVideoView(
//                   _localRenderer,
//                   mirror: true,
//                   objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                 ),
//               ),
//             ),
//           ),
//           // Add controls for debugging
//           Positioned(
//             left: 16,
//             bottom: 16,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Local Stream: ${_localStream != null}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 Text(
//                   'Peer Connection: ${_peerConnection != null}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
