import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/home_config_service.dart';
import '../models/home_config_model.dart';

/// Script de test pour vérifier et configurer l'image de couverture
class TestHomeConfigScript {
  static Future<void> run() async {
    print('=== TEST HOME CONFIG ===');
    
    try {
      // 1. Récupérer la configuration actuelle
      final currentConfig = await HomeConfigService.getHomeConfig();
      print('Configuration actuelle:');
      print('- ID: ${currentConfig.id}');
      print('- CoverImageUrl: ${currentConfig.coverImageUrl}');
      print('- VersetDuJour: ${currentConfig.versetDuJour}');
      print('- SermonTitle: ${currentConfig.sermonTitle}');
      print('- SermonYouTubeUrl: ${currentConfig.sermonYouTubeUrl}');
      
      // 2. Si aucune image de couverture, en ajouter une de test
      if (currentConfig.coverImageUrl == null || currentConfig.coverImageUrl!.isEmpty) {
        print('\nAucune image de couverture trouvée. Ajout d\'une image de test...');
        
        // URL d'une image de test (remplacez par une vraie URL d'image)
        const testImageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200&h=600&fit=crop';
        
        final updatedConfig = currentConfig.copyWith(
          coverImageUrl: testImageUrl,
          lastUpdated: DateTime.now());
        
        await HomeConfigService.updateHomeConfig(updatedConfig);
        print('Image de couverture ajoutée: $testImageUrl');
        
        // Vérifier la mise à jour
        final verifyConfig = await HomeConfigService.getHomeConfig();
        print('Vérification - CoverImageUrl: ${verifyConfig.coverImageUrl}');
      } else {
        print('\nImage de couverture existante: ${currentConfig.coverImageUrl}');
      }
      
    } catch (e) {
      print('Erreur lors du test: $e');
    }
    
    print('=== FIN TEST ===');
  }
  
  /// Tester avec différentes URLs d'images
  static Future<void> testWithDifferentImages() async {
    final testImages = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200&h=600&fit=crop', // Église
      'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?w=1200&h=600&fit=crop', // Nature spirituelle
      'https://images.unsplash.com/photo-1520637836862-4d197d17c68a?w=1200&h=600&fit=crop', // Croix
    ];
    
    print('=== TEST AVEC DIFFÉRENTES IMAGES ===');
    
    for (int i = 0; i < testImages.length; i++) {
      print('\nTest image ${i + 1}: ${testImages[i]}');
      
      try {
        final currentConfig = await HomeConfigService.getHomeConfig();
        final updatedConfig = currentConfig.copyWith(
          coverImageUrl: testImages[i],
          lastUpdated: DateTime.now());
        
        await HomeConfigService.updateHomeConfig(updatedConfig);
        print('✓ Image ${i + 1} mise à jour avec succès');
        
        // Attendre un peu avant le test suivant
        await Future.delayed(const Duration(seconds: 2));
        
      } catch (e) {
        print('✗ Erreur avec l\'image ${i + 1}: $e');
      }
    }
  }
  
  /// Réinitialiser la configuration pour les tests
  static Future<void> resetConfig() async {
    print('=== RÉINITIALISATION CONFIG ===');
    
    try {
      final defaultConfig = HomeConfigModel(
        id: 'main',
        coverImageUrl: null, // Pas d'image par défaut
        versetDuJour: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
        versetReference: 'Jean 3:16',
        sermonTitle: 'Dernier sermon',
        lastUpdated: DateTime.now());
      
      await HomeConfigService.updateHomeConfig(defaultConfig);
      print('Configuration réinitialisée');
      
    } catch (e) {
      print('Erreur lors de la réinitialisation: $e');
    }
  }
}

/// Widget de test pour l'interface
class TestHomeConfigWidget extends StatefulWidget {
  const TestHomeConfigWidget({super.key});

  @override
  State<TestHomeConfigWidget> createState() => _TestHomeConfigWidgetState();
}

class _TestHomeConfigWidgetState extends State<TestHomeConfigWidget> {
  String _status = 'Prêt pour les tests';
  bool _isLoading = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Test en cours...';
    });

    try {
      await TestHomeConfigScript.run();
      setState(() {
        _status = 'Test terminé avec succès';
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testImages() async {
    setState(() {
      _isLoading = true;
      _status = 'Test des images en cours...';
    });

    try {
      await TestHomeConfigScript.testWithDifferentImages();
      setState(() {
        _status = 'Test des images terminé';
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur test images: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetConfig() async {
    setState(() {
      _isLoading = true;
      _status = 'Réinitialisation...';
    });

    try {
      await TestHomeConfigScript.resetConfig();
      setState(() {
        _status = 'Configuration réinitialisée';
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur réinitialisation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Home Config'),
        backgroundColor: Colors.blue,
        foregroundColor: AppTheme.surfaceColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.info,
                      size: 48,
                      color: _isLoading ? AppTheme.warningColor : Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'Statut',
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center),
                  ]))),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tester la configuration'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16))),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testImages,
              icon: const Icon(Icons.image),
              label: const Text('Tester différentes images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16))),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _resetConfig,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser la config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16))),
            
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator()),
            ],
          ])));
  }
}
