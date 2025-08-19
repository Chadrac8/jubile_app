

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'theme.dart';
import 'auth/auth_wrapper.dart';
import 'services/auth_listener_service.dart';
import 'services/app_config_firebase_service.dart';
import 'services/workflow_initialization_service.dart';
import 'routes/app_routes.dart';
import 'utils/date_formatter.dart';
import 'config/locale_config.dart';
import 'churchflow_splash.dart';

/// Fonction principale de l'application ChurchFlow
void main() async {
  
  // Initialiser Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la locale française pour les dates
  DateFormatter.initializeFrenchLocale();
  
  // Services d'erreur supprimés pour la production
  
  // Stockage local supprimé avec le module Songs
  
  // Configurer l'interface système
  _setSystemUIOverlayStyle();
  
  bool firebaseReady = false;
  try {
    // Initialiser les services principaux
    await _initializeCoreServices();
    firebaseReady = true;
    // Initialiser les services secondaires de manière asynchrone
    _initializeSecondaryServicesAsync();
  } catch (e) {
    print('Erreur lors de l\'initialisation: $e');
  }

  runApp(ChurchFlowAppWithSplash(firebaseReady: firebaseReady));


}

/// Configurer le style de l'interface système
void _setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Initialiser les services principaux
Future<void> _initializeCoreServices() async {
  try {
    // Initialiser Firebase avec timeout
    await _initializeFirebase().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timeout', const Duration(seconds: 10));
      },
    );
    
    // Initialiser le service d'écoute d'authentification
    try {
      AuthListenerService.initialize();
    } catch (e) {
      print('Avertissement: Échec de l\'initialisation du service d\'authentification: $e');
    }
    
  } catch (e) {
    print('Erreur d\'initialisation des services principaux: $e');
  }
}

/// Initialiser Firebase
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Erreur d\'initialisation Firebase: $e');
    
    if (e.toString().contains('not been configured')) {
      print('Firebase non configuré pour cette plateforme');
      return;
    }
    
    print('Continuation sans les services Firebase');
  }
}

/// Initialiser les services secondaires de manière asynchrone
void _initializeSecondaryServicesAsync() {
  // Synchronisation des favoris supprimée avec le module Songs
  
  // Initialiser la configuration de l'application
  _initializeAppConfigAsync();
  
  // Initialiser les workflows
  _initializeWorkflowsAsync();
}

/// Initialiser la configuration de l'application de manière asynchrone
void _initializeAppConfigAsync() async {
  try {
    await AppConfigFirebaseService.initializeDefaultConfig().timeout(
      const Duration(seconds: 15),
    );
  } catch (e) {
    print('Avertissement: Impossible d\'initialiser la configuration de l\'application: $e');
  }
}

/// Initialiser les workflows de manière asynchrone
void _initializeWorkflowsAsync() async {
  try {
    await WorkflowInitializationService.ensureWorkflowsExist().timeout(
      const Duration(seconds: 15),
    );
  } catch (e) {
    print('Avertissement: Impossible d\'initialiser les workflows: $e');
  }
}

/// Exception personnalisée pour les timeouts
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}

/// Widget principal de l'application
class ChurchFlowApp extends StatefulWidget {
  const ChurchFlowApp({super.key});

  @override
  State<ChurchFlowApp> createState() => _ChurchFlowAppState();
}

class _ChurchFlowAppState extends State<ChurchFlowApp> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupErrorWidgetBuilder();
  }

  /// Configurer le constructeur de widgets d'erreur
  void _setupErrorWidgetBuilder() {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
      
      return _buildErrorWidget();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChurchFlow - Gestion d\'Église',
      theme: AppTheme.lightTheme,
      home: _hasError ? _buildErrorScreen() : const SafeAuthWrapper(),
      debugShowCheckedModeBanner: false,
      
      // Configuration de localisation française
      locale: LocaleConfig.defaultLocale,
      localizationsDelegates: LocaleConfig.localizationsDelegates,
      supportedLocales: LocaleConfig.supportedLocales,
      
      // Configuration du routage
      initialRoute: '/',
      
      // Gestionnaire global d'erreurs
      builder: (context, child) {
        if (child == null) {
          return _buildErrorWidget();
        }
        
        return child;
      },
    );
  }

  /// Construire l'écran d'erreur pour les erreurs critiques de l'application
  Widget _buildErrorScreen() {
    return Scaffold(
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
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Erreur de l\'Application',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Une erreur inattendue s\'est produite. Veuillez redémarrer l\'application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Redémarrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construire un widget d'erreur simple
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.red.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur d\'affichage',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper d'authentification sécurisé
class SafeAuthWrapper extends StatelessWidget {
  const SafeAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return const AuthWrapper();
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'authentification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Impossible de charger le système d\'authentification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}