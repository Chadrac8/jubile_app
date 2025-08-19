import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_plan.dart';

class ReadingPlanService {
  static const String _userProgressKey = 'user_reading_progress';
  static const String _activePlanKey = 'active_reading_plan';
  
  static List<ReadingPlan>? _cachedPlans;
  static Map<String, UserReadingProgress>? _cachedProgress;

  /// Charge tous les plans de lecture disponibles
  static Future<List<ReadingPlan>> getAvailablePlans() async {
    if (_cachedPlans != null) return _cachedPlans!;
    
    try {
      final String data = await rootBundle.loadString('assets/bible/reading_plans.json');
      final List<dynamic> jsonData = json.decode(data);
      _cachedPlans = jsonData.map((plan) => ReadingPlan.fromJson(plan)).toList();
      return _cachedPlans!;
    } catch (e) {
      // Si le fichier n'existe pas, retourner les plans par défaut
      return _getDefaultPlans();
    }
  }

  /// Plans par défaut si le fichier JSON n'existe pas
  static List<ReadingPlan> _getDefaultPlans() {
    return [
      ReadingPlan(
        id: 'bible_365',
        name: 'Bible en 1 an',
        description: 'Lisez toute la Bible en 365 jours avec ce plan structuré qui combine Ancien et Nouveau Testament.',
        category: 'Classique',
        totalDays: 365,
        estimatedReadingTime: 15,
        difficulty: 'beginner',
        days: _generateBible365Days(),
        createdAt: DateTime.now(),
        isPopular: true),
      ReadingPlan(
        id: 'new_testament_90',
        name: 'Nouveau Testament en 90 jours',
        description: 'Un parcours intensif à travers le Nouveau Testament en 3 mois.',
        category: 'Nouveau Testament',
        totalDays: 90,
        estimatedReadingTime: 20,
        difficulty: 'intermediate',
        days: _generateNewTestament90Days(),
        createdAt: DateTime.now(),
        isPopular: true),
      ReadingPlan(
        id: 'psalms_30',
        name: 'Psaumes en 30 jours',
        description: 'Découvrez la richesse des Psaumes avec 5 psaumes par jour.',
        category: 'Psaumes',
        totalDays: 30,
        estimatedReadingTime: 10,
        difficulty: 'beginner',
        days: _generatePsalms30Days(),
        createdAt: DateTime.now(),
        isPopular: false),
      ReadingPlan(
        id: 'gospels_28',
        name: 'Les 4 Évangiles en 28 jours',
        description: 'Explorez la vie de Jésus à travers les quatre évangiles.',
        category: 'Évangiles',
        totalDays: 28,
        estimatedReadingTime: 12,
        difficulty: 'beginner',
        days: _generateGospels28Days(),
        createdAt: DateTime.now(),
        isPopular: true),
      ReadingPlan(
        id: 'proverbs_31',
        name: 'Proverbes en 31 jours',
        description: 'Un chapitre de Proverbes par jour pour acquérir la sagesse.',
        category: 'Sagesse',
        totalDays: 31,
        estimatedReadingTime: 5,
        difficulty: 'beginner',
        days: _generateProverbs31Days(),
        createdAt: DateTime.now(),
        isPopular: true),
    ];
  }

  /// Génère les jours pour le plan Bible en 1 an
  static List<ReadingPlanDay> _generateBible365Days() {
    final List<ReadingPlanDay> days = [];
    
    // Plan simplifié - dans une vraie implémentation, ceci serait plus détaillé
    for (int i = 1; i <= 365; i++) {
      days.add(ReadingPlanDay(
        day: i,
        title: 'Jour $i',
        readings: [
          BibleReference(book: 'Genèse', chapter: ((i - 1) % 50) + 1),
          BibleReference(book: 'Matthieu', chapter: ((i - 1) % 28) + 1),
        ],
        reflection: 'Réflexion du jour $i sur la Parole de Dieu.'));
    }
    
    return days;
  }

