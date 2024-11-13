import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCService {
  final _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  final String userId;

  WebRTCService({required this.userId});

  //check and request permission
  Future<bool> _handlePermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    bool cameras = await Permission.camera.isGranted;
    bool microphone = await Permission.microphone.isGranted;

    return cameras && microphone;
  }

  Future<String> createRoom() async {
    bool hasPermissions = await _handlePermissions();
    if (!hasPermissions) {
      throw 'Permissions not granted';
    }
    final roomId = const Uuid().v4();

    // WebRTC configuration
    final configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };

    // Create peer connection
    peerConnection = await createPeerConnection(configuration);

    // Get local stream
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
      }
    });

    // Add local stream to peer connection
    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    // Create room in Firestore
    await _firestore.collection('rooms').doc(roomId).set({
      'created': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'offer': null,
      'answer': null,
    });

    // Listen for remote ICE candidates
    _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          final candidate = RTCIceCandidate(
            change.doc.data()!['candidate'],
            change.doc.data()!['sdpMid'],
            change.doc.data()!['sdpMLineIndex'],
          );
          peerConnection!.addCandidate(candidate);
        }
      });
    });

    // Create and set local description
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    // Save the offer to Firestore
    await _firestore.collection('rooms').doc(roomId).update({
      'offer': offer.toMap(),
    });

    // Handle ICE candidates
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('candidates')
          .add(candidate.toMap());
    };

    return roomId;
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    // peerConnection?.onAddStream = (MediaStream stream) {
    //   print("Add remote stream");
    //   onAddRemoteStream?.call(stream);
    //   remoteStream = stream;
    // };
  }
}
