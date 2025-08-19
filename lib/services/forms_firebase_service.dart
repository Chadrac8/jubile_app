import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/form_model.dart';
import '../models/person_model.dart';

class FormsFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String formsCollection = 'forms';
  static const String formSubmissionsCollection = 'form_submissions';
  static const String formTemplatesCollection = 'form_templates';
  static const String formActivityLogsCollection = 'form_activity_logs';

  // Form CRUD Operations
  static Future<String> createForm(FormModel form) async {
    try {
      final docRef = await _firestore.collection(formsCollection).add(form.toFirestore());
      await _logFormActivity(docRef.id, 'form_created', {'title': form.title});
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du formulaire: $e');
    }
  }

  static Future<void> updateForm(FormModel form) async {
    try {
      await _firestore.collection(formsCollection).doc(form.id).update(form.toFirestore());
      await _logFormActivity(form.id, 'form_updated', {'title': form.title});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du formulaire: $e');
    }
  }

  static Future<void> deleteForm(String formId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete form
      batch.delete(_firestore.collection(formsCollection).doc(formId));
      
      // Delete all submissions
      final submissions = await _firestore
          .collection(formSubmissionsCollection)
          .where('formId', isEqualTo: formId)
          .get();
      
      for (final doc in submissions.docs) {
        batch.delete(doc.reference);
        
        // Delete uploaded files
        final submission = FormSubmissionModel.fromFirestore(doc);
        for (final fileUrl in submission.fileUrls) {
          try {
            final ref = _storage.refFromURL(fileUrl);
            await ref.delete();
          } catch (e) {
            // File might not exist, continue
          }
        }
      }
      
      await batch.commit();
      await _logFormActivity(formId, 'form_deleted', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression du formulaire: $e');
    }
  }

  static Future<FormModel?> getForm(String formId) async {
    try {
      final doc = await _firestore.collection(formsCollection).doc(formId).get();
      if (doc.exists) {
        return FormModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du formulaire: $e');
    }
  }

  static Stream<List<FormModel>> getFormsStream({
    String? searchQuery,
    String? statusFilter,
    String? accessibilityFilter,
    String? createdBy,
    int limit = 50,
  }) {
    try {
      Query query = _firestore.collection(formsCollection).orderBy('updatedAt', descending: true);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      if (accessibilityFilter != null && accessibilityFilter.isNotEmpty) {
        query = query.where('accessibility', isEqualTo: accessibilityFilter);
      }

      if (createdBy != null && createdBy.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }

      if (limit > 0) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        var forms = snapshot.docs.map((doc) => FormModel.fromFirestore(doc)).toList();

        // Client-side search filtering
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final queryLower = searchQuery.toLowerCase();
          forms = forms.where((form) =>
              form.title.toLowerCase().contains(queryLower) ||
              form.description.toLowerCase().contains(queryLower)
          ).toList();
        }

        return forms;
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des formulaires: $e');
    }
  }

  // Public form access
  static Future<FormModel?> getPublicForm(String formId) async {
    try {
      final doc = await _firestore.collection(formsCollection).doc(formId).get();
      if (doc.exists) {
        final form = FormModel.fromFirestore(doc);
        // Check if form is publicly accessible
        if (form.accessibility == 'public' && form.isOpen) {
          return form;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de l\'accès au formulaire public: $e');
    }
  }

  // Form Submissions
  static Future<String> submitForm(FormSubmissionModel submission) async {
    try {
      // Check if form exists and is open
      final form = await getForm(submission.formId);
      if (form == null || !form.isOpen) {
        throw Exception('Le formulaire n\'est pas disponible');
      }

      // Check submission limit
      if (form.hasSubmissionLimit) {
        final count = await getSubmissionCount(submission.formId);
        if (count >= form.submissionLimit!) {
          throw Exception('La limite de soumissions a été atteinte');
        }
      }

      // Check for multiple submissions
      if (!form.settings.allowMultipleSubmissions && submission.personId != null) {
        final existingSubmissions = await _firestore
            .collection(formSubmissionsCollection)
            .where('formId', isEqualTo: submission.formId)
            .where('personId', isEqualTo: submission.personId)
            .get();
        
        if (existingSubmissions.docs.isNotEmpty) {
          throw Exception('Vous avez déjà soumis ce formulaire');
        }
      }

      final docRef = await _firestore.collection(formSubmissionsCollection).add(submission.toFirestore());
      
      // Execute post-submission actions
      await _executePostSubmissionActions(form, submission);
      
      await _logFormActivity(submission.formId, 'form_submitted', {
        'submissionId': docRef.id,
        'personId': submission.personId,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la soumission du formulaire: $e');
    }
  }

  static Future<void> updateSubmissionStatus(String submissionId, String newStatus) async {
    try {
      await _firestore.collection(formSubmissionsCollection).doc(submissionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  static Stream<List<FormSubmissionModel>> getFormSubmissionsStream(String formId, {
    String? statusFilter,
    bool includeTestSubmissions = false,
  }) {
    try {
      Query query = _firestore
          .collection(formSubmissionsCollection)
          .where('formId', isEqualTo: formId)
          .orderBy('submittedAt', descending: true);

      if (!includeTestSubmissions) {
        query = query.where('isTestSubmission', isEqualTo: false);
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => FormSubmissionModel.fromFirestore(doc)).toList()
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des soumissions: $e');
    }
  }

  static Future<int> getSubmissionCount(String formId, {bool includeTestSubmissions = false}) async {
    try {
      Query query = _firestore
          .collection(formSubmissionsCollection)
          .where('formId', isEqualTo: formId);

      if (!includeTestSubmissions) {
        query = query.where('isTestSubmission', isEqualTo: false);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des soumissions: $e');
    }
  }

  // File upload for form submissions
  static Future<String> uploadFormFile(Uint8List fileBytes, String fileName, String formId) async {
    try {
      final ref = _storage.ref().child('forms/$formId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du fichier: $e');
    }
  }

  // Form Templates
  static Future<List<FormTemplate>> getFormTemplates() async {
    try {
      final snapshot = await _firestore.collection(formTemplatesCollection).get();
      return snapshot.docs.map((doc) => FormTemplate.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles: $e');
    }
  }

  static Future<void> saveAsTemplate(FormModel form, String templateName, String category) async {
    try {
      final template = FormTemplate(
        id: '',
        name: templateName,
        description: form.description,
        category: category,
        fields: form.fields,
        defaultSettings: form.settings,
        isBuiltIn: false,
      );

      await _firestore.collection(formTemplatesCollection).add(template.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du modèle: $e');
    }
  }

  // Duplicate form
  static Future<String> duplicateForm(String originalFormId, String newTitle) async {
    try {
      final originalForm = await getForm(originalFormId);
      if (originalForm == null) {
        throw Exception('Formulaire original introuvable');
      }

      final duplicatedForm = originalForm.copyWith(
        title: newTitle,
        status: 'brouillon',
        updatedAt: DateTime.now(),
        lastModifiedBy: _auth.currentUser?.uid,
      );

      final formData = duplicatedForm.toFirestore();
      formData.remove('id');
      formData['createdAt'] = FieldValue.serverTimestamp();
      formData['createdBy'] = _auth.currentUser?.uid;

      final docRef = await _firestore.collection(formsCollection).add(formData);
      
      await _logFormActivity(docRef.id, 'form_duplicated', {
        'originalFormId': originalFormId,
        'title': newTitle,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication du formulaire: $e');
    }
  }

  // Statistics
  static Future<FormStatisticsModel> getFormStatistics(String formId) async {
    try {
      final submissions = await _firestore
          .collection(formSubmissionsCollection)
          .where('formId', isEqualTo: formId)
          .get();

      final allSubmissions = submissions.docs.map((doc) => FormSubmissionModel.fromFirestore(doc)).toList();
      
      final totalSubmissions = allSubmissions.length;
      final processedSubmissions = allSubmissions.where((s) => s.status == 'processed').length;
      final archivedSubmissions = allSubmissions.where((s) => s.status == 'archived').length;
      final testSubmissions = allSubmissions.where((s) => s.isTestSubmission).length;

      // Group submissions by date
      final submissionsByDate = <String, int>{};
      for (final submission in allSubmissions) {
        final dateKey = '${submission.submittedAt.year}-${submission.submittedAt.month.toString().padLeft(2, '0')}-${submission.submittedAt.day.toString().padLeft(2, '0')}';
        submissionsByDate[dateKey] = (submissionsByDate[dateKey] ?? 0) + 1;
      }

      // Analyze field responses
      final fieldResponses = <String, Map<String, int>>{};
      for (final submission in allSubmissions) {
        for (final entry in submission.responses.entries) {
          final fieldId = entry.key;
          final response = entry.value.toString();
          
          if (!fieldResponses.containsKey(fieldId)) {
            fieldResponses[fieldId] = {};
          }
          
          fieldResponses[fieldId]![response] = (fieldResponses[fieldId]![response] ?? 0) + 1;
        }
      }

      return FormStatisticsModel(
        formId: formId,
        totalSubmissions: totalSubmissions,
        processedSubmissions: processedSubmissions,
        archivedSubmissions: archivedSubmissions,
        testSubmissions: testSubmissions,
        submissionsByDate: submissionsByDate,
        fieldResponses: fieldResponses,
        averageCompletionTime: 0.0, // TODO: Implement completion time tracking
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Export submissions
  static Future<List<Map<String, dynamic>>> exportFormSubmissions(String formId) async {
    try {
      final submissions = await _firestore
          .collection(formSubmissionsCollection)
          .where('formId', isEqualTo: formId)
          .where('isTestSubmission', isEqualTo: false)
          .orderBy('submittedAt', descending: true)
          .get();

      final form = await getForm(formId);
      if (form == null) return [];

      return submissions.docs.map((doc) {
        final submission = FormSubmissionModel.fromFirestore(doc);
        final Map<String, dynamic> exportData = {
          'ID': submission.id,
          'Nom complet': submission.fullName,
          'Email': submission.email ?? '',
          'Date de soumission': submission.submittedAt.toIso8601String(),
          'Statut': submission.status,
        };

        // Add field responses
        for (final field in form.fields) {
          if (field.isInputField) {
            final response = submission.responses[field.id];
            exportData[field.label] = response?.toString() ?? '';
          }
        }

        return exportData;
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de l\'export des soumissions: $e');
    }
  }

  // Search forms
  static Future<List<FormModel>> searchForms(String query) async {
    try {
      final snapshot = await _firestore.collection(formsCollection).get();
      final queryLower = query.toLowerCase();
      
      return snapshot.docs
          .map((doc) => FormModel.fromFirestore(doc))
          .where((form) =>
              form.title.toLowerCase().contains(queryLower) ||
              form.description.toLowerCase().contains(queryLower)
          )
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Archive form
  static Future<void> archiveForm(String formId) async {
    try {
      await _firestore.collection(formsCollection).doc(formId).update({
        'status': 'archive',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });
      
      await _logFormActivity(formId, 'form_archived', {});
    } catch (e) {
      throw Exception('Erreur lors de l\'archivage du formulaire: $e');
    }
  }

  // Helper: Execute post-submission actions
  static Future<void> _executePostSubmissionActions(FormModel form, FormSubmissionModel submission) async {
    try {
      final settings = form.settings;
      
      // Auto-add to group
      if (settings.autoAddToGroup && settings.targetGroupId != null && submission.personId != null) {
        // TODO: Implement group addition
        // await GroupsFirebaseService.addMemberToGroup(settings.targetGroupId!, submission.personId!, 'member');
      }
      
      // Auto-add to workflow
      if (settings.autoAddToWorkflow && settings.targetWorkflowId != null && submission.personId != null) {
        // TODO: Implement workflow addition
        // await FirebaseService.startWorkflowForPerson(submission.personId!, settings.targetWorkflowId!);
      }
      
      // Send notifications (implement email service)
      if (settings.sendConfirmationEmail && submission.email != null) {
        // TODO: Implement email service
      }
      
      for (final email in settings.notificationEmails) {
        // TODO: Send notification email to administrators
      }
    } catch (e) {
      // Log error but don't fail the submission
      print('Error executing post-submission actions: $e');
    }
  }

  // Helper: Log form activity
  static Future<void> _logFormActivity(String formId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(formActivityLogsCollection).add({
        'formId': formId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Error logging form activity: $e');
    }
  }

  // Get user's form submissions
  static Future<List<FormSubmissionModel>> getUserSubmissions(String personId) async {
    try {
      final snapshot = await _firestore
          .collection(formSubmissionsCollection)
          .where('personId', isEqualTo: personId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => FormSubmissionModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des soumissions utilisateur: $e');
    }
  }

  // Check form access permission
  static Future<bool> canUserAccessForm(String formId, String? userId) async {
    try {
      final form = await getForm(formId);
      if (form == null) return false;

      switch (form.accessibility) {
        case 'public':
          return true;
        case 'membres':
          return userId != null;
        case 'groupe':
        case 'role':
          // TODO: Implement group/role access checking
          return userId != null;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Generate public form URL
  static String generatePublicFormUrl(String formId) {
    // TODO: Replace with actual domain
    return 'https://your-domain.com/forms/$formId';
  }
}