import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';

class WorkflowInitializationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String workflowsCollection = 'workflows';

  /// Initialise les workflows par défaut s'ils n'existent pas
  static Future<void> initializeDefaultWorkflows() async {
    try {
      print('🔄 Initialisation des workflows par défaut...');
      
      // Vérifier si des workflows existent déjà
      final existingWorkflows = await _firestore
          .collection(workflowsCollection)
          .limit(1)
          .get();
      
      if (existingWorkflows.docs.isNotEmpty) {
        print('✅ Workflows déjà initialisés');
        return;
      }

      final batch = _firestore.batch();
      final now = DateTime.now();

      // 1. Workflow Accueil Nouveau Membre
      final newMemberWorkflow = WorkflowModel(
        id: 'new_member_welcome',
        name: 'Accueil Nouveau Membre',
        description: 'Processus d\'intégration et d\'accueil pour les nouveaux membres de l\'église',
        steps: [
          WorkflowStep(
            id: 'initial_contact',
            name: 'Contact Initial',
            description: 'Premier contact et collecte des informations de base',
            order: 1,
            isRequired: true,
            estimatedDuration: 15,
          ),
          WorkflowStep(
            id: 'welcome_call',
            name: 'Appel de Bienvenue',
            description: 'Appel téléphonique de bienvenue dans les 48h',
            order: 2,
            isRequired: true,
            estimatedDuration: 20,
          ),
          WorkflowStep(
            id: 'pastor_meeting',
            name: 'Rencontre avec le Pasteur',
            description: 'Rendez-vous d\'accueil avec le pasteur principal',
            order: 3,
            isRequired: true,
            estimatedDuration: 45,
          ),
          WorkflowStep(
            id: 'intro_class',
            name: 'Classe d\'Introduction',
            description: 'Participation à la classe d\'introduction de l\'église',
            order: 4,
            isRequired: false,
            estimatedDuration: 90,
          ),
          WorkflowStep(
            id: 'small_group_intro',
            name: 'Introduction aux Groupes',
            description: 'Présentation des différents groupes et ministères',
            order: 5,
            isRequired: false,
            estimatedDuration: 30,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        category: 'Accueil',
        color: '#4CAF50',
        icon: 'waving_hand',
      );

      // 2. Workflow Suivi Pastoral
      final pastoralCareWorkflow = WorkflowModel(
        id: 'pastoral_care',
        name: 'Suivi Pastoral',
        description: 'Accompagnement pastoral personnalisé pour les membres ayant des besoins spécifiques',
        steps: [
          WorkflowStep(
            id: 'initial_assessment',
            name: 'Évaluation Initiale',
            description: 'Évaluation des besoins et situation personnelle',
            order: 1,
            isRequired: true,
            estimatedDuration: 60,
          ),
          WorkflowStep(
            id: 'prayer_support',
            name: 'Soutien par la Prière',
            description: 'Mise en place d\'un soutien par la prière',
            order: 2,
            isRequired: true,
            estimatedDuration: 15,
          ),
          WorkflowStep(
            id: 'regular_followup',
            name: 'Suivi Régulier',
            description: 'Contacts réguliers pour accompagnement',
            order: 3,
            isRequired: true,
            estimatedDuration: 30,
          ),
          WorkflowStep(
            id: 'resource_provision',
            name: 'Provision de Ressources',
            description: 'Fourniture de ressources spirituelles ou pratiques',
            order: 4,
            isRequired: false,
            estimatedDuration: 20,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        category: 'Pastoral',
        color: '#9C27B0',
        icon: 'favorite',
      );

      // 3. Workflow Formation Leadership
      final leadershipTrainingWorkflow = WorkflowModel(
        id: 'leadership_training',
        name: 'Formation Leadership',
        description: 'Programme de formation et développement pour les futurs leaders',
        steps: [
          WorkflowStep(
            id: 'leadership_assessment',
            name: 'Évaluation Leadership',
            description: 'Évaluation des dons et aptitudes au leadership',
            order: 1,
            isRequired: true,
            estimatedDuration: 90,
          ),
          WorkflowStep(
            id: 'mentoring_setup',
            name: 'Mise en Place Mentorat',
            description: 'Attribution d\'un mentor expérimenté',
            order: 2,
            isRequired: true,
            estimatedDuration: 30,
          ),
          WorkflowStep(
            id: 'leadership_course',
            name: 'Cours de Leadership',
            description: 'Participation au cours de formation leadership',
            order: 3,
            isRequired: true,
            estimatedDuration: 480, // 8 heures réparties
          ),
          WorkflowStep(
            id: 'practical_application',
            name: 'Application Pratique',
            description: 'Mise en pratique dans un ministère supervisé',
            order: 4,
            isRequired: true,
            estimatedDuration: 120,
          ),
          WorkflowStep(
            id: 'leadership_evaluation',
            name: 'Évaluation Finale',
            description: 'Évaluation des compétences acquises',
            order: 5,
            isRequired: true,
            estimatedDuration: 60,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        category: 'Formation',
        color: '#FF9800',
        icon: 'school',
      );

      // 4. Workflow Visite Malade
      final sickVisitWorkflow = WorkflowModel(
        id: 'sick_visit',
        name: 'Visite aux Malades',
        description: 'Protocole de visite et soutien aux membres malades ou hospitalisés',
        steps: [
          WorkflowStep(
            id: 'notification_received',
            name: 'Réception Notification',
            description: 'Réception et enregistrement de l\'information',
            order: 1,
            isRequired: true,
            estimatedDuration: 5,
          ),
          WorkflowStep(
            id: 'initial_contact',
            name: 'Contact Initial',
            description: 'Premier contact avec la famille ou le malade',
            order: 2,
            isRequired: true,
            estimatedDuration: 15,
          ),
          WorkflowStep(
            id: 'visit_planning',
            name: 'Planification Visite',
            description: 'Organisation de la visite (lieu, horaire, participants)',
            order: 3,
            isRequired: true,
            estimatedDuration: 10,
          ),
          WorkflowStep(
            id: 'visit_execution',
            name: 'Réalisation Visite',
            description: 'Visite effective avec prière et encouragement',
            order: 4,
            isRequired: true,
            estimatedDuration: 45,
          ),
          WorkflowStep(
            id: 'followup_support',
            name: 'Suivi Continu',
            description: 'Suivi régulier selon l\'évolution de la situation',
            order: 5,
            isRequired: false,
            estimatedDuration: 20,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        category: 'Pastoral',
        color: '#f44336',
        icon: 'healing',
      );

      // 5. Workflow Préparation Baptême
      final baptismPrepWorkflow = WorkflowModel(
        id: 'baptism_preparation',
        name: 'Préparation au Baptême',
        description: 'Processus de préparation et accompagnement vers le baptême',
        steps: [
          WorkflowStep(
            id: 'declaration_intent',
            name: 'Déclaration d\'Intention',
            description: 'Manifestation du désir d\'être baptisé',
            order: 1,
            isRequired: true,
            estimatedDuration: 15,
          ),
          WorkflowStep(
            id: 'testimony_sharing',
            name: 'Partage de Témoignage',
            description: 'Partage du témoignage de foi personnel',
            order: 2,
            isRequired: true,
            estimatedDuration: 30,
          ),
          WorkflowStep(
            id: 'baptism_class',
            name: 'Classe de Baptême',
            description: 'Participation à la classe de préparation au baptême',
            order: 3,
            isRequired: true,
            estimatedDuration: 120,
          ),
          WorkflowStep(
            id: 'pastor_interview',
            name: 'Entretien Pastoral',
            description: 'Entretien final avec le pasteur',
            order: 4,
            isRequired: true,
            estimatedDuration: 45,
          ),
          WorkflowStep(
            id: 'baptism_scheduling',
            name: 'Planification Baptême',
            description: 'Programmation de la cérémonie de baptême',
            order: 5,
            isRequired: true,
            estimatedDuration: 10,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        category: 'Sacrements',
        color: '#2196F3',
        icon: 'water_drop',
      );

      // Ajouter tous les workflows au batch
      final workflows = [
        newMemberWorkflow,
        pastoralCareWorkflow,
        leadershipTrainingWorkflow,
        sickVisitWorkflow,
        baptismPrepWorkflow,
      ];

      for (final workflow in workflows) {
        final docRef = _firestore.collection(workflowsCollection).doc();
        final workflowWithId = WorkflowModel(
          id: docRef.id,
          name: workflow.name,
          description: workflow.description,
          steps: workflow.steps,
          isActive: workflow.isActive,
          createdAt: workflow.createdAt,
          updatedAt: workflow.updatedAt,
          createdBy: workflow.createdBy,
          category: workflow.category,
          color: workflow.color,
          icon: workflow.icon,
        );
        batch.set(docRef, workflowWithId.toFirestore());
      }

      await batch.commit();
      print('✅ ${workflows.length} workflows par défaut créés avec succès');

    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des workflows: $e');
      rethrow;
    }
  }

  /// Crée un workflow personnalisé
  static Future<String> createCustomWorkflow(WorkflowModel workflow) async {
    try {
      final docRef = _firestore.collection(workflowsCollection).doc();
      final workflowWithId = WorkflowModel(
        id: docRef.id,
        name: workflow.name,
        description: workflow.description,
        steps: workflow.steps,
        isActive: workflow.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: workflow.createdBy,
        category: workflow.category,
        color: workflow.color,
        icon: workflow.icon,
      );
      
      await docRef.set(workflowWithId.toFirestore());
      print('✅ Workflow personnalisé "${workflow.name}" créé avec succès');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création du workflow: $e');
      throw Exception('Failed to create workflow: $e');
    }
  }

  /// Vérifie et initialise les workflows si nécessaire
  static Future<void> ensureWorkflowsExist() async {
    try {
      final workflows = await _firestore
          .collection(workflowsCollection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (workflows.docs.isEmpty) {
        await initializeDefaultWorkflows();
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification des workflows: $e');
    }
  }
}