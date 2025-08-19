import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/thematic_passage_service.dart';

class ThematicPassagesInitializer extends StatefulWidget {
  final Widget child;
  
  const ThematicPassagesInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ThematicPassagesInitializer> createState() => _ThematicPassagesInitializerState();
}

class _ThematicPassagesInitializerState extends State<ThematicPassagesInitializer> {
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndInitializeThemes();
  }

  Future<void> _checkAndInitializeThemes() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await ThematicPassageService.initializeDefaultThemes();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    // Retourner l'enfant seulement si l'initialisation est terminée
    if (_isInitialized) {
      return widget.child;
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
              child: Icon(
                Icons.collections_bookmark,
                size: 48,
                color: theme.colorScheme.primary)),
            const SizedBox(height: 24),
            Text(
              'Initialisation des passages thématiques',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Préparation des thèmes bibliques par défaut...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
          ])));
  }

  Widget _buildErrorScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Erreur d\'initialisation',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Impossible d\'initialiser les passages thématiques.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.error),
                textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isInitialized = true;
                      });
                    },
                    child: Text(
                      'Continuer sans initialisation',
                      style: GoogleFonts.inter())),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _checkAndInitializeThemes,
                    child: Text(
                      'Réessayer',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                ]),
            ]))));
  }
}
