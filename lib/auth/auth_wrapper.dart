import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login_page.dart';
import '../widgets/admin_navigation_wrapper.dart';
import '../widgets/bottom_navigation_wrapper.dart';
import '../models/person_model.dart';
import '../services/dashboard_initialization_service.dart';

/// Enhanced AuthWrapper with comprehensive error handling and fallback mechanisms
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _retryInProgress = false;

  @override
  Widget build(BuildContext context) {
    // If there's a critical error, show error screen
    if (_hasError && !_retryInProgress) {
      return _buildErrorScreen();
    }

    return StreamBuilder<User?>(
      stream: _getAuthStateStream(),
      builder: (context, snapshot) {
        // Handle connection states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen('Vérification de l\'authentification...');
        }

        // Handle stream errors
        if (snapshot.hasError) {
          print('❌ Auth stream error: ${snapshot.error}');
          return _buildAuthErrorScreen(snapshot.error.toString());
        }

        // Handle authenticated user
        if (snapshot.hasData && snapshot.data != null) {
          return _buildAuthenticatedUserWidget(snapshot.data!);
        } 
        
        // Handle unauthenticated user
        return _buildUnauthenticatedWidget();
      },
    );
  }

  /// Get auth state stream with fallback handling
  Stream<User?> _getAuthStateStream() {
    try {
      return AuthService.authStateChanges;
    } catch (e) {
      print('❌ Error getting auth state stream: $e');
      // Return a stream that emits null (unauthenticated state)
      return Stream.value(null);
    }
  }

  /// Build widget for authenticated users with profile loading
  Widget _buildAuthenticatedUserWidget(User user) {
    return FutureBuilder<PersonModel?>(
      future: _loadUserProfileSafely(user),
      builder: (context, profileSnapshot) {
        // Loading profile
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen('Chargement de votre profil...');
        }

        // Profile loading error
        if (profileSnapshot.hasError) {
          print('❌ Profile loading error: ${profileSnapshot.error}');
          return _buildProfileErrorScreen(profileSnapshot.error.toString(), user);
        }

        // Profile loaded successfully
        if (profileSnapshot.hasData && profileSnapshot.data != null) {
          return _buildUserInterface(profileSnapshot.data!);
        }

        // No profile data - might be creating profile
        return _buildProfileCreationScreen(user);
      },
    );
  }

  /// Safely load user profile with timeout and error handling
  Future<PersonModel?> _loadUserProfileSafely(User user) async {
    try {
      // Add timeout to prevent hanging
      return await AuthService.getCurrentUserProfile().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Profile loading timeout - will retry');
          throw TimeoutException('Profile loading timeout', const Duration(seconds: 10));
        },
      );
    } catch (e) {
      print('❌ Error loading user profile: $e');
      
      // For timeout or network errors, try once more
      if (e is TimeoutException || e.toString().contains('network')) {
        try {
          await Future.delayed(const Duration(seconds: 1));
          return await AuthService.getCurrentUserProfile().timeout(
            const Duration(seconds: 5),
          );
        } catch (retryError) {
          print('❌ Retry failed: $retryError');
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  /// Build user interface based on user roles
  Widget _buildUserInterface(PersonModel profile) {
    try {
      // Check for admin/leader roles
      final hasAdminAccess = _checkAdminAccess(profile);
      
      if (hasAdminAccess) {
        // Initialize admin dashboard in background (non-blocking)
        _initializeAdminDashboardAsync();
        return const AdminNavigationWrapper();
      } else {
        return const BottomNavigationWrapper();
      }
    } catch (e) {
      print('❌ Error building user interface: $e');
      // Fallback to basic member interface
      return const BottomNavigationWrapper();
    }
  }

  /// Check if user has admin access
  bool _checkAdminAccess(PersonModel profile) {
    try {
      return profile.roles.any((role) => 
        role.toLowerCase().contains('admin') || 
        role.toLowerCase().contains('leader') ||
        role.toLowerCase().contains('pasteur') ||
        role.toLowerCase().contains('responsable') ||
        role.toLowerCase().contains('dirigeant')
      );
    } catch (e) {
      print('❌ Error checking admin access: $e');
      return false; // Default to member access
    }
  }

  /// Initialize admin dashboard asynchronously
  void _initializeAdminDashboardAsync() async {
    try {
      await DashboardInitializationService.initializeCompleteDashboard();
      print('✅ Admin dashboard initialized');
    } catch (e) {
      print('⚠️ Warning: Could not initialize admin dashboard: $e');
      // Continue anyway - admin interface will work with basic features
    }
  }

  /// Build widget for unauthenticated users
  Widget _buildUnauthenticatedWidget() {
    try {
      return const LoginPage();
    } catch (e) {
      print('❌ Error building login page: $e');
      return _buildFallbackLoginScreen();
    }
  }

  /// Build loading screen with message
  Widget _buildLoadingScreen(String message) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App branding
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.church,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build error screen for authentication errors
  Widget _buildAuthErrorScreen(String error) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange.shade600,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Problème d\'Authentification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Impossible de vérifier votre statut de connexion. Vérifiez votre connexion internet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _retryAuthentication,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _continueOffline,
                        icon: const Icon(Icons.offline_bolt),
                        label: const Text('Mode Hors-ligne'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build error screen for profile loading errors
  Widget _buildProfileErrorScreen(String error, User user) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.person_off,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Erreur de Profil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Impossible de charger votre profil utilisateur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Utilisateur: ${user.email ?? 'Inconnu'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _retryProfileLoading,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build screen for profile creation
  Widget _buildProfileCreationScreen(User user) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: Colors.blue.shade600,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Configuration du Profil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Création de votre profil en cours...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? 'Utilisateur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _signOut(),
                    child: const Text('Retour à la connexion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build main error screen
  Widget _buildErrorScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Erreur d\'Authentification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage.isNotEmpty 
                        ? _errorMessage
                        : 'Une erreur inattendue s\'est produite.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _resetAndRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Redémarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build fallback login screen
  Widget _buildFallbackLoginScreen() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 20),
              const Text(
                'Connexion Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Veuillez vous connecter pour continuer.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retryAuthentication,
                child: const Text('Actualiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retry authentication
  void _retryAuthentication() {
    setState(() {
      _retryInProgress = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    // Wait a bit then refresh
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _retryInProgress = false;
        });
      }
    });
  }

  /// Retry profile loading
  void _retryProfileLoading() {
    setState(() {
      // Trigger rebuild
    });
  }

  /// Continue in offline mode
  void _continueOffline() {
    // For now, show basic interface
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const BottomNavigationWrapper(),
      ),
    );
  }

  /// Sign out user
  void _signOut() async {
    try {
      await AuthService.signOut();
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  /// Reset and retry everything
  void _resetAndRetry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _retryInProgress = false;
    });
  }
}

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}