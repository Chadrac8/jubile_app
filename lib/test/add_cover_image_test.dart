import '../services/home_config_service.dart';

/// Script simple pour ajouter une image de couverture de test
void main() async {
  await testHomeConfigWithCoverImage();
}

Future<void> testHomeConfigWithCoverImage() async {
  print('=== AJOUT IMAGE DE COUVERTURE DE TEST ===');
  
  try {
    // 1. Récupérer la config actuelle
    final currentConfig = await HomeConfigService.getHomeConfig();
    print('Config actuelle - CoverImageUrl: ${currentConfig.coverImageUrl}');
    
    // 2. Ajouter une image de test
    const testImageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1200&q=80';
    
    final updatedConfig = currentConfig.copyWith(
      coverImageUrl: testImageUrl,
      lastUpdated: DateTime.now());
    
    // 3. Sauvegarder
    await HomeConfigService.updateHomeConfig(updatedConfig);
    print('✓ Image de couverture ajoutée: $testImageUrl');
    
    // 4. Vérifier
    final verifiedConfig = await HomeConfigService.getHomeConfig();
    print('✓ Vérification - CoverImageUrl: ${verifiedConfig.coverImageUrl}');
    
    if (verifiedConfig.coverImageUrl != null && verifiedConfig.coverImageUrl!.isNotEmpty) {
      print('✅ SUCCESS: L\'image de couverture est bien configurée !');
    } else {
      print('❌ PROBLEM: L\'image de couverture n\'est toujours pas configurée');
    }
    
  } catch (e) {
    print('❌ ERREUR: $e');
  }
}
