/// Modèle pour représenter une personne
class Person {
  final String? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final DateTime? birthDate;
  final String? address;
  final String? profileImageUrl;
  final List<String> roles;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Person({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.birthDate,
    this.address,
    this.profileImageUrl,
    this.roles = const [],
    this.customFields = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Nom complet de la personne
  String get fullName => '$firstName $lastName';

  /// Âge calculé à partir de la date de naissance
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      return age - 1;
    }
    return age;
  }

  /// Vérifier si la personne a un rôle spécifique
  bool hasRole(String role) {
    return roles.contains(role);
  }

  /// Obtenir la valeur d'un champ personnalisé
  T? getCustomField<T>(String fieldName) {
    return customFields[fieldName] as T?;
  }

  /// Créer une copie avec des modifications
  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? address,
    String? profileImageUrl,
    List<String>? roles,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      roles: roles ?? this.roles,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'profileImageUrl': profileImageUrl,
      'roles': roles,
      'customFields': customFields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Créer depuis Map de Firestore
  factory Person.fromMap(Map<String, dynamic> map, String id) {
    return Person(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'],
      phone: map['phone'],
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      roles: List<String>.from(map['roles'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  String toString() {
    return 'Person(id: $id, fullName: $fullName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}