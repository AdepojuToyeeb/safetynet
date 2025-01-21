import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safetynet/screens/main/video_call_agora.dart';
import 'package:safetynet/utils/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safetynet/widget/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
    super.initState();
    _fetchUserDetails();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            userLocation = 'Location permissions denied';
          });
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        // Build address string with available components
        if (place.street?.isNotEmpty == true) {
          address += place.street!;
        }
        if (place.subLocality?.isNotEmpty == true) {
          address +=
              address.isEmpty ? place.subLocality! : ', ${place.subLocality}';
        }
        if (place.locality?.isNotEmpty == true) {
          address += address.isEmpty ? place.locality! : ', ${place.locality}';
        }

        // Update Firebase with user's location
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'location': GeoPoint(position.latitude, position.longitude),
            'address': address,
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          });
        }

        setState(() {
          userLocation = address;
        });
      }
    } catch (e) {
      setState(() {
        userLocation = 'Error fetching location';
      });
      print('Error getting location: $e');
    }
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
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  userLocation,
                                  style: const TextStyle(
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
            MaterialPageRoute(builder: (context) => const AgoraCall()),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Long press to start recording'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.emergency_recording,
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
