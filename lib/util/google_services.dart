import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

class GoogleSignInResult {
  final bool succeeded;
  final String? errorMessage;

  const GoogleSignInResult._({required this.succeeded, this.errorMessage});

  const GoogleSignInResult.success() : this._(succeeded: true);

  const GoogleSignInResult.failure(String message)
    : this._(succeeded: false, errorMessage: message);

  const GoogleSignInResult.cancelled() : this._(succeeded: false);
}

class GoogleServices {
  static Future<void>? _initialization;

  static Future<void> initialize() =>
      _initialization ??= GoogleSignIn.instance.initialize(
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS
                ? DefaultFirebaseOptions.ios.iosClientId
                : null,
        serverClientId:
            '550818826311-9okroqsll4hhrma17qsfplkcc2er76ek.apps.googleusercontent.com',
      );

  static Future<OAuthCredential> credential() async {
    await initialize();
    final user = await GoogleSignIn.instance.authenticate();
    return GoogleAuthProvider.credential(idToken: user.authentication.idToken);
  }

  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      await FirebaseAuth.instance.signInWithCredential(await credential());
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const GoogleSignInResult.failure(
          'Google did not return an account. Please try again.',
        );
      }
      // HomePage provisions the reader profile after authStateChanges fires.
      return const GoogleSignInResult.success();
    } on GoogleSignInException catch (error) {
      _logFailure('Google account selection', error.code.name);
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode
            .interrupted => const GoogleSignInResult.cancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode
            .providerConfigurationError => const GoogleSignInResult.failure(
          'Google sign-in needs an app configuration update. Please use email sign-in for now.',
        ),
        _ => const GoogleSignInResult.failure(
          'Google sign-in could not be completed. Please try again.',
        ),
      };
    } on FirebaseAuthException catch (error) {
      _logFailure('Firebase authentication', error.code);
      if (error.code == 'operation-not-allowed') {
        return const GoogleSignInResult.failure(
          'Google sign-in is disabled in Firebase Authentication for this project.',
        );
      }
      if (error.code == 'account-exists-with-different-credential') {
        return const GoogleSignInResult.failure(
          'An account already uses this email with a different sign-in method.',
        );
      }
      return const GoogleSignInResult.failure(
        'Firebase could not complete Google sign-in. Please try again.',
      );
    } catch (error) {
      _logFailure('Google sign-in', error.runtimeType.toString());
      return const GoogleSignInResult.failure(
        'Google sign-in could not be completed. Please try again.',
      );
    }
  }

  static void _logFailure(String stage, String code) {
    if (kDebugMode) {
      debugPrint('Bookfania sign-in: $stage failed ($code).');
    }
  }
}
