import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import '../../shared/widgets/custom_card.dart';
import 'models/blog_post.dart';
import 'views/blog_member_view.dart';
import 'views/blog_admin_view.dart';
import 'views/blog_detail_view.dart';
import 'views/blog_form_view.dart';
import 'services/blog_service.dart';

/// Module de gestion du blog
class BlogModule extends BaseModule {
  static const String moduleId = 'blog';
  
  late final BlogService _blogService;

  BlogModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Blog',
          description: 'Articles et actualités de l\'église',
          icon: 'article',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member, ModulePermission.public],
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/blog': (context) => const BlogMemberView(),
    '/admin/blog': (context) => const BlogAdminView(),
    '/blog/detail': (context) => BlogDetailView(
      post: ModalRoute.of(context)?.settings.arguments as BlogPost?,
    ),
    '/blog/form': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BlogPost) {
        return BlogFormView(post: args, isEdit: true);
      }
      return const BlogFormView();
    },
    '/blog/edit': (context) => BlogFormView(
      post: ModalRoute.of(context)?.settings.arguments as BlogPost?,
      isEdit: true,
    ),
  };

  @override
  Future<void> initialize() async {
    _blogService = BlogService();
    print('✅ Module Blog initialisé');
  }

  @override
  Widget buildModuleCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getQuickStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
        return CustomCard(
          child: InkWell(
            onTap: () => _navigateToModule(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            Text(
                              config.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Statistiques rapides
                  if (snapshot.hasData) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Articles', stats['published'] ?? 0),
                        _buildStatItem('Brouillons', stats['drafts'] ?? 0),
                        _buildStatItem('Commentaires', stats['pendingComments'] ?? 0),
                        _buildStatItem('Cette semaine', stats['thisWeek'] ?? 0),
                      ],
                    ),
                  ] else
                    const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToMemberView(context),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Voir'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToAdminView(context),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Gérer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getQuickStats() async {
    try {
      return await _blogService.getBlogStatistics();
    } catch (e) {
      print('Erreur lors du chargement des statistiques du blog: $e');
      return {};
    }
  }

  void _navigateToModule(BuildContext context) {
    // Navigation par défaut vers la vue membre
    _navigateToMemberView(context);
  }

  void _navigateToMemberView(BuildContext context) {
    Navigator.of(context).pushNamed('/member/blog');
  }

  void _navigateToAdminView(BuildContext context) {
    Navigator.of(context).pushNamed('/admin/blog');
  }

  @override
  List<Widget> getMemberMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.article),
        title: const Text('Blog'),
        subtitle: const Text('Articles et actualités'),
        onTap: () => _navigateToMemberView(context),
      ),
    ];
  }

  @override
  List<Widget> getAdminMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.article),
        title: const Text('Blog'),
        subtitle: const Text('Gérer les articles'),
        trailing: FutureBuilder<int>(
          future: getNotificationCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return count > 0 ? Badge(label: Text(count.toString())) : const SizedBox.shrink();
          },
        ),
        onTap: () => _navigateToAdminView(context),
      ),
    ];
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques du Blog'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _getQuickStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return const Text('Erreur lors du chargement des statistiques');
            }
            
            final stats = snapshot.data ?? {};
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatsRow('Total des articles', stats['total'] ?? 0),
                _buildStatsRow('Articles publiés', stats['published'] ?? 0),
                _buildStatsRow('Brouillons', stats['drafts'] ?? 0),
                _buildStatsRow('Articles programmés', stats['scheduled'] ?? 0),
                _buildStatsRow('Total des commentaires', stats['totalComments'] ?? 0),
                _buildStatsRow('Commentaires en attente', stats['pendingComments'] ?? 0),
                _buildStatsRow('Articles cette semaine', stats['thisWeek'] ?? 0),
                _buildStatsRow('Catégories', stats['categories'] ?? 0),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAdminView(context);
            },
            child: const Text('Voir détails'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<int> getNotificationCount() async {
    try {
      final stats = await _getQuickStats();
      return stats['pendingComments'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Méthodes utilitaires pour les autres modules
  
  /// Obtenir les articles récents pour d'autres modules
  Future<List<BlogPost>> getRecentPostsForWidget({int limit = 5}) async {
    try {
      return await _blogService.getRecentPosts(limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Obtenir les articles en vedette pour d'autres modules
  Future<List<BlogPost>> getFeaturedPostsForWidget({int limit = 3}) async {
    try {
      return await _blogService.getFeaturedPosts(limit: limit);
    } catch (e) {
      return [];
    }
  }
}