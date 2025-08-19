import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modèle représentant une catégorie de chant
class SongCategory {
  final String? id;
  final String name;
  final String description;
  final String? icon;
  final Color color;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SongCategory({
    this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color = Colors.blue,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer une SongCategory à partir des données Firestore
  factory SongCategory.fromMap(Map<String, dynamic> map, String id) {
    return SongCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'],
      color: Color(map['color'] ?? Colors.blue.value),
      sortOrder: map['sortOrder'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir la SongCategory en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color.value,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Créer une copie de la SongCategory avec des modifications
  SongCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    Color? color,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SongCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SongCategory(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Catégories prédéfinies pour les chants
class DefaultSongCategories {
  static List<SongCategory> get defaultCategories => [
    SongCategory(
      name: 'Louange',
      description: 'Chants de louange et d\'adoration',
      icon: 'music_note',
      color: Colors.orange,
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Adoration',
      description: 'Chants d\'adoration et de recueillement',
      icon: 'favorite',
      color: Colors.red,
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Prière',
      description: 'Chants de prière et de méditation',
      icon: 'church',
      color: Colors.purple,
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Évangélisation',
      description: 'Chants d\'évangélisation et témoignage',
      icon: 'share',
      color: Colors.green,
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Noël',
      description: 'Chants de Noël et de l\'Avent',
      icon: 'star',
      color: Colors.red,
      sortOrder: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Pâques',
      description: 'Chants de Pâques et de la Résurrection',
      icon: 'wb_sunny',
      color: Colors.yellow,
      sortOrder: 6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Jeunesse',
      description: 'Chants pour les jeunes et enfants',
      icon: 'child_friendly',
      color: Colors.cyan,
      sortOrder: 7,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SongCategory(
      name: 'Traditionnel',
      description: 'Chants traditionnels et cantiques',
      icon: 'library_music',
      color: Colors.brown,
      sortOrder: 8,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}