class BibleStudy {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int estimatedDuration; // en minutes
  final String imageUrl;
  final List<BibleStudyLesson> lessons;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPopular;
  final bool isActive;
  final String author;
  final List<String> tags;

  const BibleStudy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedDuration,
    required this.imageUrl,
    required this.lessons,
    required this.createdAt,
    this.updatedAt,
    this.isPopular = false,
    this.isActive = true,
    required this.author,
    this.tags = const [],
  });

  factory BibleStudy.fromJson(Map<String, dynamic> json) {
    return BibleStudy(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      estimatedDuration: json['estimatedDuration'] as int,
      imageUrl: json['imageUrl'] as String,
      lessons: (json['lessons'] as List)
          .map((lesson) => BibleStudyLesson.fromJson(lesson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isPopular: json['isPopular'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      author: json['author'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'imageUrl': imageUrl,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPopular': isPopular,
      'isActive': isActive,
      'author': author,
      'tags': tags,
    };
  }

  BibleStudy copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? estimatedDuration,
    String? imageUrl,
    List<BibleStudyLesson>? lessons,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPopular,
    bool? isActive,
    String? author,
    List<String>? tags,
  }) {
    return BibleStudy(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      lessons: lessons ?? this.lessons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
      author: author ?? this.author,
      tags: tags ?? this.tags);
  }

  String get displayDifficulty {
    switch (difficulty) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return 'Débutant';
    }
  }

  String get formattedDuration {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}min';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      return minutes > 0 ? '${hours}h${minutes}min' : '${hours}h';
    }
  }
}

class BibleStudyLesson {
  final String id;
  final String title;
  final String content;
  final List<BibleReference> references;
  final List<StudyQuestion> questions;
  final String? reflection;
  final String? prayer;
  final int order;
  final int estimatedDuration; // en minutes
  final List<String> objectives;
  final List<BibleReference> bibleReferences;

  const BibleStudyLesson({
    required this.id,
    required this.title,
    required this.content,
    required this.references,
    required this.questions,
    this.reflection,
    this.prayer,
    required this.order,
    required this.estimatedDuration,
    this.objectives = const [],
    this.bibleReferences = const [],
  });

  factory BibleStudyLesson.fromJson(Map<String, dynamic> json) {
    return BibleStudyLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      references: (json['references'] as List)
          .map((ref) => BibleReference.fromJson(ref))
          .toList(),
      questions: (json['questions'] as List)
          .map((q) => StudyQuestion.fromJson(q))
          .toList(),
      reflection: json['reflection'] as String?,
      prayer: json['prayer'] as String?,
      order: json['order'] as int,
      estimatedDuration: json['estimatedDuration'] as int,
      objectives: List<String>.from(json['objectives'] as List? ?? []),
      bibleReferences: (json['bibleReferences'] as List? ?? [])
          .map((ref) => BibleReference.fromJson(ref))
          .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'references': references.map((ref) => ref.toJson()).toList(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'reflection': reflection,
      'prayer': prayer,
      'order': order,
      'estimatedDuration': estimatedDuration,
      'objectives': objectives,
      'bibleReferences': bibleReferences.map((ref) => ref.toJson()).toList(),
    };
  }

  BibleStudyLesson copyWith({
    String? id,
    String? title,
    String? content,
    List<BibleReference>? references,
    List<StudyQuestion>? questions,
    String? reflection,
    String? prayer,
    int? order,
    int? estimatedDuration,
    List<String>? objectives,
    List<BibleReference>? bibleReferences,
  }) {
    return BibleStudyLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      references: references ?? this.references,
      questions: questions ?? this.questions,
      reflection: reflection ?? this.reflection,
      prayer: prayer ?? this.prayer,
      order: order ?? this.order,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      objectives: objectives ?? this.objectives,
      bibleReferences: bibleReferences ?? this.bibleReferences);
  }
}

class BibleReference {
  final String book;
  final int? chapter;
  final int? startVerse;
  final int? endVerse;
  final String reference;
  final String text;
  final String commentary;

