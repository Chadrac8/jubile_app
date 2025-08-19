import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_service.dart';

class AuthListenerService {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  /// Initialize auth state listener
  static void initialize() {
    if (_isInitialized) return;
    
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User signed in - ensure profile exists
        try {
          await UserProfileService.ensureUserProfile(user);
          print('✅ Profile ensured for user: ${user.email}');
        } catch (e) {
          print('❌ Error ensuring user profile: $e');
        }
      } else {
        // User signed out
        print('🔐 User signed out');
      }
    });
    
    _isInitialized = true;
    print('🎯 Auth listener service initialized');
  }
}