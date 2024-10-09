import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<void> signIn() async {
    // Implement your sign in logic here
    print(
        'Signing in with email: ${state.email} and password: ${state.password}');
    // After successful sign in, you might want to navigate to another screen
  }
}

// State class for authentication
class AuthState {
  final String email;
  final String password;

  AuthState({this.email = '', this.password = ''});

  AuthState copyWith({String? email, String? password}) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}


final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
