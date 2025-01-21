import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safetynet/screens/main/video_call_1.dart';

class RoomModel {
  final String id;
  final String hostId;
  final DateTime createdAt;
  final bool isActive;
  final String roomName;
  final int maxParticipants;
  final List<String> participants;

  RoomModel({
    required this.id,
    required this.hostId,
    required this.createdAt,
    required this.isActive,
    required this.roomName,
    this.maxParticipants = 2,
    required this.participants,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
      roomName: map['roomName'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 2,
      participants: List<String>.from(map['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'createdAt': createdAt,
      'isActive': isActive,
      'roomName': roomName,
      'maxParticipants': maxParticipants,
      'participants': participants,
    };
  }
}

// services/room_service.dart
class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RoomModel> createRoom({
    required String hostId,
    required String roomName,
    int maxParticipants = 2,
  }) async {
    final roomRef = _firestore.collection('rooms').doc();

    final room = RoomModel(
      id: roomRef.id,
      hostId: hostId,
      createdAt: DateTime.now(),
      isActive: true,
      roomName: roomName,
      maxParticipants: maxParticipants,
      participants: [hostId],
    );

    await roomRef.set(room.toMap());
    return room;
  }

  Future<bool> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    return _firestore.runTransaction<bool>((transaction) async {
      final roomDoc = await transaction.get(roomRef);

      if (!roomDoc.exists) {
        throw Exception('Room not found');
      }

      final room = RoomModel.fromMap(roomDoc.data()!..['id'] = roomDoc.id);

      if (!room.isActive) {
        throw Exception('Room is no longer active');
      }

      if (room.participants.length >= room.maxParticipants) {
        throw Exception('Room is full');
      }

      if (room.participants.contains(userId)) {
        return true; // Already joined
      }

      transaction.update(roomRef, {
        'participants': FieldValue.arrayUnion([userId])
      });

      return true;
    });
  }

  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);

      if (!roomDoc.exists) return;

      final room = RoomModel.fromMap(roomDoc.data()!..['id'] = roomDoc.id);

      if (room.hostId == userId) {
        // If host leaves, close the room
        transaction.update(roomRef, {
          'isActive': false,
          'participants': FieldValue.arrayRemove([userId])
        });
      } else {
        // If participant leaves, just remove them
        transaction.update(roomRef, {
          'participants': FieldValue.arrayRemove([userId])
        });
      }
    });
  }

  Stream<List<RoomModel>> getActiveRooms() {
    return _firestore
        .collection('rooms')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    });
  }
}

// screens/join_call_screen.dart
class JoinCallScreen extends StatefulWidget {
  final String userId;

  const JoinCallScreen({super.key, required this.userId});

  @override
  JoinCallScreenState createState() => JoinCallScreenState();
}

class JoinCallScreenState extends State<JoinCallScreen> {
  final RoomService _roomService = RoomService();
  final TextEditingController _roomNameController = TextEditingController();
  bool _isCreatingRoom = false;

  Future<void> _createAndJoinRoom() async {
    if (_roomNameController.text.isEmpty) return;

    setState(() => _isCreatingRoom = true);

    try {
      final room = await _roomService.createRoom(
        hostId: widget.userId,
        roomName: _roomNameController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            roomId: room.id,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: ${e.toString()}')),
      );
    } finally {
      setState(() => _isCreatingRoom = false);
    }
  }

  Future<void> _joinRoom(RoomModel room) async {
    try {
      final joined = await _roomService.joinRoom(
        roomId: room.id,
        userId: widget.userId,
      );

      if (joined) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              roomId: room.id,
              userId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Call')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                  ),
                ),
               const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isCreatingRoom ? null : _createAndJoinRoom,
                  child: _isCreatingRoom
                      ? const CircularProgressIndicator()
                      : const Text('Create New Room'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<RoomModel>>(
              stream: _roomService.getActiveRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!;

                if (rooms.isEmpty) {
                  return const Center(child: Text('No active rooms'));
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final hasJoined = room.participants.contains(widget.userId);

                    return ListTile(
                      title: Text(room.roomName),
                      subtitle: Text(
                          'Participants: ${room.participants.length}/${room.maxParticipants}'),
                      trailing: hasJoined
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : (room.participants.length < room.maxParticipants
                              ? ElevatedButton(
                                  onPressed: () => _joinRoom(room),
                                  child: const  Text('Join'),
                                )
                              : const Text('Full')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }
}



class JoinExistingRoomScreen extends StatefulWidget {
  final String userId;

  const JoinExistingRoomScreen({
    super.key,
    required this.userId,
  });

  @override
  JoinExistingRoomScreenState createState() => JoinExistingRoomScreenState();
}

class JoinExistingRoomScreenState extends State<JoinExistingRoomScreen> {
  final _roomIdController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() => _errorMessage = 'Please enter a room ID');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      // Check if room exists and is active
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();

      if (!roomDoc.exists) {
        setState(() {
          _errorMessage = 'Room not found';
          _isJoining = false;
        });
        return;
      }

      final roomData = roomDoc.data()!;
      // if (!(roomData['isActive'] ?? false)) {
      //   setState(() {
      //     _errorMessage = 'This room is no longer active';
      //     _isJoining = false;
      //   });
      //   return;
      // }

      // Check if room is full
      final participants = List<String>.from(roomData['participants'] ?? []);
      final maxParticipants = roomData['maxParticipants'] ?? 2;

      if (participants.length >= maxParticipants) {
        setState(() {
          _errorMessage = 'Room is full';
          _isJoining = false;
        });
        return;
      }

      // Add user to room participants
      if (!participants.contains(widget.userId)) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .update({
          'participants': FieldValue.arrayUnion([widget.userId])
        });
      }

      // Navigate to video call screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            roomId: roomId,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join room: ${e.toString()}';
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter the room ID to join',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              enabled: !_isJoining,
               style:const TextStyle(color: Colors.white)
            ),
           const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinRoom,
              child: _isJoining
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Joining...'),
                      ],
                    )
                  : const  Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }
}

// Use this method to show room ID to the host
void showRoomIdDialog(BuildContext context, String roomId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const  Text('Room Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           const  Text('Share this Room ID with others to join:'),
           const  SizedBox(height: 10),
            SelectableText(
              roomId,
              style: const  TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const  Text('OK'),
          ),
        ],
      );
    },
  );
}