// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safetynet/providers/auth_provider.dart';
import 'package:safetynet/screens/main/main_app.dart';
import 'package:safetynet/widget/custom_next_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48),
                LogoWidget(assetPath: 'assets/images/logo.png'),
                SizedBox(height: 24),
                WelcomeTextWidget(),
                SizedBox(height: 48),
                EmailInputWidget(),
                SizedBox(height: 30),
                PasswordInputWidget(),
                SizedBox(height: 64),
                SignInButtonWidget(),
                SizedBox(height: 30),
                // OrDividerWidget(),
                // SizedBox(height: 30),
                // GoogleSignInButtonWidget(),
                // SizedBox(height: 16),
                // AppleSignInButtonWidget(),
                SizedBox(height: 48), // Add extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LogoWidget extends StatelessWidget {
  final String assetPath;

  const LogoWidget({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.contain,
          width: 100,
          height: 100,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, color: Colors.red);
          },
        ),
        const Text(
          "Safetynet.",
          style: TextStyle(
              color: Color.fromRGBO(25, 118, 210, 1),
              fontWeight: FontWeight.w600,
              fontSize: 24),
        )
      ],
    );
  }
}

class WelcomeTextWidget extends StatelessWidget {
  const WelcomeTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          'To get started, sign in to your account.',
          style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class EmailInputWidget extends ConsumerWidget {
  const EmailInputWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: authNotifier.setEmail,
    );
  }
}

class PasswordInputWidget extends ConsumerWidget {
  const PasswordInputWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    final isObscured = ref.watch(passwordVisibilityProvider);
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            ref.read(passwordVisibilityProvider.notifier).state = !isObscured;
          },
        ),
      ),
      obscureText: isObscured,
      onChanged: authNotifier.setPassword,
    );
  }
}

class SignInButtonWidget extends ConsumerWidget {
  const SignInButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    return CustomNextButton(
      onPressed:
          authState.isLoading ? () {} : () => authNotifier.signIn(context),
      text: authState.isLoading ? "Signing in..." : "Sign In",
      enabled: !authState.isLoading,
    );
  }
}

class OrDividerWidget extends StatelessWidget {
  const OrDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('or'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

class GoogleSignInButtonWidget extends StatelessWidget {
  const GoogleSignInButtonWidget({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth == null) {
        // User canceled the sign-in process
        return;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to the home screen or next page
      if (userCredential.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Handle sign-in errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Google Sign-In failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.g_translate, color: Colors.black),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(color: Colors.black),
      ),
      onPressed: () => _signInWithGoogle(context),
    );
  }
}

class AppleSignInButtonWidget extends StatelessWidget {
  const AppleSignInButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(
        Icons.apple,
        color: Colors.black,
      ),
      label: const Text(
        'Sign in with Apple',
        style: TextStyle(color: Colors.black),
      ),
      onPressed: () {
        // Implement Apple sign in
      },
    );
  }
}
