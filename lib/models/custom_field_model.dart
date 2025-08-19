import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomFieldType {
  text,
  number,
  date,
  boolean,
  select,
  multiselect,
  phone,
  email,
  url,
}

class CustomFieldModel {
  final String id;
  final String name;
  final String label;
  final CustomFieldType type;
  final bool isRequired;
  final bool isVisible;
  final int order;
  final List<String> options; // Pour les champs select et multiselect
  final String? defaultValue;
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic> validationRules;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  CustomFieldModel({
    required this.id,
    required this.name,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.isVisible = true,
    this.order = 0,
    this.options = const [],
    this.defaultValue,
    this.placeholder,
    this.helpText,
    this.validationRules = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory CustomFieldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomFieldModel(
      id: doc.id,
      name: data['name'] ?? '',
      label: data['label'] ?? '',
      type: CustomFieldType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => CustomFieldType.text,
      ),
      isRequired: data['isRequired'] ?? false,
      isVisible: data['isVisible'] ?? true,
      order: data['order'] ?? 0,
      options: List<String>.from(data['options'] ?? []),
      defaultValue: data['defaultValue'],
      placeholder: data['placeholder'],
      helpText: data['helpText'],
      validationRules: Map<String, dynamic>.from(data['validationRules'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'label': label,
      'type': type.toString().split('.').last,
      'isRequired': isRequired,
      'isVisible': isVisible,
      'order': order,
      'options': options,
      'defaultValue': defaultValue,
      'placeholder': placeholder,
      'helpText': helpText,
      'validationRules': validationRules,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  CustomFieldModel copyWith({
    String? name,
    String? label,
    CustomFieldType? type,
    bool? isRequired,
    bool? isVisible,
    int? order,
    List<String>? options,
    String? defaultValue,
    String? placeholder,
    String? helpText,
    Map<String, dynamic>? validationRules,
    DateTime? updatedAt,
  }) {
    return CustomFieldModel(
      id: id,
      name: name ?? this.name,
      label: label ?? this.label,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      options: options ?? this.options,
      defaultValue: defaultValue ?? this.defaultValue,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      validationRules: validationRules ?? this.validationRules,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
    );
  }

  // Valide une valeur selon les règles de validation
  String? validateValue(dynamic value) {
    if (isRequired && (value == null || value.toString().isEmpty)) {
      return '$label est requis';
    }

    if (value == null || value.toString().isEmpty) return null;

    switch (type) {
      case CustomFieldType.email:
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.toString())) {
          return 'Format email invalide';
        }
        break;
      case CustomFieldType.phone:
        final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
        if (!phoneRegex.hasMatch(value.toString())) {
          return 'Format téléphone invalide';
        }
        break;
      case CustomFieldType.url:
        final urlRegex = RegExp(r'^https?://.*');
        if (!urlRegex.hasMatch(value.toString())) {
          return 'Format URL invalide';
        }
        break;
      case CustomFieldType.number:
        if (double.tryParse(value.toString()) == null) {
          return 'Doit être un nombre';
        }
        if (validationRules.containsKey('min')) {
          final min = validationRules['min'] as num;
          if (double.parse(value.toString()) < min) {
            return 'Doit être supérieur ou égal à $min';
          }
        }
        if (validationRules.containsKey('max')) {
          final max = validationRules['max'] as num;
          if (double.parse(value.toString()) > max) {
            return 'Doit être inférieur ou égal à $max';
          }
        }
        break;
      case CustomFieldType.text:
        if (validationRules.containsKey('minLength')) {
          final minLength = validationRules['minLength'] as int;
          if (value.toString().length < minLength) {
            return 'Doit contenir au moins $minLength caractères';
          }
        }
        if (validationRules.containsKey('maxLength')) {
          final maxLength = validationRules['maxLength'] as int;
          if (value.toString().length > maxLength) {
            return 'Doit contenir au maximum $maxLength caractères';
          }
        }
        break;
      default:
        break;
    }

    return null;
  }
}

// Extensions pour les types de champs personnalisés
extension CustomFieldTypeExtension on CustomFieldType {
  String get displayName {
    switch (this) {
      case CustomFieldType.text:
        return 'Texte';
      case CustomFieldType.number:
        return 'Nombre';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.boolean:
        return 'Oui/Non';
      case CustomFieldType.select:
        return 'Sélection unique';
      case CustomFieldType.multiselect:
        return 'Sélection multiple';
      case CustomFieldType.phone:
        return 'Téléphone';
      case CustomFieldType.email:
        return 'Email';
      case CustomFieldType.url:
        return 'URL';
    }
  }

  String get icon {
    switch (this) {
      case CustomFieldType.text:
        return 'text_fields';
      case CustomFieldType.number:
        return 'numbers';
      case CustomFieldType.date:
        return 'calendar_today';
      case CustomFieldType.boolean:
        return 'check_box';
      case CustomFieldType.select:
        return 'radio_button_checked';
      case CustomFieldType.multiselect:
        return 'checklist';
      case CustomFieldType.phone:
        return 'phone';
      case CustomFieldType.email:
        return 'email';
      case CustomFieldType.url:
        return 'link';
    }
  }
}