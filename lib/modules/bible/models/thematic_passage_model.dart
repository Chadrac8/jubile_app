import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modèle représentant un passage biblique thématique
class ThematicPassage {
  final String id;
  final String reference; // Ex: "Jean 3:16"
  final String book;
  final int chapter;
  final int startVerse;
  final int? endVerse; // null si un seul verset
  final String text;
  final String theme;
  final String description;
  final List<String> tags;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;

  ThematicPassage({
    required this.id,
    required this.reference,
    required this.book,
    required this.chapter,
    required this.startVerse,
    this.endVerse,
    required this.text,
    required this.theme,
    required this.description,
    required this.tags,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'book': book,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'text': text,
      'theme': theme,
      'description': description,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  static ThematicPassage fromJson(Map<String, dynamic> json) {
    return ThematicPassage(
      id: json['id'] as String,
      reference: json['reference'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      startVerse: json['startVerse'] as int,
      endVerse: json['endVerse'] as int?,
      text: json['text'] as String,
      theme: json['theme'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] as List),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String);
  }

  String get fullReference {
    if (endVerse != null && endVerse != startVerse) {
      return '$book $chapter:$startVerse-$endVerse';
    }
    return '$book $chapter:$startVerse';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThematicPassage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Modèle représentant un thème biblique avec ses passages
class BiblicalTheme {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final List<ThematicPassage> passages;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final bool isPublic;

  BiblicalTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.passages,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.isPublic = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'passageIds': passages.map((p) => p.id).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isPublic': isPublic,
    };
  }

  static BiblicalTheme fromJson(Map<String, dynamic> json, List<ThematicPassage> passages) {
    return BiblicalTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      color: Color(json['color'] as int),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?),
      passages: passages,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      isPublic: json['isPublic'] as bool? ?? true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiblicalTheme &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}