  /// Génère les jours pour le Nouveau Testament en 90 jours
  static List<ReadingPlanDay> _generateNewTestament90Days() {
    final List<ReadingPlanDay> days = [];
    final newTestamentBooks = [
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', 
      '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens',
      '1 Timothée', '2 Timothée', 'Tite', 'Philémon', 'Hébreux',
      'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
      'Jude', 'Apocalypse'
    ];
    
    for (int i = 1; i <= 90; i++) {
      days.add(ReadingPlanDay(
        day: i,
        title: 'Jour $i',
        readings: [
          BibleReference(
            book: newTestamentBooks[(i - 1) % newTestamentBooks.length],
            chapter: ((i - 1) ~/ newTestamentBooks.length) + 1),
        ],
        reflection: 'Méditation sur le Nouveau Testament - Jour $i'));
    }
    
    return days;
  }

  /// Génère les jours pour les Psaumes en 30 jours
  static List<ReadingPlanDay> _generatePsalms30Days() {
    final List<ReadingPlanDay> days = [];
    
    for (int i = 1; i <= 30; i++) {
      final startPsalm = ((i - 1) * 5) + 1;
      final endPsalm = i * 5;
      
      days.add(ReadingPlanDay(
        day: i,
        title: 'Jour $i - Psaumes $startPsalm-$endPsalm',
        readings: List.generate(5, (index) => 
          BibleReference(book: 'Psaumes', chapter: startPsalm + index)
        ),
        reflection: 'Méditation sur les Psaumes $startPsalm à $endPsalm',
        prayer: 'Prière inspirée des Psaumes du jour'));
    }
    
    return days;
  }

  /// Génère les jours pour les 4 Évangiles en 28 jours
  static List<ReadingPlanDay> _generateGospels28Days() {
    final List<ReadingPlanDay> days = [];
    final gospels = ['Matthieu', 'Marc', 'Luc', 'Jean'];
    
    for (int i = 1; i <= 28; i++) {
      final gospel = gospels[((i - 1) ~/ 7) % 4];
      final chapter = ((i - 1) % 7) + 1;
      
      days.add(ReadingPlanDay(
        day: i,
        title: 'Jour $i - $gospel $chapter',
        readings: [
          BibleReference(book: gospel, chapter: chapter),
        ],
        reflection: 'Réflexion sur la vie de Jésus selon $gospel'));
    }
    
    return days;
  }

  /// Génère les jours pour les Proverbes en 31 jours
  static List<ReadingPlanDay> _generateProverbs31Days() {
    final List<ReadingPlanDay> days = [];
    
    for (int i = 1; i <= 31; i++) {
      days.add(ReadingPlanDay(
        day: i,
        title: 'Jour $i - Proverbes $i',
        readings: [
          BibleReference(book: 'Proverbes', chapter: i),
        ],
        reflection: 'Sagesse pratique pour la vie quotidienne',
        prayer: 'Prière pour recevoir la sagesse divine'));
    }
    
    return days;
  }

  /// Obtient le progrès de l'utilisateur pour tous les plans
  static Future<Map<String, UserReadingProgress>> getUserProgress() async {
    if (_cachedProgress != null) return _cachedProgress!;
    
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_userProgressKey);
    
    if (progressJson != null) {
      final Map<String, dynamic> progressMap = json.decode(progressJson);
      _cachedProgress = progressMap.map(
        (key, value) => MapEntry(key, UserReadingProgress.fromJson(value))
      );
    } else {
      _cachedProgress = {};
    }
    
