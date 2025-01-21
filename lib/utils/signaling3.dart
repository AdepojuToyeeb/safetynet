import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreSignaling {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Function(Map<String, dynamic>)? onMessageCallback;
  String? roomId;
  String? peerId;
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  void initialize(String userId) {
    peerId = userId;
  }

  void joinRoom(String roomId, Position currentPosition) async {
    this.roomId = roomId;

    // Listen for room messages
    _messageSubscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['sender'] != peerId && onMessageCallback != null) {
            onMessageCallback!(data);
          }
        }
      }
    });

    // Add user to room
     await _firestore.collection('rooms').doc(roomId).set({
      'joined': FieldValue.serverTimestamp(),
      'location': GeoPoint(
        currentPosition.latitude,
        currentPosition.longitude,
      ),
      'active': true
    });
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (roomId == null || peerId == null) return;

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      ...message,
      'sender': peerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void leaveRoom() async {
    if (roomId != null && peerId != null) {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(peerId)
          .update({'active': false, 'left': FieldValue.serverTimestamp()});
    }
    _messageSubscription?.cancel();
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final FirestoreSignaling _signaling;

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionStateChange;

  WebRTCService(this._signaling) {
    _signaling.onMessageCallback = _handleSignalingMessage;
  }

  Future<void> initialize() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': ['turn:your-turn-server.com:3478'],
          'username': 'your-username',
          'credential': 'your-password'
        }
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      _signaling.sendMessage({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (onRemoteStream != null) {
          onRemoteStream!(_remoteStream!);
        }
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (onConnectionStateChange != null) {
        onConnectionStateChange!(state);
      }
    };

    await _setupLocalStream();
  }

  Future<void> _setupLocalStream() async {
    final constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720}
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    if (onLocalStream != null) {
      onLocalStream!(_localStream!);
    }

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void _handleSignalingMessage(Map<String, dynamic> message) async {
    switch (message['type']) {
      case 'offer':
        await _handleOffer(message);
        break;
      case 'answer':
        await _handleAnswer(message);
        break;
      case 'candidate':
        await _handleCandidate(message);
        break;
      case 'join':
        await _createOffer();
        break;
    }
  }

  Future<void> _createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _signaling.sendMessage({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  Future<void> _handleOffer(Map<String, dynamic> message) async {
    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message['sdp'], message['type']));

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _signaling.sendMessage({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message['sdp'], message['type']));
  }

  Future<void> _handleCandidate(Map<String, dynamic> message) async {
    if (message['candidate'] != null) {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          message['candidate']['candidate'],
          message['candidate']['sdpMid'],
          message['candidate']['sdpMLineIndex'],
        ),
      );
    }
  }

  void toggleMicrophone(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void toggleCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void dispose() {
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.dispose();
  }
}
