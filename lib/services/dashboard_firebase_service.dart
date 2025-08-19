import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_widget_model.dart';
import '../auth/auth_service.dart';

class DashboardFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'dashboard_widgets';
  static const String _preferencesCollectionName = 'dashboard_preferences';

  // Initialiser les widgets par défaut pour un utilisateur
  static Future<void> initializeDefaultWidgets({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Vérifier si l'utilisateur a déjà des widgets
      final existingWidgets = await getDashboardWidgets(userId: uid);
      if (existingWidgets.isNotEmpty) {
        return; // L'utilisateur a déjà des widgets
      }

      // Créer les widgets par défaut
      final defaultWidgets = DefaultDashboardWidgets.getDefaultWidgets();
      final batch = _firestore.batch();

      for (final widget in defaultWidgets) {
        final docRef = _firestore
            .collection(_collectionName)
            .doc(uid)
            .collection('widgets')
            .doc(widget.id);
        batch.set(docRef, widget.toMap());
      }

      await batch.commit();
      print('Widgets par défaut créés pour l\'utilisateur $uid');
    } catch (e) {
      print('Erreur lors de l\'initialisation des widgets par défaut: $e');
      rethrow;
    }
  }

  // Obtenir les widgets du dashboard pour un utilisateur
  static Stream<List<DashboardWidgetModel>> getDashboardWidgetsStream({String? userId}) {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      return _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DashboardWidgetModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Erreur lors de la récupération des widgets: $e');
      return Stream.value([]);
    }
  }

  // Obtenir tous les widgets (visibles et cachés) pour la configuration
  static Stream<List<DashboardWidgetModel>> getAllDashboardWidgetsStream({String? userId}) {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      return _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .orderBy('order')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DashboardWidgetModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Erreur lors de la récupération de tous les widgets: $e');
      return Stream.value([]);
    }
  }

  // Obtenir les widgets du dashboard (version Future)
  static Future<List<DashboardWidgetModel>> getDashboardWidgets({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      final snapshot = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => DashboardWidgetModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des widgets: $e');
      return [];
    }
  }

  // Mettre à jour la visibilité d'un widget
  static Future<void> updateWidgetVisibility(String widgetId, bool isVisible, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .doc(widgetId)
          .update({
        'isVisible': isVisible,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la visibilité du widget: $e');
      rethrow;
    }
  }

  // Mettre à jour l'ordre des widgets
  static Future<void> updateWidgetsOrder(List<DashboardWidgetModel> widgets, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      final batch = _firestore.batch();

      for (int i = 0; i < widgets.length; i++) {
        final widget = widgets[i];
        final docRef = _firestore
            .collection(_collectionName)
            .doc(uid)
            .collection('widgets')
            .doc(widget.id);

        batch.update(docRef, {
          'order': i,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordre des widgets: $e');
      rethrow;
    }
  }

  // Ajouter un widget personnalisé
  static Future<String> addCustomWidget(DashboardWidgetModel widget, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      final docRef = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .add(widget.toMap());

      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du widget personnalisé: $e');
      rethrow;
    }
  }

  // Supprimer un widget
  static Future<void> deleteWidget(String widgetId, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .doc(widgetId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression du widget: $e');
      rethrow;
    }
  }

  // Réinitialiser aux widgets par défaut
  static Future<void> resetToDefaultWidgets({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Supprimer tous les widgets existants
      final existingWidgets = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .get();

      final batch = _firestore.batch();

      // Supprimer les widgets existants
      for (final doc in existingWidgets.docs) {
        batch.delete(doc.reference);
      }

      // Ajouter les widgets par défaut
      final defaultWidgets = DefaultDashboardWidgets.getDefaultWidgets();
      for (final widget in defaultWidgets) {
        final docRef = _firestore
            .collection(_collectionName)
            .doc(uid)
            .collection('widgets')
            .doc(widget.id);
        batch.set(docRef, widget.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la réinitialisation des widgets: $e');
      rethrow;
    }
  }

  // Sauvegarder les préférences générales du dashboard
  static Future<void> saveDashboardPreferences(Map<String, dynamic> preferences, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      await _firestore
          .collection(_preferencesCollectionName)
          .doc(uid)
          .set({
        ...preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la sauvegarde des préférences: $e');
      rethrow;
    }
  }

  // Obtenir les préférences du dashboard
  static Future<Map<String, dynamic>> getDashboardPreferences({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      final doc = await _firestore
          .collection(_preferencesCollectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      // Préférences par défaut
      return {
        'refreshInterval': 300, // 5 minutes
        'showTrends': true,
        'compactView': false,
        'autoRefresh': true,
      };
    } catch (e) {
      print('Erreur lors de la récupération des préférences: $e');
      return {
        'refreshInterval': 300,
        'showTrends': true,
        'compactView': false,
        'autoRefresh': true,
      };
    }
  }

  // Vérifier si l'utilisateur a des widgets configurés
  static Future<bool> hasConfiguredWidgets({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) return false;

      final snapshot = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification des widgets: $e');
      return false;
    }
  }

  // Dupliquer un widget
  static Future<String> duplicateWidget(String widgetId, {String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Récupérer le widget original
      final doc = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .doc(widgetId)
          .get();

      if (!doc.exists) {
        throw Exception('Widget non trouvé');
      }

      final originalWidget = DashboardWidgetModel.fromMap(doc.data()!, doc.id);
      
      // Créer une copie avec un nouveau nom
      final duplicatedWidget = originalWidget.copyWith(
        title: '${originalWidget.title} (Copie)',
        order: originalWidget.order + 1,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder la copie
      final docRef = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .collection('widgets')
          .add(duplicatedWidget.toMap());

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la duplication du widget: $e');
      rethrow;
    }
  }
}