    return _cachedProgress!;
  }

  /// Sauvegarde le progrès de l'utilisateur
  static Future<void> saveUserProgress(Map<String, UserReadingProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = json.encode(
      progress.map((key, value) => MapEntry(key, value.toJson()))
    );
    await prefs.setString(_userProgressKey, progressJson);
    _cachedProgress = progress;
  }

  /// Commence un nouveau plan de lecture
  static Future<void> startReadingPlan(String planId) async {
    final progress = await getUserProgress();
    final newProgress = UserReadingProgress(
      planId: planId,
      startDate: DateTime.now(),
      currentDay: 1,
      completedDays: {});
    
    progress[planId] = newProgress;
    await saveUserProgress(progress);
    
    // Définir comme plan actif
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePlanKey, planId);
  }

  /// Marque un jour comme terminé
  static Future<void> completeDayReading(String planId, int day, {String? note}) async {
    final progress = await getUserProgress();
    final planProgress = progress[planId];
    
    if (planProgress != null) {
      final updatedCompletedDays = Set<int>.from(planProgress.completedDays)..add(day);
      final updatedNotes = Map<int, String>.from(planProgress.dayNotes);
      if (note != null && note.isNotEmpty) {
        updatedNotes[day] = note;
      }
      
      final updatedProgress = planProgress.copyWith(
        completedDays: updatedCompletedDays,
        currentDay: day + 1,
        lastReadDate: DateTime.now(),
        dayNotes: updatedNotes);
      
      progress[planId] = updatedProgress;
      await saveUserProgress(progress);
    }
  }

  /// Obtient le plan de lecture actif
  static Future<String?> getActivePlanId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activePlanKey);
  }

  /// Obtient le plan de lecture actif avec ses détails
  static Future<ReadingPlan?> getActivePlan() async {
    final activePlanId = await getActivePlanId();
    if (activePlanId == null) return null;
    
    final plans = await getAvailablePlans();
    return plans.firstWhere(
      (plan) => plan.id == activePlanId,
      orElse: () => plans.first);
  }

  /// Obtient le progrès pour un plan spécifique
  static Future<UserReadingProgress?> getPlanProgress(String planId) async {
    final progress = await getUserProgress();
    return progress[planId];
  }

  /// Filtre les plans par catégorie
  static Future<List<ReadingPlan>> getPlansByCategory(String category) async {
    final plans = await getAvailablePlans();
    if (category == 'Tous') return plans;
    return plans.where((plan) => plan.category == category).toList();
  }

  /// Obtient les catégories disponibles
  static Future<List<String>> getCategories() async {
    final plans = await getAvailablePlans();
    final categories = plans.map((plan) => plan.category).toSet().toList();
    categories.insert(0, 'Tous');
    return categories;
  }

  /// Obtient les plans populaires
  static Future<List<ReadingPlan>> getPopularPlans() async {
    final plans = await getAvailablePlans();
    return plans.where((plan) => plan.isPopular).toList();
  }

  /// Recherche dans les plans
  static Future<List<ReadingPlan>> searchPlans(String query) async {
    final plans = await getAvailablePlans();
    if (query.isEmpty) return plans;
    
    final lowerQuery = query.toLowerCase();
    return plans.where((plan) =>
      plan.name.toLowerCase().contains(lowerQuery) ||
      plan.description.toLowerCase().contains(lowerQuery) ||
      plan.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Obtient les statistiques d'usage
  static Future<Map<String, dynamic>> getUsageStatistics() async {
    final allProgress = await getUserProgress();
    final plans = await getAvailablePlans();
    final progressValues = allProgress.values.toList();
    
    return {
      'totalPlans': plans.length,
      'activePlans': progressValues.where((p) => !p.isCompleted).length,
      'completedPlans': progressValues.where((p) => p.isCompleted).length,
      'totalUsers': 1, // Simulé pour un utilisateur
      'averageCompletion': progressValues.isEmpty 
          ? 0.0 
          : progressValues.map((p) => p.progressPercentage).reduce((a, b) => a + b) / progressValues.length,
    };
  }

  /// Remet à zéro le cache
  static void clearCache() {
    _cachedPlans = null;
    _cachedProgress = null;
  }
}
