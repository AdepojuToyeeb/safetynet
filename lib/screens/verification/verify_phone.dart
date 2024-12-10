import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:safetynet/screens/verification/confirm_phone_number.dart';
import 'package:safetynet/widget/custom_next_button.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController controller = TextEditingController();
  String initialCountry = 'NG';
  PhoneNumber number = PhoneNumber(isoCode: 'NG');
  bool _isLoading = false;

  Future<void> _saveUserDetails() async {
    print("controller");
    print(controller);
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user after phone authentication
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // If user is not logged in, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please complete phone verification first')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // // Update user profile with name
      // await currentUser.updateProfile(
      //   DisplayNameUpdater(displayName: _nameController.text.trim()),
      // );

      // Save additional user details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'phoneNumber': controller.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Navigate to next screen
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const ConfirmPhoneNumber()),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What’s Your Phone Number?",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "Don’t worry! Your phone number will remain private and won’t be visible to others. We just need it for verification purposes.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Phone Number",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber number) {
                    print(number.phoneNumber);
                  },
                  onInputValidated: (bool value) {
                    print(value);
                  },
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.DIALOG,
                    useBottomSheetSafeArea: true,
                  ),
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.disabled,
                  selectorTextStyle: const TextStyle(color: Colors.black),
                  initialValue: number,
                  textFieldController: controller,
                  formatInput: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputBorder: const OutlineInputBorder(),
                  inputDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(),
                  ),
                  cursorColor: Colors.black,
                  onSaved: (PhoneNumber number) {
                    print('On Saved: $number');
                  },
                ),
                const SizedBox(
                  height: 60,
                ),
                CustomNextButton(
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const ConfirmPhoneNumber(),
                    //   ),
                    // );
                    _isLoading ? () {} : _saveUserDetails();
                  },
                  text: _isLoading ? "Proceeding" : "Proceed",
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