  const BibleReference({
    required this.book,
    this.chapter,
    this.startVerse,
    this.endVerse,
    this.reference = '',
    this.text = '',
    this.commentary = '',
  });

  factory BibleReference.fromJson(Map<String, dynamic> json) {
    return BibleReference(
      book: json['book'] as String,
      chapter: json['chapter'] as int?,
      startVerse: json['startVerse'] as int?,
      endVerse: json['endVerse'] as int?,
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
      commentary: json['commentary'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'reference': reference,
      'text': text,
      'commentary': commentary,
    };
  }

  String get displayText {
    if (chapter == null) return book;
    
    String result = '$book $chapter';
    
    if (startVerse != null) {
      if (endVerse != null && endVerse != startVerse) {
        result += ':$startVerse-$endVerse';
      } else {
        result += ':$startVerse';
      }
    }
    
    return result;
  }
}

class StudyQuestion {
  final String id;
  final String question;
  final String type; // 'reflection', 'multiple_choice', 'open_ended'
  final List<String>? options; // pour les questions à choix multiples
  final String? correctAnswer; // pour les questions à choix multiples
  final String? hint;
  final List<String> hints;

  const StudyQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.correctAnswer,
    this.hint,
    this.hints = const [],
  });

  factory StudyQuestion.fromJson(Map<String, dynamic> json) {
    return StudyQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      type: json['type'] as String,
      options: json['options'] != null 
          ? List<String>.from(json['options'] as List)
          : null,
      correctAnswer: json['correctAnswer'] as String?,
      hint: json['hint'] as String?,
      hints: List<String>.from(json['hints'] as List? ?? []));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'hint': hint,
      'hints': hints,
    };
  }

  StudyQuestion copyWith({
    String? id,
    String? question,
    String? type,
    List<String>? options,
    String? correctAnswer,
    String? hint,
    List<String>? hints,
  }) {
    return StudyQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      hint: hint ?? this.hint,
      hints: hints ?? this.hints);
  }
}

class UserStudyProgress {
  final String studyId;
  final String userId;
  final int currentLessonIndex;
  final List<String> completedLessons;
  final Map<String, dynamic> answers; // réponses aux questions
  final DateTime startedAt;
  final DateTime? completedAt;
  final double progressPercentage;

  const UserStudyProgress({
    required this.studyId,
    required this.userId,
    required this.currentLessonIndex,
    required this.completedLessons,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    required this.progressPercentage,
  });

  factory UserStudyProgress.fromJson(Map<String, dynamic> json) {
    return UserStudyProgress(
      studyId: json['studyId'] as String,
      userId: json['userId'] as String,
      currentLessonIndex: json['currentLessonIndex'] as int,
      completedLessons: List<String>.from(json['completedLessons'] as List),
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      progressPercentage: (json['progressPercentage'] as num).toDouble());
  }

  Map<String, dynamic> toJson() {
    return {
      'studyId': studyId,
      'userId': userId,
      'currentLessonIndex': currentLessonIndex,
      'completedLessons': completedLessons,
      'answers': answers,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'progressPercentage': progressPercentage,
    };
  }

  UserStudyProgress copyWith({
    String? studyId,
    String? userId,
    int? currentLessonIndex,
    List<String>? completedLessons,
    Map<String, dynamic>? answers,
    DateTime? startedAt,
    DateTime? completedAt,
    double? progressPercentage,
  }) {
    return UserStudyProgress(
      studyId: studyId ?? this.studyId,
      userId: userId ?? this.userId,
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      completedLessons: completedLessons ?? this.completedLessons,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      progressPercentage: progressPercentage ?? this.progressPercentage);
  }

  bool get isCompleted => completedAt != null;
  
  String get statusText {
    if (isCompleted) return 'Terminée';
    if (currentLessonIndex == 0) return 'Non commencée';
    return 'En cours';
  }
}
