import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:receipt_ai_scanner/shared/models/user.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Web Client ID - same for both web and mobile
  static const String _webClientId = '967736229136-jccfe2msg2trmhb65mmp3h156ofiqb8m.apps.googleusercontent.com';

  // Google Sign-In instance (singleton, initialized once based on platform)
  // IMPORTANT:
  // - Web: use clientId
  // - Mobile: use serverClientId
  late final GoogleSignIn _googleSignIn = _createGoogleSignIn();

  GoogleSignIn _createGoogleSignIn() {
    if (kIsWeb) {
      // WEB: serverClientId is not supported on web.
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: _webClientId,
      );
    } else {
      // MOBILE: use serverClientId for backend-verified ID tokens.
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: _webClientId,
      );
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  bool _isGoogleSignInCancelled(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('popup_closed') ||
        msg.contains('sign_in_canceled') ||
        msg.contains('cancelled') ||
        msg.contains('canceled');
  }

  String _googleConfigHint() {
    if (!kIsWeb) {
      return 'Revisa el client ID de Google para Android y el SHA-1/SHA-256.';
    }
    return 'Revisa Google Cloud OAuth Web Client: Orígenes JS autorizados y URIs de redireccionamiento para ${Uri.base.origin}.';
  }

  /// Sign in with Google OAuth
  Future<User?> signInWithGoogle() async {
    try {
      // Ensure a clean session before starting a new OAuth popup.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // User cancelled sign-in
        return null;
      }
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      _logDebug('Google sign-in email: ${account.email}');
      _logDebug('ID token length: ${idToken?.length ?? 0}');
      _logDebug('Access token length: ${accessToken?.length ?? 0}');

      // Web fallback: idToken may be null, use accessToken.
      final String? oauthToken = (idToken != null && idToken.isNotEmpty) ? idToken : accessToken;
      if (oauthToken == null || oauthToken.isEmpty) {
        throw Exception('No se pudo obtener token de Google. ${_googleConfigHint()}');
      }

      if (oauthToken == 'mock-token') {
        throw Exception('Invalid Google token received. Please check OAuth configuration.');
      }
      
      // Authenticate with backend using ID token (mobile) or access token (web).
      return await authenticateWithOAuth(
        provider: 'google',
        token: oauthToken,
        email: account.email,
        oauthId: account.id,
      );
    } catch (e) {
      if (_isGoogleSignInCancelled(e)) {
        return null;
      }

      final msg = e.toString();
      if (msg.contains('redirect_uri_mismatch') ||
          msg.contains('unauthorized') ||
          msg.contains('invalid_request')) {
        throw Exception('Google OAuth no autorizado. ${_googleConfigHint()}');
      }

      throw Exception('Google Sign-In failed: $msg');
    }
  }

  /// Sign in with Apple OAuth
  Future<User?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }
      
      // Apple may not provide email in credential (privacy feature)
      // If email is not provided, we'll need to handle it in the backend
      final String email = credential.email ?? '';
      final String? oauthIdNullable = credential.userIdentifier;
      
      if (oauthIdNullable == null || oauthIdNullable.isEmpty) {
        throw Exception('Failed to get Apple user identifier');
      }
      
      final String oauthId = oauthIdNullable;
      
      return await authenticateWithOAuth(
        provider: 'apple',
        token: idToken,
        email: email,
        oauthId: oauthId,
      );
    } catch (e) {
      // Handle user cancellation gracefully
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        return null;
      }
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  Future<User?> authenticateWithOAuth({
    required String provider,
    required String token,
    required String email,
    required String oauthId,
  }) async {
    try {
      // Ensure URL is properly formatted
      final baseUrl = AppConstants.apiBaseUrl.trim();
      final url = baseUrl.endsWith('/') 
          ? '${baseUrl}api/auth/oauth'
          : '$baseUrl/api/auth/oauth';
      
      _logDebug('Authenticating with URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'token': token,
          'email': email,
          'oauthId': oauthId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - El servidor no respondió a tiempo');
        },
      );

      _logDebug('OAuth response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final authToken = data['token'] as String;

        // Save token and user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, authToken);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));

        return user;
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final errorMessage = errorBody?['message'] as String? ??
            errorBody?['error'] as String? ??
            'Authentication failed: ${response.statusCode}';
        
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      _logDebug('JSON parse error: $e');
      throw Exception('Invalid response format from server');
    } catch (e) {
      _logDebug('Network error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
