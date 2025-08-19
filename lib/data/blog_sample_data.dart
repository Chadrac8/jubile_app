import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';

class BlogSampleData {
  /// Créer des données d'exemple pour le blog
  static Future<void> createSampleBlogData() async {
    try {
      print('🔄 Création des données d\'exemple pour le blog...');

      // Créer des catégories
      final now = DateTime.now();
      final categories = [
        BlogCategory(
          id: 'announcements',
          name: 'Annonces',
          description: 'Actualités et annonces de l\'église',
          color: '#2196F3',
          createdAt: now,
          updatedAt: now,
        ),
        BlogCategory(
          id: 'teachings',
          name: 'Enseignements',
          description: 'Prédications et enseignements bibliques',
          color: '#4CAF50',
          createdAt: now,
          updatedAt: now,
        ),
        BlogCategory(
          id: 'events',
          name: 'Événements',
          description: 'Événements et activités de l\'église',
          color: '#FF9800',
          createdAt: now,
          updatedAt: now,
        ),
        BlogCategory(
          id: 'testimonies',
          name: 'Témoignages',
          description: 'Témoignages et histoires de foi',
          color: '#9C27B0',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Créer les catégories
      for (final category in categories) {
        await BlogFirebaseService.createCategory(category);
      }

      // Créer des articles d'exemple
      final posts = [
        BlogPost(
          id: '',
          title: 'Bienvenue sur notre nouveau blog !',
          excerpt: 'Nous sommes ravis de vous présenter notre nouveau blog où nous partagerons des actualités, enseignements et témoignages.',
          content: '''
# Bienvenue sur notre nouveau blog !

Nous sommes ravis de vous présenter notre nouveau blog ! Cet espace sera votre source d'information pour :

## 📢 Les actualités de l'église
- Annonces importantes
- Nouveaux programmes
- Changements d'horaires

## 📖 Les enseignements
- Résumés de prédications
- Études bibliques
- Réflexions spirituelles

## 🎉 Les événements
- Activités à venir
- Comptes-rendus d'événements
- Photos et souvenirs

## 💬 Les témoignages
- Histoires de foi
- Expériences personnelles
- Encouragements

N'hésitez pas à commenter et partager vos réflexions !

*Que Dieu vous bénisse !*
          ''',
          categories: ['announcements'],
          tags: ['blog', 'nouveau', 'bienvenue'],
          status: BlogPostStatus.published,
          authorId: 'system',
          authorName: 'Équipe Église',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          views: 25,
          likes: 8,
          commentsCount: 3,
          featuredImageUrl: null,
          isFeatured: true,
          allowComments: true,
          seoData: {
            'title': 'Bienvenue sur notre nouveau blog - Église',
            'description': 'Découvrez notre nouveau blog avec des actualités, enseignements et témoignages de notre communauté.',
            'keywords': ['blog', 'église', 'actualités', 'enseignements'],
          },
        ),
        
        BlogPost(
          id: '',
          title: 'La puissance de la prière communautaire',
          excerpt: 'Découvrez comment la prière en communauté peut transformer notre foi et renforcer nos liens fraternels.',
          content: '''
# La puissance de la prière communautaire

La prière est au cœur de notre foi, mais avez-vous déjà expérimenté la puissance de la prière communautaire ?

## 🙏 Pourquoi prier ensemble ?

> "Car là où deux ou trois sont assemblés en mon nom, je suis au milieu d'eux." - Matthieu 18:20

La prière communautaire a plusieurs avantages :

### 1. L'unité dans la foi
Prier ensemble nous unit dans un même esprit et une même vision.

### 2. Le soutien mutuel
Nous portons les fardeaux les uns des autres.

### 3. La force collective
Nos prières se renforcent mutuellement.

## 📅 Nos temps de prière

- **Mardi 19h** : Soirée de prière
- **Vendredi 6h** : Prière matinale
- **Dimanche avant le culte** : Prière d'intercession

Rejoignez-nous pour ces moments privilégiés !

*"L'Éternel est près de tous ceux qui l'invoquent." - Psaume 145:18*
          ''',
          categories: ['teachings'],
          tags: ['prière', 'communauté', 'foi'],
          status: BlogPostStatus.published,
          authorId: 'pastor',
          authorName: 'Pasteur Martin',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          views: 42,
          likes: 15,
          commentsCount: 7,
          featuredImageUrl: null,
          isFeatured: false,
          allowComments: true,
          seoData: {
            'title': 'La puissance de la prière communautaire',
            'description': 'Découvrez l\'importance et les bienfaits de la prière en communauté pour fortifier notre foi.',
            'keywords': ['prière', 'communauté', 'foi', 'église'],
          },
        ),

        BlogPost(
          id: '',
          title: 'Journée portes ouvertes : un grand succès !',
          excerpt: 'Retour sur notre journée portes ouvertes qui a permis d\'accueillir de nombreuses nouvelles familles.',
          content: '''
# Journée portes ouvertes : un grand succès !

Samedi dernier, notre église a ouvert ses portes à la communauté locale, et quelle belle journée nous avons vécue !

## 📊 Les chiffres

- **150 visiteurs** ont franchi nos portes
- **23 nouvelles familles** ont découvert notre communauté  
- **45 enfants** ont participé aux activités jeunesse
- **12 personnes** ont exprimé le désir d'en savoir plus

## 🎯 Les activités proposées

### Pour les adultes
- Visite guidée de l'église
- Présentation de nos ministères
- Café et pâtisseries
- Témoignages de membres

### Pour les enfants
- Atelier bricolage
- Jeux et animations
- Spectacle de marionnettes
- Goûter spécial

## 💫 Témoignages

*"Nous cherchions une église accueillante pour notre famille. Nous l'avons trouvée !"* - Famille Dubois

*"L'ambiance chaleureuse nous a tout de suite conquis."* - Marie L.

## 📞 Pour les nouveaux intéressés

Si vous avez manqué cette journée, pas de panique ! Nous organisons chaque dimanche un accueil spécial pour les nouveaux visiteurs à 9h45.

**Merci à tous les bénévoles** qui ont rendu cette journée possible ! 🙏

*Prochaine journée portes ouvertes : Printemps 2024*
          ''',
          categories: ['events', 'announcements'],
          tags: ['portes ouvertes', 'communauté', 'accueil', 'nouveaux'],
          status: BlogPostStatus.published,
          authorId: 'communication',
          authorName: 'Équipe Communication',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          views: 38,
          likes: 22,
          commentsCount: 11,
          featuredImageUrl: null,
          isFeatured: true,
          allowComments: true,
          seoData: {
            'title': 'Journée portes ouvertes : un grand succès !',
            'description': 'Retour sur notre journée portes ouvertes qui a accueilli 150 visiteurs et 23 nouvelles familles.',
            'keywords': ['portes ouvertes', 'événement', 'communauté', 'église'],
          },
        ),
      ];

      // Créer les articles
      for (final post in posts) {
        await BlogFirebaseService.createPost(post);
      }

      print('✅ Données d\'exemple créées avec succès !');
      print('📝 ${posts.length} articles créés');
      print('📂 ${categories.length} catégories créées');

    } catch (e) {
      print('❌ Erreur lors de la création des données d\'exemple: $e');
      rethrow;
    }
  }

  /// Supprimer toutes les données d'exemple
  static Future<void> clearSampleData() async {
    try {
      print('🧹 Suppression des données d\'exemple...');
      // Note: Implementer la logique de suppression si nécessaire
      print('✅ Données d\'exemple supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }
}