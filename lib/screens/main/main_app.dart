import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safetynet/utils/signaling.dart';
import 'package:safetynet/utils/webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webRTCService =
        WebRTCService(userId: FirebaseAuth.instance.currentUser!.uid);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello Christy!',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Wuse, Adetokunbo Ademola Cres...',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search zones...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
            const SizedBox(width: 32), // Space for FAB
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
            // IconButton(icon: const Icon(Icons.person), onPressed: () {}),
            ElevatedButton(
              onPressed: () {
                signaling.openUserMedia(_localRenderer, _remoteRenderer);
              },
              child: const Icon(Icons.person),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // onPressed: () {},
        // onPressed: () async {
        //    final webRTCService = WebRTCService(
        //     userId: FirebaseAuth.instance.currentUser!.uid,
        //   );
        //   try {
        //     final roomId = await webRTCService.createRoom();
        //     if (!context.mounted) return;

        //     // Navigate to the video chat room
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => VideoChatRoom(roomId: roomId),
        //   ),
        // );
        //   } catch (e) {
        //     if (!context.mounted) return;
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text(
        //           'Failed to create room: ${e.toString()}',
        //           style: const TextStyle(color: Colors.white),
        //         ),
        //         backgroundColor: Colors.red,
        //         behavior: SnackBarBehavior.floating,
        //         margin: const EdgeInsets.all(16),
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //       ),
        //     );
        //   }
        // },
        onPressed: () async {
          // roomId = await signaling.createRoom(_remoteRenderer);
          // textEditingController.text = roomId!;
          // setState(() {});
          //   Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => VideoChatRoom(roomId: "B8y9pNw2SWdhfBJcVtp9"),
          //   ),
          // );
          signaling.joinRoom(
            "B8y9pNw2SWdhfBJcVtp9",
            _remoteRenderer,
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class VideoChatRoom extends StatefulWidget {
  final String roomId;

  const VideoChatRoom({super.key, required this.roomId});

  @override
  VideoChatRoomState createState() => VideoChatRoomState();
}

class VideoChatRoomState extends State<VideoChatRoom> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      await _initLocalStream();
      await _createPeerConnection();
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      print('Failed to initialize renderers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize video: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print('Failed to get local stream: $e');
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    try {
      _peerConnection =
          await createPeerConnection(configuration, offerSdpConstraints);

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          _remoteRenderer.srcObject = event.streams[0];
        }
      };

      // Here you would implement signaling and ICE candidate handling
      // based on your backend implementation
    } catch (e) {
      print('Failed to create peer connection: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
      ),
      body: Stack(
        children: [
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
          // Add controls for debugging
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Stream: ${_localStream != null}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Peer Connection: ${_peerConnection != null}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
