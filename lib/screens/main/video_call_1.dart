// screens/video_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safetynet/utils/signaling3.dart';
import 'package:safetynet/utils/snack_message.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final String userId;

  const VideoCallScreen(
      {super.key, required this.roomId, required this.userId});

  @override
  VideoCallScreenState createState() => VideoCallScreenState();
}

class VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  late FirestoreSignaling _signaling;
  late WebRTCService _webRTC;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  String _connectionStatus = 'Connecting...';
  bool _initStatusLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
      _initializeCall();
    } catch (e) {
      SnackMsg.showError(context, 'Error getting location: $e');
    }
  }

  Future<void> _initializeCall() async {
    setState(() {
      _initStatusLoading = false;
    });
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling = FirestoreSignaling();
    _signaling.initialize(widget.userId);

    _webRTC = WebRTCService(_signaling);

    _webRTC.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    _webRTC.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _connectionStatus = 'Connected';
      });
    };

    _webRTC.onConnectionStateChange = (state) {
      setState(() {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _connectionStatus = 'Connected';
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _connectionStatus = 'Disconnected';
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _connectionStatus = 'Connection failed';
            break;
          default:
            _connectionStatus = 'Connecting...';
        }
      });
    };

    await _webRTC.initialize();
    _signaling.joinRoom(widget.roomId, _currentPosition!);
  }

  void _toggleMicrophone() {
    setState(() {
      _isMicMuted = !_isMicMuted;
      _webRTC.toggleMicrophone(!_isMicMuted);
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
      _webRTC.toggleCamera(!_isCameraOff);
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webRTC.dispose();
    _signaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(_connectionStatus),
            ),
          ),
        ],
      ),
      body: _initStatusLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  right: 20,
                  bottom: 100,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                          onPressed: _toggleMicrophone,
                          color: Colors.white,
                        ),
                        IconButton(
                          icon: Icon(_isCameraOff
                              ? Icons.videocam_off
                              : Icons.videocam),
                          onPressed: _toggleCamera,
                          color: Colors.white,
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_end),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
