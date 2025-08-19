import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/services/base_firebase_service.dart';
import '../models/person_module_model.dart';

/// Service pour la gestion des personnes
class PeopleModuleService extends BaseFirebaseService<Person> {
  @override
  String get collectionName => 'people';

  @override
  Person fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person.fromMap(data, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(Person person) {
    return person.toMap();
  }

  /// Initialiser le service
  Future<void> initialize() async {
    // Initialisation spécifique au service des personnes
    print('Service People initialisé');
  }

  /// Nettoyer le service
  Future<void> dispose() async {
    // Nettoyage spécifique au service des personnes
    print('Service People nettoyé');
  }

  /// Rechercher des personnes par nom
  @override
  Future<List<Person>> search(String query) async {
    if (query.isEmpty) return [];

    try {
      final querySnapshot = await collection
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: query + '\uf8ff')
          .get();

      final firstNameResults = querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();

      final lastNameQuery = await collection
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: query + '\uf8ff')
          .get();

      final lastNameResults = lastNameQuery.docs
          .map((doc) => fromFirestore(doc))
          .toList();

      // Combiner et dédupliquer les résultats
      final combined = <String, Person>{};
      for (final person in firstNameResults) {
        if (person.id != null) combined[person.id!] = person;
      }
      for (final person in lastNameResults) {
        if (person.id != null) combined[person.id!] = person;
      }

      return combined.values.toList();
    } catch (e) {
      print('Erreur lors de la recherche de personnes: $e');
      return [];
    }
  }

  /// Rechercher par email
  Future<Person?> findByEmail(String email) async {
    try {
      final querySnapshot = await collection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la recherche par email: $e');
      return null;
    }
  }

  /// Rechercher par téléphone
  Future<Person?> findByPhone(String phone) async {
    try {
      final querySnapshot = await collection
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la recherche par telephone: $e');
      return null;
    }
  }

  /// Obtenir les personnes par rôle
  Future<List<Person>> getByRole(String role) async {
    try {
      final querySnapshot = await collection
          .where('roles', arrayContains: role)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche par role: $e');
      return [];
    }
  }

  /// Obtenir les anniversaires du mois
  Future<List<Person>> getBirthdaysThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final querySnapshot = await collection
          .where('birthDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('birthDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche des anniversaires: $e');
      return [];
    }
  }

  /// Statistiques des personnes
  Future<Map<String, int>> getStatistics() async {
    try {
      final allPeople = await getAll();
      final activePeople = allPeople.where((p) => p.isActive).toList();
      
      return {
        'total': allPeople.length,
        'actives': activePeople.length,
        'inactives': allPeople.length - activePeople.length,
        'withEmail': activePeople.where((p) => p.email != null && p.email!.isNotEmpty).length,
        'withPhone': activePeople.where((p) => p.phone != null && p.phone!.isNotEmpty).length,
        'withBirthDate': activePeople.where((p) => p.birthDate != null).length,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Mettre à jour le rôle d'une personne
  Future<bool> updateRole(String personId, String role, bool add) async {
    try {
      final person = await getById(personId);
      if (person == null) return false;

      List<String> roles = List.from(person.roles);
      if (add) {
        if (!roles.contains(role)) {
          roles.add(role);
        }
      } else {
        roles.remove(role);
      }

      final updatedPerson = person.copyWith(
        roles: roles,
        updatedAt: DateTime.now(),
      );

      await update(personId, updatedPerson);
      return true;
    } catch (e) {
      print('Erreur lors de la mise a jour du role: $e');
      return false;
    }
  }

  /// Importer des personnes depuis une liste
  Future<int> importPeople(List<Map<String, dynamic>> peopleData) async {
    int imported = 0;
    
    for (final data in peopleData) {
      try {
        final person = Person(
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'],
          phone: data['phone'],
          birthDate: data['birthDate'] != null ? DateTime.tryParse(data['birthDate']) : null,
          address: data['address'],
          roles: List<String>.from(data['roles'] ?? []),
          customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
        );

        final success = await create(person);
        if (success != null) imported++;
      } catch (e) {
        print('Erreur lors de l importation d une personne: $e');
      }
    }

    return imported;
  }

  /// Exporter toutes les personnes
  Future<List<Map<String, dynamic>>> exportPeople() async {
    try {
      final people = await getAll();
      return people.map((person) => person.toMap()).toList();
    } catch (e) {
      print('Erreur lors de l exportation: $e');
      return [];
    }
  }
}