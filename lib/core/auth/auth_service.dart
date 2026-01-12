import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:receipt_ai_scanner/shared/models/user.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Google Sign-In instance
  // Note: If you need to specify a serverClientId explicitly, uncomment and add:
  // serverClientId: '967736229136-6trttcp44a4vhkc9g8st2dpj8430vbcl.apps.googleusercontent.com',
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google OAuth
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // User cancelled sign-in
        return null;
      }
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }
      
      // Authenticate with backend using the ID token
      return await authenticateWithOAuth(
        provider: 'google',
        token: idToken,
        email: account.email,
        oauthId: account.id,
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
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
      
      // Debug: Log the URL being used (remove in production if needed)
      print('🔐 Authenticating with URL: $url');
      print('🔐 Base URL: $baseUrl');
      
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

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

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
        
        print('❌ Auth error: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      print('❌ JSON parse error: $e');
      throw Exception('Invalid response format from server');
    } catch (e) {
      print('❌ Network error: $e');
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
