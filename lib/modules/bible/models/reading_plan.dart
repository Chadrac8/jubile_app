class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final String category;
  final int totalDays;
  final int estimatedReadingTime; // en minutes
  final String difficulty; // beginner, intermediate, advanced
  final List<ReadingPlanDay> days;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isPopular;

  ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.totalDays,
    required this.estimatedReadingTime,
    required this.difficulty,
    required this.days,
    this.imageUrl,
    required this.createdAt,
    this.isPopular = false,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      totalDays: json['totalDays'],
      estimatedReadingTime: json['estimatedReadingTime'],
      difficulty: json['difficulty'],
      days: (json['days'] as List).map((d) => ReadingPlanDay.fromJson(d)).toList(),
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isPopular: json['isPopular'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'totalDays': totalDays,
      'estimatedReadingTime': estimatedReadingTime,
      'difficulty': difficulty,
      'days': days.map((d) => d.toJson()).toList(),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isPopular': isPopular,
    };
  }
}

class ReadingPlanDay {
  final int day;
  final String title;
  final List<BibleReference> readings;
  final String? reflection;
  final String? prayer;

  ReadingPlanDay({
    required this.day,
    required this.title,
    required this.readings,
    this.reflection,
    this.prayer,
  });

  factory ReadingPlanDay.fromJson(Map<String, dynamic> json) {
    return ReadingPlanDay(
      day: json['day'],
      title: json['title'],
      readings: (json['readings'] as List).map((r) => BibleReference.fromJson(r)).toList(),
      reflection: json['reflection'],
      prayer: json['prayer']);
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'readings': readings.map((r) => r.toJson()).toList(),
      'reflection': reflection,
      'prayer': prayer,
    };
  }
}

class BibleReference {
  final String book;
  final int? chapter;
  final int? startVerse;
  final int? endVerse;
  final int? endChapter;

  BibleReference({
    required this.book,
    this.chapter,
    this.startVerse,
    this.endVerse,
    this.endChapter,
  });

  factory BibleReference.fromJson(Map<String, dynamic> json) {
    return BibleReference(
      book: json['book'],
      chapter: json['chapter'],
      startVerse: json['startVerse'],
      endVerse: json['endVerse'],
      endChapter: json['endChapter']);
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'endChapter': endChapter,
    };
  }

  String get displayText {
    if (chapter == null) return book;
    
    if (endChapter != null && endChapter != chapter) {
      return '$book $chapter-$endChapter';
    }
    
    if (startVerse != null && endVerse != null) {
      return '$book $chapter:$startVerse-$endVerse';
    }
    
    if (startVerse != null) {
      return '$book $chapter:$startVerse';
    }
    
    return '$book $chapter';
  }
}

class UserReadingProgress {
  final String planId;
  final DateTime startDate;
  final int currentDay;
  final Set<int> completedDays;
  final DateTime? lastReadDate;
  final bool isCompleted;
  final Map<int, String> dayNotes; // notes par jour

  UserReadingProgress({
    required this.planId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    this.lastReadDate,
    this.isCompleted = false,
    this.dayNotes = const {},
  });

  factory UserReadingProgress.fromJson(Map<String, dynamic> json) {
    return UserReadingProgress(
      planId: json['planId'],
      startDate: DateTime.parse(json['startDate']),
      currentDay: json['currentDay'],
      completedDays: Set<int>.from(json['completedDays']),
      lastReadDate: json['lastReadDate'] != null ? DateTime.parse(json['lastReadDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      dayNotes: Map<int, String>.from(json['dayNotes'] ?? {}));
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'currentDay': currentDay,
      'completedDays': completedDays.toList(),
      'lastReadDate': lastReadDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'dayNotes': dayNotes,
    };
  }

  double get progressPercentage {
    return completedDays.length / currentDay.clamp(1, double.infinity);
  }

  UserReadingProgress copyWith({
    String? planId,
    DateTime? startDate,
    int? currentDay,
    Set<int>? completedDays,
    DateTime? lastReadDate,
    bool? isCompleted,
    Map<int, String>? dayNotes,
  }) {
    return UserReadingProgress(
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      isCompleted: isCompleted ?? this.isCompleted,
      dayNotes: dayNotes ?? this.dayNotes);
  }
}
