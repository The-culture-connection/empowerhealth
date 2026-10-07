import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Turns any error thrown during sign in / sign up into a short,
/// plain-language message. Never returns raw exception text or error codes.
class AuthErrorMessages {
  AuthErrorMessages._();

  static const String generic =
      'Something went wrong. Please try again in a moment.';

  /// True when the user simply backed out of a Google/Apple sheet, in which
  /// case no error should be shown at all.
  static bool isUserCancellation(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      return error.code == AuthorizationErrorCode.canceled;
    }
    if (error is FirebaseAuthException) {
      return error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request' ||
          error.code == 'web-context-canceled';
    }
    if (error is PlatformException) {
      return error.code == 'sign_in_canceled' ||
          error.code == 'popup_closed_by_user';
    }
    return false;
  }

  static const String googleFailed =
      'Google sign-in didn\'t work. Please try again or use email instead.';
  static const String appleFailed =
      'Apple sign-in didn\'t work. Please try again or use email instead.';

  /// Message for a failed email/password, Google or Apple sign-in or sign-up.
  /// [fallback] is used when the error isn't recognised; pass [googleFailed]
  /// or [appleFailed] from the social sign-in paths.
  static String forError(Object error, {String fallback = generic}) {
    if (error is FirebaseAuthException) {
      return forCode(error.code) ?? _fromText(error.message ?? '') ?? fallback;
    }
    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return 'Apple sign-in was cancelled.';
      }
      return appleFailed;
    }
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('network')) return forCode('network-request-failed')!;
      return fallback;
    }
    // AuthService rethrows FirebaseAuthException as a String (already mapped)
    // or wraps other failures in Exception(...); match on known text.
    return _fromText(error.toString()) ?? fallback;
  }

  /// Maps a FirebaseAuthException code to a friendly message.
  static String? forCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right. Please check it and try again.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'That email and password don\'t match. Try again or reset your password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again, or reset your password.';
      case 'network-request-failed':
        return 'We couldn\'t connect. Check your internet connection and try again.';
      case 'user-disabled':
        return 'This account has been turned off. Please contact support for help.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'An account with this email already exists. Try signing in instead.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to a different sign-in method. Try signing in another way.';
      case 'weak-password':
        return 'Please choose a stronger password with at least 6 characters.';
      case 'missing-email':
        return 'Please enter your email address.';
      case 'missing-password':
        return 'Please enter your password.';
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return 'This sign-in option isn\'t available right now. Please try another way.';
      case 'requires-recent-login':
        return 'For your security, please sign in again and retry.';
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'This link has expired. Please request a new one.';
      case 'popup-blocked':
        return 'Your browser blocked the sign-in window. Please allow pop-ups and try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
        return 'Sign-in was cancelled.';
      case 'unauthorized-domain':
      case 'internal-error':
        return generic;
      default:
        return null;
    }
  }

  static String? _fromText(String raw) {
    final text = raw.toLowerCase();
    if (text.isEmpty) return null;

    // Friendly strings produced by AuthService._handleAuthException.
    if (text.contains('no user found') || text.contains('wrong password')) {
      return forCode('invalid-credential');
    }
    if (text.contains('already exists with this email') ||
        text.contains('email address is already in use')) {
      return forCode('email-already-in-use');
    }
    if (text.contains('email address is invalid') ||
        text.contains('badly formatted')) {
      return forCode('invalid-email');
    }
    if (text.contains('password is too weak') ||
        text.contains('password should be at least')) {
      return forCode('weak-password');
    }
    if (text.contains('has been disabled')) return forCode('user-disabled');
    if (text.contains('operation is not allowed') ||
        text.contains('not enabled')) {
      return forCode('operation-not-allowed');
    }

    // Raw Firebase messages that fall through AuthService's default case.
    if (text.contains('credential is incorrect') ||
        text.contains('invalid_login_credentials') ||
        text.contains('invalid-credential') ||
        text.contains('malformed or has expired')) {
      return forCode('invalid-credential');
    }
    if (text.contains('too many') ||
        text.contains('blocked all requests') ||
        text.contains('too-many-requests')) {
      return forCode('too-many-requests');
    }
    if (text.contains('network')) return forCode('network-request-failed');
    if (text.contains('popup') && text.contains('closed')) {
      return forCode('popup-closed-by-user');
    }

    if (text.contains('google sign-in')) return googleFailed;
    return null;
  }
}
