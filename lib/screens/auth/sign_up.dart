import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:safetynet/screens/auth/login_or_signup_screen.dart';
import 'package:safetynet/screens/verification/verify_phone.dart';
import 'package:safetynet/widget/custom_next_button.dart';

// Define a provider for FirebaseAuth
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Define a provider for the signup state
final signupProvider =
    StateNotifierProvider<SignupNotifier, AsyncValue<UserCredential?>>((ref) {
  return SignupNotifier(ref.watch(firebaseAuthProvider));
});

class SignupNotifier extends StateNotifier<AsyncValue<UserCredential?>> {
  final FirebaseAuth _auth;

  SignupNotifier(this._auth) : super(const AsyncValue.data(null));

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
        print(next.error);
        print(
            "[firebase_auth/weak-password] Password should be at least 6 characters"
                .replaceAll(RegExp(r'\[.*?\]'), '')
                .trim());

      //  final errorMessage =
      //      ( next.error)?.replaceAll(RegExp(r'\[.*?\]'), '').trim() ??
      //           '';
      //   final cleanedMessage = errorMessage.replaceAll(RegExp(r'\s+'), ' ');
      //   print('cleanedMessage: $cleanedMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8), // Spacing between icon and text
                Expanded(child: Text('Error: ${next.error}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Show success snackbar if signup is successful
      if (next.hasValue && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Signup successful! User ID: ${next.value!.user!.uid}'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          // Navigate to the next screen (replace with your destination)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PhoneNumberScreen(),
            ), // Replace with your screen widget
          );
        });
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
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
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomNextButton(
                onPressed: () {
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
    );
  }
}
