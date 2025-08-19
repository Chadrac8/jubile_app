import 'package:cloud_firestore/cloud_firestore.dart';

class FormModel {
  final String id;
  final String title;
  final String description;
  final String? headerImageUrl;
  final String status; // 'brouillon', 'publie', 'archive'
  final DateTime? publishDate;
  final DateTime? closeDate;
  final int? submissionLimit;
  final String accessibility; // 'public', 'membres', 'groupe', 'role'
  final List<String> accessibilityTargets; // Group IDs or Role IDs if restricted
  final String displayMode; // 'single_page', 'multi_step'
  final List<CustomFormField> fields;
  final FormSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;

  FormModel({
    required this.id,
    required this.title,
    required this.description,
    this.headerImageUrl,
    this.status = 'brouillon',
    this.publishDate,
    this.closeDate,
    this.submissionLimit,
    this.accessibility = 'public',
    this.accessibilityTargets = const [],
    this.displayMode = 'single_page',
    this.fields = const [],
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
  });

  String get statusLabel {
    switch (status) {
      case 'brouillon': return 'Brouillon';
      case 'publie': return 'Publié';
      case 'archive': return 'Archivé';
      default: return status;
    }
  }

  String get accessibilityLabel {
    switch (accessibility) {
      case 'public': return 'Public';
      case 'membres': return 'Membres connectés';
      case 'groupe': return 'Groupes spécifiques';
      case 'role': return 'Rôles spécifiques';
      default: return accessibility;
    }
  }

  bool get isPublished => status == 'publie';
  bool get isDraft => status == 'brouillon';
  bool get isArchived => status == 'archive';
  
  bool get isOpen {
    if (!isPublished) return false;
    final now = DateTime.now();
    if (publishDate != null && now.isBefore(publishDate!)) return false;
    if (closeDate != null && now.isAfter(closeDate!)) return false;
    return true;
  }

  bool get hasSubmissionLimit => submissionLimit != null && submissionLimit! > 0;

