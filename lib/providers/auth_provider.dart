import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safetynet/screens/main/main_app.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
    ]);
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Error Handler
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return e.toString();
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isLoggedIn() {
    return state.isLoggedIn;
  }

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Read the login timestamp
      final loginTimestamp = await _storage.read(key: 'login_timestamp');

      if (loginTimestamp != null) {
        final loginTime = DateTime.parse(loginTimestamp);
        final currentTime = DateTime.now();

        // Check if login is still valid (within 6 hours)
        if (currentTime.difference(loginTime).inHours < 6) {
          state = state.copyWith(isLoggedIn: true);
        } else {
          // Token expired, reset login status
          await _storage.deleteAll();
          state = state.copyWith(isLoggedIn: false);
        }
      }
    } catch (e) {
      // If there's any error in reading or parsing, reset login status
      await _storage.deleteAll();
      state = state.copyWith(isLoggedIn: false);
    }
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  // Future<void> signIn(BuildContext context) async {
  //   // Implement your sign in logic here
  // Navigator.pushReplacement(
  //   context,
  //   MaterialPageRoute(builder: (context) => const MainScreen()),
  // );
  //   // After successful sign in, you might want to navigate to another screen
  // }

  Future<void> logout() async {
    // Clear storage and reset login state
    await _storage.deleteAll();
    state = state.copyWith(isLoggedIn: false, email: '', password: '');

    // Optional: Add any additional logout logic like Firebase signOut
    await _authService.signOut();
  }

  Future<void> signIn(BuildContext context) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter email and password',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // Makes it floating
          margin: const EdgeInsets.all(16), // Adds margin around the SnackBar
          shape: RoundedRectangleBorder(
            // Rounds the corners
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      if (!context.mounted) return;
      await _authService.signInWithEmailAndPassword(
          state.email, state.password);
      state = state.copyWith(isLoading: false);
      if (!context.mounted) return;
      final loginTimestamp = DateTime.now().toIso8601String();
      await _storage.write(key: 'login_timestamp', value: loginTimestamp);

      await _storage.write(key: 'auth_token', value: 'your_generated_token');
      state = state.copyWith(isLoggedIn: true, isLoading: false);
      
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

// State class for authentication
class AuthState {
  final String email;
  final String password;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  AuthState({
    this.isLoggedIn = false,
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? email,
    bool? isLoggedIn,
    String? password,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

final passwordVisibilityProvider = StateProvider<bool>((ref) => true);
