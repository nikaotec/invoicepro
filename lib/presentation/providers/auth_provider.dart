import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Ensure Firebase is initialized
      await Firebase.app();

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        state = state.copyWith(user: user, isLoading: false);
      });

      // Check if user is already logged in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        state = state.copyWith(user: currentUser);
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Auth: $e');
      state = state.copyWith(
        error: 'Firebase not initialized. Please check your configuration.',
      );
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        state = state.copyWith(user: userCredential.user, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed.';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        state = state.copyWith(user: userCredential.user, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Google Sign In failed';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google Sign In is not enabled.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'Google Sign In failed.';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return false;
    } catch (e) {
      // Handle PlatformException (ApiException: 10 - DEVELOPER_ERROR)
      String errorMessage = 'Google Sign In failed';
      final errorString = e.toString();

      if (errorString.contains('ApiException: 10') ||
          errorString.contains('DEVELOPER_ERROR') ||
          errorString.contains('sign_in_failed')) {
        errorMessage =
            'Google Sign In configuration error. Please check:\n'
            '1. SHA-1 fingerprint is registered in Firebase Console\n'
            '2. Google Sign In is enabled in Firebase Authentication\n'
            '3. Package name matches Firebase configuration\n\n'
            'SHA-1: 98:50:38:3F:1F:2B:BC:F8:C2:B7:4C:99:9D:54:0E:4A:9A:7D:BC:EE\n\n'
            'See GOOGLE_SIGNIN_SETUP.md for instructions.';
      } else {
        errorMessage = 'Google Sign In failed: ${e.toString()}';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google Sign In
      await _googleSignIn.signOut();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to sign out: ${e.toString()}');
    }
  }

  /// Create account with email and password
  Future<bool> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        state = state.copyWith(user: userCredential.user, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed.';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send password reset email';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send password reset email: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
