import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dynamic_list_model.dart';
import '../auth/auth_service.dart';

/// Service Firebase pour les listes dynamiques
class DynamicListsFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'dynamic_lists';

  /// Créer une nouvelle liste dynamique
  static Future<String> createList(DynamicListModel list) async {
    try {
      final docRef = await _firestore.collection(_collection).add(list.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la liste: $e');
    }
  }

  /// Obtenir toutes les listes de l'utilisateur actuel
  static Future<List<DynamicListModel>> getUserLists() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => DynamicListModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des listes: $e');
    }
  }

  /// Obtenir les listes publiques et partagées
  static Future<List<DynamicListModel>> getSharedLists() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      // Listes publiques
      final publicQuery = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Listes partagées avec l'utilisateur
      final sharedQuery = await _firestore
          .collection(_collection)
          .where('sharedWith', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final publicLists = publicQuery.docs
          .map((doc) => DynamicListModel.fromFirestore(doc))
          .toList();

      final sharedLists = sharedQuery.docs
          .map((doc) => DynamicListModel.fromFirestore(doc))
          .toList();

      // Combiner et dédupliquer
      final allLists = [...publicLists, ...sharedLists];
      final uniqueLists = <String, DynamicListModel>{};
      for (final list in allLists) {
        uniqueLists[list.id] = list;
      }

      return uniqueLists.values.toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des listes partagées: $e');
    }
  }

  /// Obtenir toutes les listes accessibles à l'utilisateur
  static Future<List<DynamicListModel>> getAllAccessibleLists() async {
    try {
      final userLists = await getUserLists();
      final sharedLists = await getSharedLists();
      
      // Combiner et trier par dernière utilisation puis date de création
      final allLists = [...userLists, ...sharedLists];
      allLists.sort((a, b) {
        if (a.lastUsed != null && b.lastUsed != null) {
          return b.lastUsed!.compareTo(a.lastUsed!);
        } else if (a.lastUsed != null) {
          return -1;
        } else if (b.lastUsed != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return allLists;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des listes: $e');
    }
  }

  /// Obtenir une liste par ID
  static Future<DynamicListModel?> getListById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return DynamicListModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la liste: $e');
    }
  }

  /// Mettre à jour une liste
  static Future<void> updateList(String id, DynamicListModel list) async {
    try {
      await _firestore.collection(_collection).doc(id).update(
        list.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la liste: $e');
    }
  }

  /// Supprimer une liste
  static Future<void> deleteList(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la liste: $e');
    }
  }

  /// Marquer une liste comme utilisée
  static Future<void> markListAsUsed(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'lastUsed': Timestamp.fromDate(DateTime.now()),
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse pour les statistiques
      print('Erreur lors de la mise à jour des statistiques: $e');
    }
  }

  /// Basculer le statut favori d'une liste
  static Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isFavorite': isFavorite,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des favoris: $e');
    }
  }

  /// Partager une liste avec des utilisateurs
  static Future<void> shareList(String id, List<String> userIds) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'sharedWith': FieldValue.arrayUnion(userIds),
      });
    } catch (e) {
      throw Exception('Erreur lors du partage de la liste: $e');
    }
  }

  /// Arrêter de partager une liste avec des utilisateurs
  static Future<void> unshareList(String id, List<String> userIds) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'sharedWith': FieldValue.arrayRemove(userIds),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'arrêt du partage: $e');
    }
  }

  /// Dupliquer une liste
  static Future<String> duplicateList(String id, String newName) async {
    try {
      final originalList = await getListById(id);
      if (originalList == null) {
        throw Exception('Liste originale non trouvée');
      }

      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final duplicatedList = originalList.copyWith(
        name: newName,
        isPublic: false,
        sharedWith: [],
        isFavorite: false,
        viewCount: 0,
        lastUsed: null,
      );

      final docRef = await _firestore.collection(_collection).add(
        duplicatedList.toFirestore()..['createdBy'] = user.uid,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication: $e');
    }
  }

  /// Obtenir les listes par catégorie
  static Future<Map<String, List<DynamicListModel>>> getListsByCategory() async {
    try {
      final allLists = await getAllAccessibleLists();
      final categories = <String, List<DynamicListModel>>{};

      for (final list in allLists) {
        final category = list.category;
        if (!categories.containsKey(category)) {
          categories[category] = [];
        }
        categories[category]!.add(list);
      }

      return categories;
    } catch (e) {
      throw Exception('Erreur lors de la récupération par catégorie: $e');
    }
  }

  /// Rechercher des listes
  static Future<List<DynamicListModel>> searchLists(String query) async {
    try {
      final allLists = await getAllAccessibleLists();
      final lowercaseQuery = query.toLowerCase();

      return allLists.where((list) {
        return list.name.toLowerCase().contains(lowercaseQuery) ||
               list.description.toLowerCase().contains(lowercaseQuery) ||
               list.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}

/// Service pour les templates de listes dynamiques
class DynamicListTemplatesService {
  /// Obtenir tous les templates disponibles
  static List<DynamicListTemplate> getAllTemplates() {
    return [
      // Templates pour les Personnes
      DynamicListTemplate(
        id: 'people_basic',
        name: 'Liste basique des membres',
        description: 'Liste simple avec nom, prénom, email et téléphone',
        sourceModule: 'people',
        category: 'Personnes',
        iconName: 'people',
        fields: [
          DynamicListField(
            fieldKey: 'lastName',
            displayName: 'Nom',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'firstName',
            displayName: 'Prénom',
            fieldType: 'text',
            order: 1,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'email',
            displayName: 'Email',
            fieldType: 'email',
            order: 2,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'phone',
            displayName: 'Téléphone',
            fieldType: 'phone',
            order: 3,
            isClickable: true,
          ),
        ],
        sorting: [
          DynamicListSort(
            fieldKey: 'lastName',
            direction: 'asc',
            priority: 1,
          ),
        ],
      ),

      DynamicListTemplate(
        id: 'people_contact',
        name: 'Carnet d\'adresses',
        description: 'Liste complète avec coordonnées et adresses',
        sourceModule: 'people',
        category: 'Personnes',
        iconName: 'contact_page',
        fields: [
          DynamicListField(
            fieldKey: 'fullName',
            displayName: 'Nom complet',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'email',
            displayName: 'Email',
            fieldType: 'email',
            order: 1,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'phone',
            displayName: 'Téléphone',
            fieldType: 'phone',
            order: 2,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'address',
            displayName: 'Adresse',
            fieldType: 'text',
            order: 3,
          ),
          DynamicListField(
            fieldKey: 'city',
            displayName: 'Ville',
            fieldType: 'text',
            order: 4,
          ),
        ],
      ),

      DynamicListTemplate(
        id: 'people_ministry',
        name: 'Équipes ministérielles',
        description: 'Membres avec leurs rôles et responsabilités',
        sourceModule: 'people',
        category: 'Ministère',
        iconName: 'groups',
        fields: [
          DynamicListField(
            fieldKey: 'fullName',
            displayName: 'Nom',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'roles',
            displayName: 'Rôles',
            fieldType: 'list',
            order: 1,
          ),
          DynamicListField(
            fieldKey: 'email',
            displayName: 'Email',
            fieldType: 'email',
            order: 2,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'phone',
            displayName: 'Téléphone',
            fieldType: 'phone',
            order: 3,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'joinDate',
            displayName: 'Membre depuis',
            fieldType: 'date',
            order: 4,
            format: 'dd/MM/yyyy',
          ),
        ],
        filters: [
          DynamicListFilter(
            fieldKey: 'isActive',
            operator: 'equals',
            value: true,
          ),
        ],
      ),

      DynamicListTemplate(
        id: 'people_birthday',
        name: 'Anniversaires du mois',
        description: 'Liste des anniversaires à venir',
        sourceModule: 'people',
        category: 'Événements',
        iconName: 'cake',
        fields: [
          DynamicListField(
            fieldKey: 'fullName',
            displayName: 'Nom',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'birthDate',
            displayName: 'Date de naissance',
            fieldType: 'date',
            order: 1,
            format: 'dd/MM',
          ),
          DynamicListField(
            fieldKey: 'age',
            displayName: 'Âge',
            fieldType: 'number',
            order: 2,
          ),
          DynamicListField(
            fieldKey: 'phone',
            displayName: 'Téléphone',
            fieldType: 'phone',
            order: 3,
            isClickable: true,
          ),
        ],
        sorting: [
          DynamicListSort(
            fieldKey: 'birthDate',
            direction: 'asc',
            priority: 1,
          ),
        ],
      ),

      // Templates pour les Groupes
      DynamicListTemplate(
        id: 'groups_active',
        name: 'Groupes actifs',
        description: 'Liste des groupes en activité',
        sourceModule: 'groups',
        category: 'Groupes',
        iconName: 'groups',
        fields: [
          DynamicListField(
            fieldKey: 'name',
            displayName: 'Nom du groupe',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'category',
            displayName: 'Catégorie',
            fieldType: 'text',
            order: 1,
          ),
          DynamicListField(
            fieldKey: 'memberCount',
            displayName: 'Membres',
            fieldType: 'number',
            order: 2,
          ),
          DynamicListField(
            fieldKey: 'leader',
            displayName: 'Responsable',
            fieldType: 'text',
            order: 3,
          ),
          DynamicListField(
            fieldKey: 'meetingDay',
            displayName: 'Jour de réunion',
            fieldType: 'text',
            order: 4,
          ),
        ],
        filters: [
          DynamicListFilter(
            fieldKey: 'isActive',
            operator: 'equals',
            value: true,
          ),
        ],
      ),

      // Templates pour les Événements
      DynamicListTemplate(
        id: 'events_upcoming',
        name: 'Événements à venir',
        description: 'Prochains événements programmés',
        sourceModule: 'events',
        category: 'Événements',
        iconName: 'event',
        fields: [
          DynamicListField(
            fieldKey: 'title',
            displayName: 'Événement',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'startDate',
            displayName: 'Date',
            fieldType: 'date',
            order: 1,
            format: 'dd/MM/yyyy HH:mm',
          ),
          DynamicListField(
            fieldKey: 'location',
            displayName: 'Lieu',
            fieldType: 'text',
            order: 2,
          ),
          DynamicListField(
            fieldKey: 'registrationCount',
            displayName: 'Inscrits',
            fieldType: 'number',
            order: 3,
          ),
          DynamicListField(
            fieldKey: 'status',
            displayName: 'Statut',
            fieldType: 'text',
            order: 4,
          ),
        ],
        sorting: [
          DynamicListSort(
            fieldKey: 'startDate',
            direction: 'asc',
            priority: 1,
          ),
        ],
      ),

      // Templates pour les Tâches
      DynamicListTemplate(
        id: 'tasks_assigned',
        name: 'Mes tâches assignées',
        description: 'Tâches qui me sont attribuées',
        sourceModule: 'tasks',
        category: 'Tâches',
        iconName: 'task_alt',
        fields: [
          DynamicListField(
            fieldKey: 'title',
            displayName: 'Tâche',
            fieldType: 'text',
            order: 0,
            isClickable: true,
          ),
          DynamicListField(
            fieldKey: 'priority',
            displayName: 'Priorité',
            fieldType: 'text',
            order: 1,
          ),
          DynamicListField(
            fieldKey: 'dueDate',
            displayName: 'Échéance',
            fieldType: 'date',
            order: 2,
            format: 'dd/MM/yyyy',
          ),
          DynamicListField(
            fieldKey: 'status',
            displayName: 'Statut',
            fieldType: 'text',
            order: 3,
          ),
          DynamicListField(
            fieldKey: 'assignedBy',
            displayName: 'Assigné par',
            fieldType: 'text',
            order: 4,
          ),
        ],
        sorting: [
          DynamicListSort(
            fieldKey: 'dueDate',
            direction: 'asc',
            priority: 1,
          ),
        ],
      ),
    ];
  }

  /// Obtenir les templates par catégorie
  static Map<String, List<DynamicListTemplate>> getTemplatesByCategory() {
    final templates = getAllTemplates();
    final categories = <String, List<DynamicListTemplate>>{};

    for (final template in templates) {
      if (!categories.containsKey(template.category)) {
        categories[template.category] = [];
      }
      categories[template.category]!.add(template);
    }

    return categories;
  }

  /// Obtenir un template par ID
  static DynamicListTemplate? getTemplateById(String id) {
    final templates = getAllTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}