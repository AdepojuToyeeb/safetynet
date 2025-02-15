import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safetynet/screens/emergency/add_emergency.dart';
// import 'package:safetynet/screens/verification/confirm_phone_number.dart';
import 'package:safetynet/widget/custom_next_button.dart';

class FullNameScreen extends StatefulWidget {
  const FullNameScreen({super.key});

  @override
  State<FullNameScreen> createState() => _FullNameScreenState();
}

class _FullNameScreenState extends State<FullNameScreen> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  bool _isLoading = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user's UID
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          // Handle case where no user is logged in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user is currently logged in')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Save name to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'fullName': _enteredName,
          'email': currentUser.email,
          'uid': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Navigate to next screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencySetupScreen(),
          ),
        );
      } catch (error) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving name: $error')),
        );
      } finally {
        // Reset loading state
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What is your name?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please enter your full name to make it easier for your contacts to recognize you.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        maxLength: 50,
                        cursorColor: Colors.blue,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          label: Text(
                            "Name",
                            style: TextStyle(color: Colors.black),
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // border color when not focused
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Colors.black), // border color when focused
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length < 2 ||
                              value.trim().length > 50) {
                            return "Value Must be within 2 and 50 characters";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredName = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomNextButton(
                  onPressed: () {
                    _isLoading ? () {} : _saveItem();
                  },
                  text: _isLoading ? "Saving..." : "Proceed",
                  enabled: !_isLoading,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