  factory FormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      headerImageUrl: data['headerImageUrl'],
      status: data['status'] ?? 'brouillon',
      publishDate: data['publishDate']?.toDate(),
      closeDate: data['closeDate']?.toDate(),
      submissionLimit: data['submissionLimit'],
      accessibility: data['accessibility'] ?? 'public',
      accessibilityTargets: List<String>.from(data['accessibilityTargets'] ?? []),
      displayMode: data['displayMode'] ?? 'single_page',
      fields: (data['fields'] as List<dynamic>? ?? [])
          .map((field) => CustomFormField.fromMap(field))
          .toList(),
      settings: FormSettings.fromMap(data['settings'] ?? {}),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'headerImageUrl': headerImageUrl,
      'status': status,
      'publishDate': publishDate,
      'closeDate': closeDate,
      'submissionLimit': submissionLimit,
      'accessibility': accessibility,
      'accessibilityTargets': accessibilityTargets,
      'displayMode': displayMode,
      'fields': fields.map((field) => field.toMap()).toList(),
      'settings': settings.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  FormModel copyWith({
    String? title,
    String? description,
    String? headerImageUrl,
    String? status,
    DateTime? publishDate,
    DateTime? closeDate,
    int? submissionLimit,
    String? accessibility,
    List<String>? accessibilityTargets,
    String? displayMode,
    List<CustomFormField>? fields,
    FormSettings? settings,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return FormModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      status: status ?? this.status,
      publishDate: publishDate ?? this.publishDate,
      closeDate: closeDate ?? this.closeDate,
      submissionLimit: submissionLimit ?? this.submissionLimit,
      accessibility: accessibility ?? this.accessibility,
      accessibilityTargets: accessibilityTargets ?? this.accessibilityTargets,
      displayMode: displayMode ?? this.displayMode,
      fields: fields ?? this.fields,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class CustomFormField {
  final String id;
  final String type; // 'text', 'textarea', 'email', 'phone', 'checkbox', 'radio', 'select', 'date', 'time', 'file', 'section', 'title', 'instructions', 'person_field', 'signature'
  final String label;
  final String? placeholder;
  final String? helpText;
  final bool isRequired;
  final List<String> options; // For radio, checkbox, select
  final Map<String, dynamic> validation; // Validation rules
  final Map<String, dynamic> conditional; // Conditional logic
  final Map<String, dynamic> personField; // For person field mapping
  final int order;
  final Map<String, dynamic> styling; // Field styling options

  CustomFormField({
    required this.id,
    required this.type,
    required this.label,
    this.placeholder,
    this.helpText,
    this.isRequired = false,
    this.options = const [],
    this.validation = const {},
    this.conditional = const {},
    this.personField = const {},
    required this.order,
    this.styling = const {},
  });

  String get typeLabel {
    switch (type) {
      case 'text': return 'Texte court';
      case 'textarea': return 'Texte long';
      case 'email': return 'Email';
      case 'phone': return 'Téléphone';
      case 'checkbox': return 'Cases à cocher';
      case 'radio': return 'Boutons radio';
      case 'select': return 'Liste déroulante';
      case 'date': return 'Date';
      case 'time': return 'Heure';
      case 'file': return 'Fichier';
      case 'section': return 'Section';
      case 'title': return 'Titre';
      case 'instructions': return 'Instructions';
      case 'person_field': return 'Champ personne';
      case 'signature': return 'Signature';
      default: return type;
    }
  }

  bool get isContentField => ['section', 'title', 'instructions'].contains(type);
  bool get isInputField => !isContentField;
  bool get hasOptions => ['checkbox', 'radio', 'select'].contains(type);
  bool get isPersonLinked => type == 'person_field';

  factory CustomFormField.fromMap(Map<String, dynamic> map) {
    return CustomFormField(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      label: map['label'] ?? '',
      placeholder: map['placeholder'],
      helpText: map['helpText'],
      isRequired: map['isRequired'] ?? false,
      options: List<String>.from(map['options'] ?? []),
      validation: Map<String, dynamic>.from(map['validation'] ?? {}),
      conditional: Map<String, dynamic>.from(map['conditional'] ?? {}),
      personField: Map<String, dynamic>.from(map['personField'] ?? {}),
      order: map['order'] ?? 0,
      styling: Map<String, dynamic>.from(map['styling'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'placeholder': placeholder,
      'helpText': helpText,
      'isRequired': isRequired,
      'options': options,
      'validation': validation,
      'conditional': conditional,
      'personField': personField,
      'order': order,
      'styling': styling,
    };
  }

  CustomFormField copyWith({
    String? type,
    String? label,
    String? placeholder,
    String? helpText,
    bool? isRequired,
    List<String>? options,
    Map<String, dynamic>? validation,
    Map<String, dynamic>? conditional,
    Map<String, dynamic>? personField,
    int? order,
    Map<String, dynamic>? styling,
  }) {
    return CustomFormField(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      conditional: conditional ?? this.conditional,
      personField: personField ?? this.personField,
      order: order ?? this.order,
      styling: styling ?? this.styling,
    );
  }
}

class FormSettings {
  final String confirmationMessage;
  final String? redirectUrl;
  final bool sendConfirmationEmail;
  final String? confirmationEmailTemplate;
  final List<String> notificationEmails;
  final bool autoAddToGroup;
  final String? targetGroupId;
  final bool autoAddToWorkflow;
  final String? targetWorkflowId;
  final bool allowMultipleSubmissions;
  final bool showProgressBar;
  final bool enableTestMode;
  final Map<String, dynamic> postSubmissionActions;

  FormSettings({
    this.confirmationMessage = 'Merci pour votre soumission !',
    this.redirectUrl,
    this.sendConfirmationEmail = false,
    this.confirmationEmailTemplate,
    this.notificationEmails = const [],
    this.autoAddToGroup = false,
    this.targetGroupId,
    this.autoAddToWorkflow = false,
    this.targetWorkflowId,
    this.allowMultipleSubmissions = true,
    this.showProgressBar = true,
    this.enableTestMode = false,
    this.postSubmissionActions = const {},
  });

  factory FormSettings.fromMap(Map<String, dynamic> map) {
    return FormSettings(
      confirmationMessage: map['confirmationMessage'] ?? 'Merci pour votre soumission !',
      redirectUrl: map['redirectUrl'],
      sendConfirmationEmail: map['sendConfirmationEmail'] ?? false,
      confirmationEmailTemplate: map['confirmationEmailTemplate'],
      notificationEmails: List<String>.from(map['notificationEmails'] ?? []),
      autoAddToGroup: map['autoAddToGroup'] ?? false,
      targetGroupId: map['targetGroupId'],
      autoAddToWorkflow: map['autoAddToWorkflow'] ?? false,
      targetWorkflowId: map['targetWorkflowId'],
      allowMultipleSubmissions: map['allowMultipleSubmissions'] ?? true,
      showProgressBar: map['showProgressBar'] ?? true,
      enableTestMode: map['enableTestMode'] ?? false,
      postSubmissionActions: Map<String, dynamic>.from(map['postSubmissionActions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'confirmationMessage': confirmationMessage,
      'redirectUrl': redirectUrl,
      'sendConfirmationEmail': sendConfirmationEmail,
      'confirmationEmailTemplate': confirmationEmailTemplate,
      'notificationEmails': notificationEmails,
      'autoAddToGroup': autoAddToGroup,
      'targetGroupId': targetGroupId,
      'autoAddToWorkflow': autoAddToWorkflow,
      'targetWorkflowId': targetWorkflowId,
      'allowMultipleSubmissions': allowMultipleSubmissions,
      'showProgressBar': showProgressBar,
      'enableTestMode': enableTestMode,
      'postSubmissionActions': postSubmissionActions,
    };
  }
}

class FormSubmissionModel {
  final String id;
  final String formId;
  final String? personId; // Linked person if authenticated
  final String? firstName;
  final String? lastName;
  final String? email;
  final Map<String, dynamic> responses; // Field ID -> Response value
  final List<String> fileUrls; // Uploaded file URLs
  final String status; // 'submitted', 'processed', 'archived'
  final DateTime submittedAt;
  final String? submitterIp;
  final String? submitterUserAgent;
  final bool isTestSubmission;
  final Map<String, dynamic> metadata;

  FormSubmissionModel({
    required this.id,
    required this.formId,
    this.personId,
    this.firstName,
    this.lastName,
    this.email,
    this.responses = const {},
    this.fileUrls = const [],
    this.status = 'submitted',
    required this.submittedAt,
    this.submitterIp,
    this.submitterUserAgent,
    this.isTestSubmission = false,
    this.metadata = const {},
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return email ?? 'Anonyme';
  }

  bool get isProcessed => status == 'processed';
  bool get isArchived => status == 'archived';

  factory FormSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormSubmissionModel(
      id: doc.id,
      formId: data['formId'] ?? '',
      personId: data['personId'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      responses: Map<String, dynamic>.from(data['responses'] ?? {}),
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      status: data['status'] ?? 'submitted',
      submittedAt: data['submittedAt']?.toDate() ?? DateTime.now(),
      submitterIp: data['submitterIp'],
      submitterUserAgent: data['submitterUserAgent'],
      isTestSubmission: data['isTestSubmission'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'formId': formId,
      'personId': personId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'responses': responses,
      'fileUrls': fileUrls,
      'status': status,
      'submittedAt': submittedAt,
      'submitterIp': submitterIp,
      'submitterUserAgent': submitterUserAgent,
      'isTestSubmission': isTestSubmission,
      'metadata': metadata,
    };
  }

  FormSubmissionModel copyWith({
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return FormSubmissionModel(
      id: id,
      formId: formId,
      personId: personId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      responses: responses,
      fileUrls: fileUrls,
      status: status ?? this.status,
      submittedAt: submittedAt,
      submitterIp: submitterIp,
      submitterUserAgent: submitterUserAgent,
      isTestSubmission: isTestSubmission,
      metadata: metadata ?? this.metadata,
    );
  }
}

class FormStatisticsModel {
  final String formId;
  final int totalSubmissions;
  final int processedSubmissions;
  final int archivedSubmissions;
  final int testSubmissions;
  final Map<String, int> submissionsByDate;
  final Map<String, Map<String, int>> fieldResponses;
  final double averageCompletionTime;
  final DateTime lastUpdated;

  FormStatisticsModel({
    required this.formId,
    required this.totalSubmissions,
    required this.processedSubmissions,
    required this.archivedSubmissions,
    required this.testSubmissions,
    required this.submissionsByDate,
    required this.fieldResponses,
    required this.averageCompletionTime,
    required this.lastUpdated,
  });

  int get realSubmissions => totalSubmissions - testSubmissions;
  double get processedRate => totalSubmissions > 0 ? processedSubmissions / totalSubmissions : 0.0;

  factory FormStatisticsModel.fromMap(Map<String, dynamic> data) {
    return FormStatisticsModel(
      formId: data['formId'] ?? '',
      totalSubmissions: data['totalSubmissions'] ?? 0,
      processedSubmissions: data['processedSubmissions'] ?? 0,
      archivedSubmissions: data['archivedSubmissions'] ?? 0,
      testSubmissions: data['testSubmissions'] ?? 0,
      submissionsByDate: Map<String, int>.from(data['submissionsByDate'] ?? {}),
      fieldResponses: Map<String, Map<String, int>>.from(
        (data['fieldResponses'] ?? {}).map((key, value) => 
          MapEntry(key, Map<String, int>.from(value))
        )
      ),
      averageCompletionTime: (data['averageCompletionTime'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'formId': formId,
      'totalSubmissions': totalSubmissions,
      'processedSubmissions': processedSubmissions,
      'archivedSubmissions': archivedSubmissions,
      'testSubmissions': testSubmissions,
      'submissionsByDate': submissionsByDate,
      'fieldResponses': fieldResponses,
      'averageCompletionTime': averageCompletionTime,
      'lastUpdated': lastUpdated,
    };
  }
}

class FormTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<CustomFormField> fields;
  final FormSettings defaultSettings;
  final bool isBuiltIn;

  FormTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.fields,
    required this.defaultSettings,
    this.isBuiltIn = false,
  });

  factory FormTemplate.fromMap(Map<String, dynamic> map) {
    return FormTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      fields: (map['fields'] as List<dynamic>? ?? [])
          .map((field) => CustomFormField.fromMap(field))
          .toList(),
      defaultSettings: FormSettings.fromMap(map['defaultSettings'] ?? {}),
      isBuiltIn: map['isBuiltIn'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'fields': fields.map((field) => field.toMap()).toList(),
      'defaultSettings': defaultSettings.toMap(),
      'isBuiltIn': isBuiltIn,
    };
  }
}