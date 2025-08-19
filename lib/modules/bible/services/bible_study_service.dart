import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_study.dart';

class BibleStudyService {
  static const String _progressKey = 'bible_studies_progress';
  static const String _assetPath = 'assets/bible/bible_studies.json';

  // Charger les études bibliques disponibles
  static Future<List<BibleStudy>> getAvailableStudies() async {
    try {
      // Essayer de charger depuis les assets
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      final studies = jsonList
          .map((json) => BibleStudy.fromJson(json))
          .where((study) => study.isActive)
          .toList();
      
      // Trier par popularité puis par date de création
      studies.sort((a, b) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return studies;
    } catch (e) {
      // Si pas d'asset, retourner les études par défaut
      return _getDefaultStudies();
    }
  }

  // Obtenir les études populaires
  static Future<List<BibleStudy>> getPopularStudies({int limit = 3}) async {
    final studies = await getAvailableStudies();
    return studies.where((study) => study.isPopular).take(limit).toList();
  }

  // Obtenir les études par catégorie
  static Future<List<BibleStudy>> getStudiesByCategory(String category) async {
    final studies = await getAvailableStudies();
    if (category == 'Tous') return studies;
    return studies.where((study) => study.category == category).toList();
  }

  // Rechercher des études
  static Future<List<BibleStudy>> searchStudies(String query) async {
    if (query.isEmpty) return getAvailableStudies();
    
    final studies = await getAvailableStudies();
    final lowerQuery = query.toLowerCase();
    
    return studies.where((study) {
      return study.title.toLowerCase().contains(lowerQuery) ||
             study.description.toLowerCase().contains(lowerQuery) ||
             study.author.toLowerCase().contains(lowerQuery) ||
             study.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Obtenir une étude spécifique
  static Future<BibleStudy?> getStudyById(String id) async {
    final studies = await getAvailableStudies();
    try {
      return studies.firstWhere((study) => study.id == id);
    } catch (e) {
      return null;
    }
  }

  // Gestion du progrès utilisateur
  static Future<List<UserStudyProgress>> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey) ?? '[]';
    final List<dynamic> progressList = jsonDecode(progressJson);
    
    return progressList
        .map((json) => UserStudyProgress.fromJson(json))
        .toList();
  }

  static Future<UserStudyProgress?> getStudyProgress(String studyId) async {
    final allProgress = await getUserProgress();
    try {
      return allProgress.firstWhere((progress) => progress.studyId == studyId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveStudyProgress(UserStudyProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final allProgress = await getUserProgress();
    
    // Mettre à jour ou ajouter le progrès
    final index = allProgress.indexWhere((p) => p.studyId == progress.studyId);
    if (index >= 0) {
      allProgress[index] = progress;
    } else {
      allProgress.add(progress);
    }
    
    final progressJson = jsonEncode(
      allProgress.map((p) => p.toJson()).toList());
    await prefs.setString(_progressKey, progressJson);
  }

  static Future<void> startStudy(String studyId) async {
    final userId = 'current_user'; // À remplacer par l'ID utilisateur réel
    
    final progress = UserStudyProgress(
      studyId: studyId,
      userId: userId,
      currentLessonIndex: 0,
      completedLessons: [],
      answers: {},
      startedAt: DateTime.now(),
      progressPercentage: 0.0);
    
    await saveStudyProgress(progress);
  }

  static Future<void> completeLesson(String studyId, String lessonId, Map<String, dynamic> answers) async {
    final currentProgress = await getStudyProgress(studyId);
    if (currentProgress == null) return;
    
    final study = await getStudyById(studyId);
    if (study == null) return;
    
    final updatedCompletedLessons = List<String>.from(currentProgress.completedLessons);
    if (!updatedCompletedLessons.contains(lessonId)) {
      updatedCompletedLessons.add(lessonId);
    }
    
    final newAnswers = Map<String, dynamic>.from(currentProgress.answers);
    newAnswers.addAll(answers);
    
    final progressPercentage = (updatedCompletedLessons.length / study.lessons.length) * 100;
    final isCompleted = updatedCompletedLessons.length >= study.lessons.length;
    
    final updatedProgress = currentProgress.copyWith(
      currentLessonIndex: currentProgress.currentLessonIndex + 1,
      completedLessons: updatedCompletedLessons,
      answers: newAnswers,
      progressPercentage: progressPercentage,
      completedAt: isCompleted ? DateTime.now() : null);
    
    await saveStudyProgress(updatedProgress);
  }

  // Obtenir les études en cours
  static Future<List<BibleStudy>> getActiveStudies() async {
    final allProgress = await getUserProgress();
    final activeProgress = allProgress.where((p) => !p.isCompleted).toList();
    
    final studies = <BibleStudy>[];
    for (final progress in activeProgress) {
      final study = await getStudyById(progress.studyId);
      if (study != null) {
        studies.add(study);
      }
    }
    
    return studies;
  }

  // Obtenir les études complétées
  static Future<List<BibleStudy>> getCompletedStudies() async {
    final allProgress = await getUserProgress();
    final completedProgress = allProgress.where((p) => p.isCompleted).toList();
    
    final studies = <BibleStudy>[];
    for (final progress in completedProgress) {
      final study = await getStudyById(progress.studyId);
      if (study != null) {
        studies.add(study);
      }
    }
    
    return studies;
  }

  // Administration - Sauvegarder une étude
  static Future<void> saveStudy(BibleStudy study) async {
    // TODO: Implémenter la sauvegarde réelle (Firestore, etc.)
    // Pour l'instant, simulation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Administration - Supprimer une étude
  static Future<void> deleteStudy(String studyId) async {
    // TODO: Implémenter la suppression réelle
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Obtenir les statistiques d'usage
  static Future<Map<String, dynamic>> getUsageStatistics() async {
    final allProgress = await getUserProgress();
    final studies = await getAvailableStudies();
    
    return {
      'totalStudies': studies.length,
      'activeStudies': allProgress.where((p) => !p.isCompleted).length,
      'completedStudies': allProgress.where((p) => p.isCompleted).length,
      'totalUsers': 1, // Simulé pour un utilisateur
      'averageCompletion': allProgress.isEmpty 
          ? 0.0 
          : allProgress.map((p) => p.progressPercentage).reduce((a, b) => a + b) / allProgress.length,
    };
  }

  // Études par défaut
  static List<BibleStudy> _getDefaultStudies() {
    return [
      BibleStudy(
        id: 'study_1',
        title: 'Les Paraboles de Jésus',
        description: 'Découvrez les enseignements profonds à travers les paraboles du Christ',
        category: 'Nouveau Testament',
        difficulty: 'beginner',
        estimatedDuration: 120,
        imageUrl: 'assets/illustrations/paraboles.png',
        author: 'Dr. Marie Dubois',
        tags: ['paraboles', 'enseignement', 'jésus'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isPopular: true,
        lessons: [
          BibleStudyLesson(
            id: 'lesson_1_1',
            title: 'La Parabole du Semeur',
            content: 'Cette parabole nous enseigne sur les différents types de cœurs qui reçoivent la Parole de Dieu.',
            references: [
              BibleReference(book: 'Matthieu', chapter: 13, startVerse: 1, endVerse: 23),
              BibleReference(book: 'Marc', chapter: 4, startVerse: 1, endVerse: 20),
            ],
            questions: [
              StudyQuestion(
                id: 'q1_1',
                question: 'Quels sont les quatre types de terrain mentionnés dans cette parabole ?',
                type: 'open_ended'),
              StudyQuestion(
                id: 'q1_2',
                question: 'Que représente la semence dans cette parabole ?',
                type: 'multiple_choice',
                options: ['L\'argent', 'La Parole de Dieu', 'Les bonnes œuvres', 'La prière'],
                correctAnswer: 'La Parole de Dieu'),
            ],
            reflection: 'Réfléchissez à quel type de terrain votre cœur représente-t-il actuellement.',
            prayer: 'Seigneur, prépare mon cœur à recevoir ta Parole avec joie et à porter du fruit.',
            order: 1,
            estimatedDuration: 30),
          BibleStudyLesson(
            id: 'lesson_1_2',
            title: 'La Parabole de la Brebis Perdue',
            content: 'Cette parabole révèle l\'amour infini de Dieu pour chaque âme perdue.',
            references: [
              BibleReference(book: 'Luc', chapter: 15, startVerse: 1, endVerse: 7),
              BibleReference(book: 'Matthieu', chapter: 18, startVerse: 10, endVerse: 14),
            ],
            questions: [
              StudyQuestion(
                id: 'q2_1',
                question: 'Que fait le berger quand il découvre qu\'une brebis manque ?',
                type: 'open_ended'),
            ],
            reflection: 'Dieu nous cherche avec la même passion quand nous nous éloignons de lui.',
            prayer: 'Merci Seigneur de ne jamais m\'abandonner, même quand je m\'égare.',
            order: 2,
            estimatedDuration: 25),
        ]),
      BibleStudy(
        id: 'study_2',
        title: 'Les Héros de la Foi',
        description: 'Étudiez les grandes figures bibliques qui ont marqué l\'histoire du salut',
        category: 'Ancien Testament',
        difficulty: 'intermediate',
        estimatedDuration: 180,
        imageUrl: 'assets/illustrations/heroes_foi.png',
        author: 'Pasteur Jean Martin',
        tags: ['foi', 'héros', 'ancien testament'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isPopular: true,
        lessons: [
          BibleStudyLesson(
            id: 'lesson_2_1',
            title: 'Abraham, le Père de la Foi',
            content: 'Abraham nous enseigne ce que signifie vraiment faire confiance à Dieu.',
            references: [
              BibleReference(book: 'Genèse', chapter: 12, startVerse: 1, endVerse: 9),
              BibleReference(book: 'Hébreux', chapter: 11, startVerse: 8, endVerse: 19),
            ],
            questions: [
              StudyQuestion(
                id: 'q3_1',
                question: 'Quel âge avait Abraham quand Dieu l\'a appelé ?',
                type: 'multiple_choice',
                options: ['65 ans', '75 ans', '85 ans', '95 ans'],
                correctAnswer: '75 ans'),
            ],
            reflection: 'Êtes-vous prêt à obéir à Dieu même sans voir le chemin complet ?',
            prayer: 'Seigneur, donne-moi la foi d\'Abraham pour te suivre où que tu m\'appelles.',
            order: 1,
            estimatedDuration: 45),
        ]),
      BibleStudy(
        id: 'study_3',
        title: 'Les Fruits de l\'Esprit',
        description: 'Explorez les neuf fruits de l\'Esprit et leur application pratique',
        category: 'Spiritualité',
        difficulty: 'beginner',
        estimatedDuration: 90,
        imageUrl: 'assets/illustrations/fruits_esprit.png',
        author: 'Pasteure Sarah Lecomte',
        tags: ['esprit saint', 'fruits', 'caractère'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isPopular: false,
        lessons: [
          BibleStudyLesson(
            id: 'lesson_3_1',
            title: 'L\'Amour - Le Premier Fruit',
            content: 'L\'amour est le fondement de tous les autres fruits de l\'Esprit.',
            references: [
              BibleReference(book: 'Galates', chapter: 5, startVerse: 22, endVerse: 23),
              BibleReference(book: '1 Corinthiens', chapter: 13, startVerse: 1, endVerse: 13),
            ],
            questions: [
              StudyQuestion(
                id: 'q4_1',
                question: 'Comment peut-on cultiver l\'amour dans notre vie quotidienne ?',
                type: 'reflection'),
            ],
            reflection: 'L\'amour véritable se manifeste dans nos actions, pas seulement nos paroles.',
            prayer: 'Seigneur, remplis mon cœur de ton amour pour que je puisse l\'offrir aux autres.',
            order: 1,
            estimatedDuration: 30),
        ]),
    ];
  }

  // Marquer une leçon comme terminée
  static Future<void> markLessonComplete(String studyId, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);
    
    Map<String, dynamic> allProgress = {};
    if (progressJson != null) {
      allProgress = jsonDecode(progressJson);
    }
    
    // Initialiser le progrès de l'étude si nécessaire
    if (!allProgress.containsKey(studyId)) {
      allProgress[studyId] = {
        'studyId': studyId,
        'userId': 'current_user',
        'startedAt': DateTime.now().toIso8601String(),
        'lastAccessedAt': DateTime.now().toIso8601String(),
        'completedLessons': [],
        'currentLessonId': lessonId,
        'notes': {},
        'isCompleted': false,
      };
    }
    
    final studyProgress = allProgress[studyId];
    final completedLessons = List<String>.from(studyProgress['completedLessons'] ?? []);
    
    // Ajouter la leçon si pas déjà terminée
    if (!completedLessons.contains(lessonId)) {
      completedLessons.add(lessonId);
      studyProgress['completedLessons'] = completedLessons;
      studyProgress['lastAccessedAt'] = DateTime.now().toIso8601String();
      
      // Vérifier si l'étude est terminée
      final study = await getStudyById(studyId);
      if (study != null && completedLessons.length == study.lessons.length) {
        studyProgress['isCompleted'] = true;
        studyProgress['completedAt'] = DateTime.now().toIso8601String();
      }
      
      allProgress[studyId] = studyProgress;
      await prefs.setString(_progressKey, jsonEncode(allProgress));
    }
  }
}
