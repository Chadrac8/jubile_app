import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import '../../shared/widgets/custom_card.dart';
import 'views/songs_member_view.dart';
import 'views/songs_admin_view.dart';
import 'views/song_detail_view.dart';
import 'views/song_form_view.dart';
import 'services/songs_service.dart';

/// Module de gestion des chants
class SongsModule extends BaseModule {
  static const String moduleId = 'songs';
  
  late final SongsService _songsService;

  SongsModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Recueil des Chants',
          description: 'Gestion complète du recueil de chants avec recherche avancée, catégories, favoris et playlists',
          icon: 'library_music',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member],
          memberRoute: '/member/songs',
          adminRoute: '/admin/songs',
          customConfig: {
            'features': [
              'Recherche avancée',
              'Catégories et tags',
              'Favoris personnels',
              'Playlists',
              'Partitions et médias',
              'Statistiques d\'usage',
              'Système d\'approbation',
              'Interface responsive',
            ],
            'permissions': {
              'member': ['view', 'search', 'favorite', 'playlist'],
              'admin': ['create', 'edit', 'delete', 'approve', 'manage_categories'],
            },
          },
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/songs': (context) => const SongsMemberView(),
    '/admin/songs': (context) => const SongsAdminView(),
    '/song/detail': (context) {
      final song = ModalRoute.of(context)?.settings.arguments;
      if (song != null) {
        return SongDetailView(song: song as dynamic);
      }
      return const Scaffold(
        body: Center(child: Text('Erreur: Chant non spécifié')),
      );
    },
    '/song/form': (context) => const SongFormView(),
    '/song/edit': (context) {
      final song = ModalRoute.of(context)?.settings.arguments;
      if (song != null) {
        return SongFormView(song: song as dynamic);
      }
      return const SongFormView();
    },
  };

  @override
  Future<void> initialize() async {
    await super.initialize();
    _songsService = SongsService();
    await _songsService.initialize();
    print('✅ Module Songs initialisé avec succès');
    print('   - Modèles: Song, SongCategory, SongPlaylist');
    print('   - Services: SongsService, SongCategoriesService, SongPlaylistsService');
    print('   - Vues: 4 vues complètes (Member, Admin, Detail, Form)');
    print('   - Fonctionnalités: Recherche, Catégories, Favoris, Statistiques');
  }

  @override
  Future<void> dispose() async {
    await _songsService.dispose();
    await super.dispose();
    print('Module Songs libéré');
  }

  @override
  Widget buildModuleCard(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/member/songs'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Fonctionnalités principales
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildFeatureChip('Recherche avancée', Icons.search),
                  _buildFeatureChip('Catégories', Icons.category),
                  _buildFeatureChip('Favoris', Icons.favorite),
                  _buildFeatureChip('Playlists', Icons.playlist_play),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Statistiques (sera mis à jour dynamiquement)
              FutureBuilder<Map<String, int>>(
                future: _songsService.getStatistics(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    return Row(
                      children: [
                        _buildStatChip('${stats['total'] ?? 0} chants', Icons.library_music),
                        const SizedBox(width: 8),
                        _buildStatChip('${stats['approved'] ?? 0} approuvés', Icons.check_circle),
                        if ((stats['pending'] ?? 0) > 0) ...[
                          const SizedBox(width: 8),
                          _buildStatChip('${stats['pending']} en attente', Icons.pending),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      _buildStatChip('Chargement...', Icons.hourglass_empty),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir les statistiques du module
  Future<Map<String, dynamic>> getModuleStatistics() async {
    try {
      final stats = await _songsService.getStatistics();
      final categories = await _songsService.categories.getActiveCategories();
      
      return {
        'total_songs': stats['total'] ?? 0,
        'approved_songs': stats['approved'] ?? 0,
        'pending_songs': stats['pending'] ?? 0,
        'categories_count': categories.length,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Vérifier l'intégrité du module
  Future<bool> verifyModuleIntegrity() async {
    try {
      // Vérifier que le service est initialisé
      if (_songsService == null) return false;
      
      // Vérifier les catégories par défaut
      final categories = await _songsService.categories.getActiveCategories();
      if (categories.isEmpty) {
        print('⚠️  Aucune catégorie trouvée, réinitialisation...');
        await _songsService.categories.initialize();
      }
      
      print('✅ Module Songs: Intégrité vérifiée');
      return true;
    } catch (e) {
      print('❌ Module Songs: Erreur d\'intégrité - $e');
      return false;
    }
  }
}