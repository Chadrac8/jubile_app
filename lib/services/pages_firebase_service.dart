import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/page_model.dart';
import '../models/person_model.dart';

class PagesFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String pagesCollection = 'custom_pages';
  static const String pageTemplatesCollection = 'page_templates';
  static const String pageViewsCollection = 'page_views';
  static const String pageActivityLogsCollection = 'page_activity_logs';

  // Page CRUD Operations
  static Future<String> createPage(CustomPageModel page) async {
    try {
      final docRef = await _firestore.collection(pagesCollection).add({
        ...page.toFirestore(),
        'createdBy': _auth.currentUser?.uid,
        'lastModifiedBy': _auth.currentUser?.uid,
      });

      await _logPageActivity(docRef.id, 'page_created', {
        'title': page.title,
        'slug': page.slug,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la page: $e');
    }
  }

  static Future<void> updatePage(CustomPageModel page) async {
    try {
      await _firestore.collection(pagesCollection).doc(page.id).update({
        ...page.toFirestore(),
        'lastModifiedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logPageActivity(page.id, 'page_updated', {
        'title': page.title,
        'status': page.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la page: $e');
    }
  }

  // Get all pages (pour la synchronisation avec la configuration)
  static Future<List<CustomPageModel>> getAllPages() async {
    try {
      final snapshot = await _firestore
          .collection(pagesCollection)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => CustomPageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des pages: $e');
    }
  }

  static Future<void> deletePage(String pageId) async {
    try {
      final batch = _firestore.batch();

      // Supprimer la page
      batch.delete(_firestore.collection(pagesCollection).doc(pageId));

      // Supprimer les statistiques de vues
      final viewsQuery = await _firestore
          .collection(pageViewsCollection)
          .where('pageId', isEqualTo: pageId)
          .get();

      for (final doc in viewsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await _logPageActivity(pageId, 'page_deleted', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la page: $e');
    }
  }

  static Future<CustomPageModel?> getPage(String pageId) async {
    try {
      final doc = await _firestore.collection(pagesCollection).doc(pageId).get();
      if (doc.exists) {
        return CustomPageModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la page: $e');
    }
  }

  static Future<CustomPageModel?> getPageBySlug(String slug) async {
    try {
      final query = await _firestore
          .collection(pagesCollection)
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return CustomPageModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la page: $e');
    }
  }

  static Stream<List<CustomPageModel>> getPagesStream({
    String? searchQuery,
    String? statusFilter,
    String? visibilityFilter,
    String? createdBy,
    int limit = 50,
  }) {
    try {
      return _getPagesStreamWithFallback(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        visibilityFilter: visibilityFilter,
        createdBy: createdBy,
        limit: limit,
      );
    } catch (e) {
      // Fallback en cas d'erreur d'index
      return _getPagesStreamSimple(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        visibilityFilter: visibilityFilter,
        createdBy: createdBy,
        limit: limit,
      );
    }
  }

  // Méthode optimisée avec index composites
  static Stream<List<CustomPageModel>> _getPagesStreamWithFallback({
    String? searchQuery,
    String? statusFilter,
    String? visibilityFilter,
    String? createdBy,
    int limit = 50,
  }) {
    Query query = _firestore.collection(pagesCollection);

    // Gestion des combinaisons de filtres avec index optimisés
    bool hasStatusFilter = statusFilter != null && statusFilter.isNotEmpty;
    bool hasVisibilityFilter = visibilityFilter != null && visibilityFilter.isNotEmpty;
    bool hasCreatedByFilter = createdBy != null && createdBy.isNotEmpty;

    if (hasStatusFilter && hasVisibilityFilter && hasCreatedByFilter) {
      // Utiliser l'index composite complexe: status + visibility + createdBy + updatedAt
      query = query
          .where('status', isEqualTo: statusFilter)
          .where('visibility', isEqualTo: visibilityFilter)
          .where('createdBy', isEqualTo: createdBy)
          .orderBy('updatedAt', descending: true);
    } else if (hasStatusFilter && hasVisibilityFilter) {
      // Utiliser index pour status + visibility
      query = query
          .where('status', isEqualTo: statusFilter)
          .where('visibility', isEqualTo: visibilityFilter)
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true);
    } else if (hasStatusFilter && hasCreatedByFilter) {
      // Utiliser index pour status + createdBy
      query = query
          .where('status', isEqualTo: statusFilter)
          .where('createdBy', isEqualTo: createdBy)
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true);
    } else if (hasVisibilityFilter && hasCreatedByFilter) {
      // Utiliser index pour visibility + createdBy
      query = query
          .where('visibility', isEqualTo: visibilityFilter)
          .where('createdBy', isEqualTo: createdBy)
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true);
    } else if (hasStatusFilter) {
      query = query.where('status', isEqualTo: statusFilter);
      query = query.orderBy('displayOrder').orderBy('createdAt', descending: true);
    } else if (hasVisibilityFilter) {
      query = query.where('visibility', isEqualTo: visibilityFilter);
      query = query.orderBy('displayOrder').orderBy('createdAt', descending: true);
    } else if (hasCreatedByFilter) {
      query = query.where('createdBy', isEqualTo: createdBy);
      query = query.orderBy('displayOrder').orderBy('createdAt', descending: true);
    } else {
      // Utiliser l'index simple pour éviter les erreurs
      query = query.orderBy('displayOrder').orderBy('createdAt', descending: true);
    }

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      List<CustomPageModel> pages = snapshot.docs
          .map((doc) => CustomPageModel.fromFirestore(doc))
          .toList();

      // Filtrage côté client pour la recherche textuelle
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        pages = pages.where((page) =>
            page.title.toLowerCase().contains(lowercaseQuery) ||
            page.description.toLowerCase().contains(lowercaseQuery) ||
            page.slug.toLowerCase().contains(lowercaseQuery)
        ).toList();
      }

      return pages;
    });
  }

  // Méthode de fallback plus simple
  static Stream<List<CustomPageModel>> _getPagesStreamSimple({
    String? searchQuery,
    String? statusFilter,
    String? visibilityFilter,
    String? createdBy,
    int limit = 50,
  }) {
    Query query = _firestore.collection(pagesCollection);

    // Utiliser un seul orderBy pour éviter les erreurs d'index
    query = query.orderBy('displayOrder');

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      List<CustomPageModel> pages = snapshot.docs
          .map((doc) => CustomPageModel.fromFirestore(doc))
          .toList();

      // Filtrage côté client pour tous les critères
      if (statusFilter != null && statusFilter.isNotEmpty) {
        pages = pages.where((page) => page.status == statusFilter).toList();
      }

      if (visibilityFilter != null && visibilityFilter.isNotEmpty) {
        pages = pages.where((page) => page.visibility == visibilityFilter).toList();
      }

      if (createdBy != null && createdBy.isNotEmpty) {
        pages = pages.where((page) => page.createdBy == createdBy).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        pages = pages.where((page) =>
            page.title.toLowerCase().contains(lowercaseQuery) ||
            page.description.toLowerCase().contains(lowercaseQuery) ||
            page.slug.toLowerCase().contains(lowercaseQuery)
        ).toList();
      }

      // Tri côté client
      pages.sort((a, b) {
        int displayOrderCompare = a.displayOrder.compareTo(b.displayOrder);
        if (displayOrderCompare != 0) return displayOrderCompare;
        return b.createdAt.compareTo(a.createdAt); // Descending
      });

      return pages;
    });
  }

  // Pages publiques pour les membres
  static Stream<List<CustomPageModel>> getPublicPagesStream({String? userId}) {
    try {
      Query query = _firestore.collection(pagesCollection)
          .where('status', isEqualTo: 'published')
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        final pages = snapshot.docs
            .map((doc) => CustomPageModel.fromFirestore(doc))
            .toList();

        // Filtrer par visibilité et dates
        return pages.where((page) => page.isVisible).toList();
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des pages publiques: $e');
    }
  }

  // Vérifier la disponibilité d'un slug
  static Future<bool> isSlugAvailable(String slug, {String? excludePageId}) async {
    try {
      Query query = _firestore.collection(pagesCollection)
          .where('slug', isEqualTo: slug);

      final docs = await query.get();
      
      if (excludePageId != null) {
        return docs.docs.every((doc) => doc.id == excludePageId);
      }
      
      return docs.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Duplication de page
  static Future<String> duplicatePage(String originalPageId, String newTitle, String newSlug) async {
    try {
      final originalPage = await getPage(originalPageId);
      if (originalPage == null) {
        throw Exception('Page originale introuvable');
      }

      final duplicatedPage = originalPage.copyWith(
        title: newTitle,
        slug: newSlug,
        status: 'draft',
        updatedAt: DateTime.now(),
        lastModifiedBy: _auth.currentUser?.uid,
      );

      final newPageData = duplicatedPage.toFirestore();
      newPageData.remove('id'); // Supprimer l'ID pour créer un nouveau document

      final docRef = await _firestore.collection(pagesCollection).add({
        ...newPageData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
      });

      await _logPageActivity(docRef.id, 'page_duplicated', {
        'originalPageId': originalPageId,
        'newTitle': newTitle,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication de la page: $e');
    }
  }

  // Publication de page
  static Future<void> publishPage(String pageId) async {
    try {
      await _firestore.collection(pagesCollection).doc(pageId).update({
        'status': 'published',
        'publishDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });

      await _logPageActivity(pageId, 'page_published', {});
    } catch (e) {
      throw Exception('Erreur lors de la publication de la page: $e');
    }
  }

  // Archivage de page
  static Future<void> archivePage(String pageId) async {
    try {
      await _firestore.collection(pagesCollection).doc(pageId).update({
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });

      await _logPageActivity(pageId, 'page_archived', {});
    } catch (e) {
      throw Exception('Erreur lors de l\'archivage de la page: $e');
    }
  }

  // Templates
  static Future<List<PageTemplate>> getPageTemplates() async {
    try {
      // Essayer d'abord avec l'index composite
      try {
        final query = await _firestore
            .collection(pageTemplatesCollection)
            .orderBy('category')
            .orderBy('name')
            .get();

        return query.docs
            .map((doc) => PageTemplate.fromFirestore(doc))
            .toList();
      } catch (indexError) {
        // Fallback: récupérer tous les templates et trier côté client
        final query = await _firestore
            .collection(pageTemplatesCollection)
            .orderBy('category')
            .get();

        final templates = query.docs
            .map((doc) => PageTemplate.fromFirestore(doc))
            .toList();

        // Tri côté client
        templates.sort((a, b) {
          int categoryCompare = a.category.compareTo(b.category);
          if (categoryCompare != 0) return categoryCompare;
          return a.name.compareTo(b.name);
        });

        return templates;
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles: $e');
    }
  }

  static Future<void> saveAsTemplate(
    CustomPageModel page,
    String templateName,
    String category,
    String description,
  ) async {
    try {
      final template = PageTemplate(
        id: '',
        name: templateName,
        description: description,
        category: category,
        components: page.components,
        defaultSettings: page.settings,
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      );

      await _firestore.collection(pageTemplatesCollection).add(template.toFirestore());

      await _logPageActivity(page.id, 'template_created', {
        'templateName': templateName,
        'category': category,
      });
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du modèle: $e');
    }
  }

  // Statistiques de vues
  static Future<void> recordPageView(String pageId, String? userId) async {
    try {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore.collection(pageViewsCollection).add({
        'pageId': pageId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateKey,
        'userAgent': 'Flutter App',
      });
    } catch (e) {
      // Ne pas lancer d'erreur pour les statistiques
      print('Erreur lors de l\'enregistrement de la vue: $e');
    }
  }

  static Future<PageStatistics> getPageStatistics(String pageId) async {
    try {
      final viewsQuery = await _firestore
          .collection(pageViewsCollection)
          .where('pageId', isEqualTo: pageId)
          .get();

      final totalViews = viewsQuery.docs.length;
      final uniqueUsers = viewsQuery.docs
          .where((doc) => doc.data()['userId'] != null)
          .map((doc) => doc.data()['userId'])
          .toSet()
          .length;

      final viewsByDate = <String, int>{};
      final viewsByRole = <String, int>{};

      for (final doc in viewsQuery.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        if (date != null) {
          viewsByDate[date] = (viewsByDate[date] ?? 0) + 1;
        }
      }

      return PageStatistics(
        pageId: pageId,
        totalViews: totalViews,
        uniqueViews: uniqueUsers,
        viewsByDate: viewsByDate,
        viewsByRole: viewsByRole,
        componentInteractions: {},
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // Recherche de pages
  static Future<List<CustomPageModel>> searchPages(String query) async {
    try {
      final allPages = await _firestore
          .collection(pagesCollection)
          .where('status', isEqualTo: 'published')
          .get();

      final lowercaseQuery = query.toLowerCase();
      return allPages.docs
          .map((doc) => CustomPageModel.fromFirestore(doc))
          .where((page) =>
              page.title.toLowerCase().contains(lowercaseQuery) ||
              page.description.toLowerCase().contains(lowercaseQuery) ||
              page.slug.toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Méthode alternative pour éviter les erreurs d'index
  static Future<List<CustomPageModel>> getAllPagesForManagement() async {
    try {
      final snapshot = await _firestore.collection(pagesCollection)
          .orderBy('displayOrder')
          .get();
      
      final pages = snapshot.docs
          .map((doc) => CustomPageModel.fromFirestore(doc))
          .toList();

      // Tri côté client pour assurer l'ordre correct
      pages.sort((a, b) {
        int displayOrderCompare = a.displayOrder.compareTo(b.displayOrder);
        if (displayOrderCompare != 0) return displayOrderCompare;
        return b.createdAt.compareTo(a.createdAt); // Descending
      });

      return pages;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des pages pour gestion: $e');
    }
  }

  // Mise à jour de l'ordre d'affichage
  static Future<void> updateDisplayOrder(List<String> pageIds) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < pageIds.length; i++) {
        final docRef = _firestore.collection(pagesCollection).doc(pageIds[i]);
        batch.update(docRef, {
          'displayOrder': i,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': _auth.currentUser?.uid,
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'ordre: $e');
    }
  }

  // Vérifier l'accès utilisateur à une page
  static Future<bool> canUserAccessPage(String pageId, String? userId) async {
    try {
      final page = await getPage(pageId);
      if (page == null || !page.isVisible) return false;

      if (page.visibility == 'public') return true;
      if (page.visibility == 'members' && userId != null) return true;

      // Pour les restrictions par groupe/rôle, il faudrait charger les données utilisateur
      // Implémentation simplifiée pour l'exemple
      return false;
    } catch (e) {
      return false;
    }
  }

  // Log d'activité
  static Future<void> _logPageActivity(String pageId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(pageActivityLogsCollection).add({
        'pageId': pageId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Ne pas lancer d'erreur pour les logs
      print('Erreur lors de l\'enregistrement du log: $e');
    }
  }

  // Créer les modèles par défaut
  static Future<void> createDefaultTemplates() async {
    try {
      final templates = [
        PageTemplate(
          id: '',
          name: 'Page d\'accueil nouveaux membres',
          description: 'Modèle pour accueillir les nouveaux membres',
          category: 'Accueil',
          iconName: 'waving_hand',
          components: _getWelcomeTemplateComponents(),
          isBuiltIn: true,
          createdAt: DateTime.now(),
        ),
        PageTemplate(
          id: '',
          name: 'Programme jeunesse',
          description: 'Modèle pour les activités jeunesse',
          category: 'Ministères',
          iconName: 'groups',
          components: _getYouthTemplateComponents(),
          isBuiltIn: true,
          createdAt: DateTime.now(),
        ),
        PageTemplate(
          id: '',
          name: 'Inscription événement',
          description: 'Modèle pour les inscriptions aux événements',
          category: 'Événements',
          iconName: 'event',
          components: _getEventRegistrationTemplateComponents(),
          isBuiltIn: true,
          createdAt: DateTime.now(),
        ),
      ];

      for (final template in templates) {
        await _firestore.collection(pageTemplatesCollection).add(template.toFirestore());
      }
    } catch (e) {
      print('Erreur lors de la création des modèles par défaut: $e');
    }
  }

  static List<PageComponent> _getWelcomeTemplateComponents() {
    return [
      PageComponent(
        id: 'welcome-banner',
        type: 'banner',
        name: 'Bannière de bienvenue',
        order: 0,
        data: {
          'title': 'Bienvenue dans notre communauté !',
          'subtitle': 'Nous sommes ravis de vous accueillir',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        },
      ),
      PageComponent(
        id: 'welcome-text',
        type: 'text',
        name: 'Texte d\'accueil',
        order: 1,
        data: {
          'content': '''Bienvenue ! Nous sommes une communauté chaleureuse qui cherche à grandir ensemble dans la foi. 

Voici quelques étapes pour bien commencer votre parcours parmi nous :''',
          'fontSize': 16,
          'textAlign': 'left',
        },
      ),
      PageComponent(
        id: 'next-steps',
        type: 'list',
        name: 'Prochaines étapes',
        order: 2,
        data: {
          'title': 'Vos prochaines étapes',
          'items': [
            {
              'title': 'Rejoindre un petit groupe',
              'description': 'Connectez-vous avec d\'autres membres',
              'action': 'groups',
              'icon': 'groups',
            },
            {
              'title': 'Consulter le calendrier',
              'description': 'Découvrez nos événements à venir',
              'action': 'events',
              'icon': 'calendar_today',
            },
            {
              'title': 'Remplir votre profil',
              'description': 'Aidez-nous à mieux vous connaître',
              'action': 'profile',
              'icon': 'person',
            },
          ],
        },
      ),
    ];
  }

  static List<PageComponent> _getYouthTemplateComponents() {
    return [
      PageComponent(
        id: 'youth-header',
        type: 'image',
        name: 'En-tête jeunesse',
        order: 0,
        data: {
          'url': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
          'alt': 'Jeunes en groupe',
          'height': 200,
        },
      ),
      PageComponent(
        id: 'youth-description',
        type: 'text',
        name: 'Description du ministère',
        order: 1,
        data: {
          'content': '''## Ministère Jeunesse

Rejoignez-nous chaque vendredi soir pour un temps de louange, d\'enseignement et de communion fraternelle !

**Horaires :** Vendredis 19h30 - 21h30
**Lieu :** Grande salle
**Âge :** 13-25 ans''',
          'fontSize': 16,
        },
      ),
      PageComponent(
        id: 'youth-video',
        type: 'video',
        name: 'Vidéo de présentation',
        order: 2,
        data: {
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title': 'Découvrez notre ministère jeunesse',
        },
      ),
    ];
  }

  static List<PageComponent> _getEventRegistrationTemplateComponents() {
    return [
      PageComponent(
        id: 'event-info',
        type: 'text',
        name: 'Informations événement',
        order: 0,
        data: {
          'content': '''# Inscription à l'événement

Merci de remplir ce formulaire pour vous inscrire à notre prochain événement.''',
          'fontSize': 18,
        },
      ),
      PageComponent(
        id: 'registration-form',
        type: 'form',
        name: 'Formulaire d\'inscription',
        order: 1,
        data: {
          'formId': '', // À remplir avec un vrai ID de formulaire
          'title': 'Formulaire d\'inscription',
        },
      ),
      PageComponent(
        id: 'contact-info',
        type: 'text',
        name: 'Informations de contact',
        order: 2,
        data: {
          'content': '''## Questions ?

N'hésitez pas à nous contacter si vous avez des questions.

**Email :** info@eglise.fr
**Téléphone :** 01 23 45 67 89''',
          'fontSize': 14,
        },
      ),
    ];
  }
}