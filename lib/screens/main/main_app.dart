import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safetynet/screens/main/video_call.dart';
import 'package:safetynet/utils/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/widget/map.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  String userName = 'Loading...';
  String userLocation = 'Fetching location...';
  String userProfilePicUrl = '';

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Get current authenticated user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        setState(() {
          userName = userDoc['fullName'] ?? userDoc['email'] ?? 'User';
          userLocation = '';
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        userName = '';
        userLocation = '';
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            //  _buildRoomList(),
            SafeArea(
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          const Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Wuse, Adetokunbo Ademola Cres...',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: RoomMapWidget())
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       IconButton(icon: const Icon(Icons.home), onPressed: () {}),
      //       IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      //       const SizedBox(width: 32), // Space for FAB
      //       IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
      //       IconButton(icon: const Icon(Icons.person), onPressed: () {}),

      //     ],
      //   ),
      // ),
      floatingActionButton: GestureDetector(
         onLongPress: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VideoCallRoom(),
            ),
          );
        },
        child: FloatingActionButton(
          
          onPressed: () async {
            // // roomId = await signaling.createRoom(_remoteRenderer);
            // // textEditingController.text = roomId!;
            // // setState(() {});
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const VideoCallRoom(),
            //   ),
            // );
          },
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
          child: const Icon(Icons.emergency_recording,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

extension on User {
  get fullName => null;
}
