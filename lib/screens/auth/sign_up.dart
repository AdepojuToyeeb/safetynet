import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:safetynet/providers/auth_provider.dart';
import 'package:safetynet/providers/firebase_provider.dart';
// import 'package:safetynet/screens/auth/login_or_signup_screen.dart';
import 'package:safetynet/screens/verification/verify_phone.dart';
import 'package:safetynet/widget/custom_next_button.dart';

// Define a provider for FirebaseAuth
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Define a provider for the signup state
final signupProvider =
    StateNotifierProvider<SignupNotifier, AsyncValue<UserCredential?>>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SignupNotifier(firebaseAuth, firestore);
});

class SignupNotifier extends StateNotifier<AsyncValue<UserCredential?>> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SignupNotifier(this._auth, this._firestore)
      : super(const AsyncValue.data(null));

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = AsyncValue.data(userCredential);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class SignupWidget extends ConsumerWidget {
  SignupWidget({super.key});

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupState = ref.watch(signupProvider);

    ref.listen(signupProvider, (previous, next) {
      // Show error snackbar if there is an error
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8), // Spacing between icon and text
                Expanded(child: Text('${next.error}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Show success snackbar if signup is successful
      if (next.hasValue && next.value != null) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Signup successful!'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
        // Future.delayed(const Duration(seconds: 1), () {
        //   // Navigate to the next screen (replace with your destination)
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const PhoneNumberScreen(),
        //   ), // Replace with your screen widget
        // );
        // });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return PopScope(
              // Prevents Android back button from dismissing
              canPop: false,
              child: AlertDialog(
                backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  'Success',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Signup successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhoneNumberScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Proceed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    });

    void validateInput(WidgetRef ref, AsyncValue<UserCredential?> signupState) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "Email and password must be provided",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
        );
        return;
      }

      if (!signupState.isLoading) {
        ref.read(signupProvider.notifier).signUp(
              _emailController.text,
              _passwordController.text,
            );
      }
    }

    final isObscured = ref.watch(passwordVisibilityProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Safetynet.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'To get started, sign up with your email and password to your account.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: isObscured,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscured ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        ref.read(passwordVisibilityProvider.notifier).state =
                            !isObscured;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomNextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    validateInput(ref, signupState);
                  },
                  text: "Sign up",
                  enabled: !signupState.isLoading,
                  isLoading: signupState.isLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
