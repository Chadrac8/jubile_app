/// Data Schema Documentation for ChurchFlow
/// 
/// This file documents the Firestore database structure and relationships
/// for the church management system.

/// COLLECTION: persons
/// Purpose: Store individual member profiles and personal information
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - firstName: String (required) - Member's first name
/// - lastName: String (required) - Member's last name  
/// - email: String (required) - Primary email address
/// - phone: String? (optional) - Primary phone number
/// - birthDate: Timestamp? (optional) - Date of birth
/// - address: String? (optional) - Physical address
/// - gender: String? (optional) - Gender identity ('Male', 'Female', 'Other')
/// - maritalStatus: String? (optional) - Marital status ('Single', 'Married', 'Divorced', 'Widowed')
/// - children: Array<String> (default: []) - Names of children
/// - profileImageUrl: String? (optional) - Base64 encoded profile image
/// - privateNotes: String? (optional) - Admin-only notes about the person
/// - isActive: Boolean (default: true) - Whether the person is an active member
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - familyId: String? (optional) - Reference to families collection
/// - roles: Array<String> (default: []) - Array of role IDs from roles collection
/// - tags: Array<String> (default: []) - Custom tags for categorization
/// - customFields: Map<String, dynamic> (default: {}) - Custom field values
/// - lastModifiedBy: String? (optional) - User ID who last modified the record
/// 
/// Indexes:
/// - Compound: (isActive, lastName) for filtered sorting
/// - Compound: (familyId, firstName) for family member queries
/// - Array: (roles, lastName) for role-based filtering
/// 
/// Security: Read/write for authenticated users, validation on required fields

/// COLLECTION: families  
/// Purpose: Group related individuals into family units
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Family name/identifier
/// - headOfFamilyId: String? (optional) - Person ID of family head
/// - memberIds: Array<String> (default: []) - Array of person IDs in this family
/// - address: String? (optional) - Family address
/// - homePhone: String? (optional) - Family home phone
/// - createdAt: Timestamp (required) - Creation timestamp  
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// 
/// Relationships:
/// - One-to-many with persons (familyId field)
/// - headOfFamilyId references persons.id
/// - memberIds array contains persons.id values
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: roles
/// Purpose: Define member roles and permissions within the church
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Role name (e.g., 'Member', 'Leader', 'Pastor')
/// - description: String (required) - Role description and responsibilities
/// - color: String (required) - Hex color code for UI display
/// - permissions: Array<String> (default: []) - Array of permission strings
/// - icon: String (required) - Material Icon name for UI display
/// - isActive: Boolean (default: true) - Whether role is available for assignment
/// - createdAt: Timestamp (required) - Creation timestamp
/// 
/// Relationships:
/// - Many-to-many with persons (persons.roles array)
/// 
/// Security: Read for authenticated users, write for admins only

/// COLLECTION: workflows
/// Purpose: Define automated follow-up processes for member care
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Workflow name
/// - description: String (required) - Workflow purpose and description
/// - steps: Array<WorkflowStep> (default: []) - Ordered array of workflow steps
/// - triggerConditions: Map<String, dynamic> (default: {}) - Conditions to auto-start workflow
/// - isActive: Boolean (default: true) - Whether workflow is available
/// - createdAt: Timestamp (required) - Creation timestamp
/// 
/// WorkflowStep Structure:
/// - id: String - Step identifier
/// - name: String - Step name
/// - description: String - Step description
/// - order: Number - Step order in workflow
/// - isRequired: Boolean - Whether step completion is required
/// 
/// Security: Read for authenticated users, write for admins only

/// COLLECTION: person_workflows
/// Purpose: Track workflow progress for individual members
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - personId: String (required) - Reference to persons.id
/// - workflowId: String (required) - Reference to workflows.id  
/// - currentStep: Number (default: 0) - Current step index in workflow
/// - completedSteps: Array<String> (default: []) - Array of completed step IDs
/// - notes: String (default: '') - Progress notes and comments
/// - startDate: Timestamp (required) - When workflow was started
/// - lastUpdated: Timestamp (required) - Last activity timestamp
/// 
/// Indexes:
/// - Compound: (personId, workflowId) for person workflow queries
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: activity_logs
/// Purpose: Audit trail of all person record modifications
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - personId: String (required) - Reference to persons.id
/// - action: String (required) - Action type ('create', 'update', 'delete', etc.)
/// - changes: Map<String, dynamic> (required) - Details of what changed
/// - timestamp: Timestamp (required) - When action occurred
/// - userId: String? (optional) - ID of user who performed action
/// 
/// Indexes:
/// - Compound: (personId, timestamp DESC) for person activity history
/// 
/// Security: Read/create for authenticated users, no updates/deletes

/// COLLECTION: groups
/// Purpose: Store group information for small groups, ministries, and communities
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Group name
/// - description: String (required) - Group description and purpose
/// - type: String (required) - Group type ('Petit groupe', 'Prière', 'Jeunesse', etc.)
/// - frequency: String (required) - Meeting frequency ('weekly', 'biweekly', 'monthly', 'quarterly')
/// - location: String (required) - Meeting location or address
/// - meetingLink: String? (optional) - Video meeting link (Zoom, Meet, etc.)
/// - dayOfWeek: Number (required) - Day of week (1-7, Monday-Sunday)
/// - time: String (required) - Meeting time in HH:MM format
/// - isPublic: Boolean (default: true) - Whether group is visible to all members
/// - color: String (required) - Hex color code for UI display
/// - leaderIds: Array<String> (default: []) - Array of person IDs who are leaders
/// - tags: Array<String> (default: []) - Custom tags for categorization
/// - customFields: Map<String, dynamic> (default: {}) - Custom field values
/// - isActive: Boolean (default: true) - Whether group is currently active
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - lastModifiedBy: String? (optional) - User ID who last modified the record
/// 
/// Indexes:
/// - Compound: (isActive, name) for filtered sorting
/// - Compound: (type, dayOfWeek) for filtered queries
/// - Array: (leaderIds, name) for leader-based filtering
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: group_members
/// Purpose: Track membership in groups with roles and status
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - groupId: String (required) - Reference to groups.id
/// - personId: String (required) - Reference to persons.id
/// - role: String (required) - Member role ('leader', 'co-leader', 'member', 'guest')
/// - status: String (default: 'active') - Membership status ('active', 'pending', 'removed')
/// - joinedAt: Timestamp (required) - When person joined the group
/// - leftAt: Timestamp? (optional) - When person left the group (if applicable)
/// - notes: String? (optional) - Additional notes about membership
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// 
/// Indexes:
/// - Compound: (groupId, status) for active member queries
/// - Compound: (personId, status) for person's group memberships
/// - Compound: (groupId, role) for role-based queries
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: group_meetings
/// Purpose: Store information about group meetings and sessions
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - groupId: String (required) - Reference to groups.id
/// - title: String (required) - Meeting title or topic
/// - description: String? (optional) - Meeting description or agenda
/// - date: Timestamp (required) - Meeting date and time
/// - location: String (required) - Meeting location
/// - notes: String? (optional) - Pre-meeting notes or agenda
/// - reportNotes: String? (optional) - Post-meeting report and summary
/// - presentMemberIds: Array<String> (default: []) - IDs of members who attended
/// - absentMemberIds: Array<String> (default: []) - IDs of members who were absent
/// - isCompleted: Boolean (default: false) - Whether attendance has been taken
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - createdBy: String? (optional) - User ID who created the meeting
/// 
/// Indexes:
/// - Compound: (groupId, date DESC) for chronological meeting lists
/// - Compound: (groupId, isCompleted) for filtering completed meetings
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: group_attendance
/// Purpose: Individual attendance records for detailed tracking
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - groupId: String (required) - Reference to groups.id
/// - meetingId: String (required) - Reference to group_meetings.id
/// - personId: String (required) - Reference to persons.id
/// - isPresent: Boolean (required) - Whether person was present
/// - notes: String? (optional) - Notes about attendance (late, early leave, etc.)
/// - recordedAt: Timestamp (required) - When attendance was recorded
/// - recordedBy: String? (optional) - User ID who recorded the attendance
/// 
/// Indexes:
/// - Compound: (meetingId, personId) for unique attendance records
/// - Compound: (personId, groupId) for individual attendance history
/// - Compound: (groupId, recordedAt DESC) for group attendance reports
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: group_activity_logs
/// Purpose: Audit trail of all group-related modifications
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - groupId: String (required) - Reference to groups.id
/// - action: String (required) - Action type ('create', 'update', 'member_added', etc.)
/// - details: Map<String, dynamic> (required) - Details of what changed
/// - timestamp: Timestamp (required) - When action occurred
/// - userId: String? (optional) - ID of user who performed action
/// 
/// Indexes:
/// - Compound: (groupId, timestamp DESC) for group activity history
/// 
/// Security: Read/create for authenticated users, no updates/deletes

/// COLLECTION: services
/// Purpose: Store church services, meetings and events information
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Service name
/// - description: String? (optional) - Service description
/// - type: String (required) - Service type ('culte', 'repetition', 'evenement_special', 'reunion')
/// - dateTime: Timestamp (required) - Service date and time
/// - location: String (required) - Service location
/// - durationMinutes: Number (default: 90) - Estimated duration in minutes
/// - status: String (default: 'brouillon') - Service status ('brouillon', 'publie', 'archive', 'annule')
/// - notes: String? (optional) - Additional notes
/// - teamIds: Array<String> (default: []) - Array of assigned team IDs
/// - attachmentUrls: Array<String> (default: []) - Array of file attachment URLs
/// - customFields: Map<String, dynamic> (default: {}) - Custom field values
/// - isRecurring: Boolean (default: false) - Whether service repeats
/// - recurrencePattern: Map<String, dynamic>? (optional) - Recurrence configuration
/// - templateId: String? (optional) - Reference to service template
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - createdBy: String? (optional) - User ID who created the service
/// - lastModifiedBy: String? (optional) - User ID who last modified the service
/// 
/// Indexes:
/// - Compound: (status, dateTime) for filtered chronological queries
/// - Compound: (type, dateTime) for type-based filtering
/// - Single: (dateTime DESC) for chronological listing
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: service_sheets
/// Purpose: Store liturgical order and service sheet information
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - serviceId: String (required) - Reference to services.id
/// - title: String (required) - Sheet title
/// - items: Array<ServiceSheetItem> (default: []) - Ordered array of service elements
/// - notes: String? (optional) - Additional sheet notes
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - createdBy: String? (optional) - User ID who created the sheet
/// 
/// ServiceSheetItem Structure:
/// - id: String - Item identifier
/// - type: String - Item type ('section', 'louange', 'predication', 'annonce', 'priere', 'chant', 'lecture', 'offrande', 'autre')
/// - title: String - Item title
/// - description: String? - Item description
/// - order: Number - Item order in service
/// - durationMinutes: Number - Estimated duration
/// - responsiblePersonId: String? - Person responsible for this item
/// - songId: String? - REMOVED - Songs module deleted
/// - attachmentUrls: Array<String> - Item-specific attachments
/// - customData: Map<String, dynamic> - Custom item data
/// 
/// Indexes:
/// - Single: (serviceId) for service sheet lookup
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: teams
/// Purpose: Define service teams and their roles
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Team name (e.g., 'Louange', 'Accueil', 'Technique')
/// - description: String (required) - Team description and responsibilities
/// - color: String (required) - Hex color code for UI display
/// - positionIds: Array<String> (default: []) - Array of position IDs in this team
/// - isActive: Boolean (default: true) - Whether team is available for assignment
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// 
/// Relationships:
/// - One-to-many with positions (positions.teamId)
/// 
/// Security: Read for authenticated users, write for team leaders and admins

/// COLLECTION: positions
/// Purpose: Define specific roles within teams
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - teamId: String (required) - Reference to teams.id
/// - name: String (required) - Position name (e.g., 'Chef de louange', 'Guitariste')
/// - description: String (required) - Position description and requirements
/// - isLeaderPosition: Boolean (default: false) - Whether this is a leadership role
/// - requiredSkills: Array<String> (default: []) - Array of required skill names
/// - maxAssignments: Number (default: 1) - Maximum people for this position per service
/// - isActive: Boolean (default: true) - Whether position is available
/// - createdAt: Timestamp (required) - Creation timestamp
/// 
/// Relationships:
/// - Many-to-one with teams (teamId field)
/// - One-to-many with service_assignments
/// 
/// Security: Read for authenticated users, write for team leaders and admins

/// COLLECTION: service_assignments
/// Purpose: Track person assignments to service positions
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - serviceId: String (required) - Reference to services.id
/// - positionId: String (required) - Reference to positions.id
/// - personId: String (required) - Reference to persons.id
/// - status: String (default: 'invited') - Assignment status ('invited', 'accepted', 'declined', 'tentative', 'confirmed')
/// - notes: String? (optional) - Assignment-specific notes
/// - respondedAt: Timestamp? (optional) - When person responded to invitation
/// - lastReminderSent: Timestamp? (optional) - When last reminder was sent
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - assignedBy: String? (optional) - User ID who made the assignment
/// 
/// Indexes:
/// - Compound: (serviceId, positionId) for service position queries
/// - Compound: (personId, serviceId) for person's service assignments
/// - Compound: (status, serviceId) for status-based filtering
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: person_availability
/// Purpose: Track individual availability preferences and constraints
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - personId: String (required) - Reference to persons.id
/// - startDate: Timestamp (required) - Availability period start
/// - endDate: Timestamp (required) - Availability period end
/// - availabilityType: String (required) - Type ('available', 'unavailable', 'preferred', 'limited')
/// - notes: String? (optional) - Additional availability notes
/// - preferredTeams: Array<String> (default: []) - Preferred team IDs
/// - preferredPositions: Array<String> (default: []) - Preferred position IDs
/// - createdAt: Timestamp (required) - Creation timestamp
/// 
/// Indexes:
/// - Compound: (personId, startDate) for person availability queries
/// - Compound: (startDate, endDate) for date range queries
/// 
/// Security: Read/write for authenticated users, personal data restrictions

/// service_activity_logs - Audit trail services

/// COLLECTION: events
/// Purpose: Store church events, conferences, and special activities
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - title: String (required) - Event title
/// - description: String (required) - Event description
/// - startDate: Timestamp (required) - Event start date and time
/// - endDate: Timestamp? (optional) - Event end date and time
/// - location: String (required) - Event location or address
/// - imageUrl: String? (optional) - Event image URL
/// - type: String (required) - Event type ('celebration', 'bapteme', 'formation', 'sortie', 'conference', 'reunion', 'autre')
/// - responsibleIds: Array<String> (default: []) - Array of responsible person IDs
/// - visibility: String (default: 'publique') - Event visibility ('publique', 'privee', 'groupe', 'role')
/// - visibilityTargets: Array<String> (default: []) - Target group/role IDs if restricted
/// - status: String (default: 'brouillon') - Event status ('brouillon', 'publie', 'archive', 'annule')
/// - isRegistrationEnabled: Boolean (default: false) - Whether registrations are allowed
/// - maxParticipants: Number? (optional) - Maximum number of participants
/// - hasWaitingList: Boolean (default: false) - Whether to enable waiting list
/// - isRecurring: Boolean (default: false) - Whether event repeats
/// - recurrencePattern: Map<String, dynamic>? (optional) - Recurrence configuration
/// - attachmentUrls: Array<String> (default: []) - Array of attachment URLs
/// - customFields: Map<String, dynamic> (default: {}) - Custom field values
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - createdBy: String? (optional) - User ID who created the event
/// - lastModifiedBy: String? (optional) - User ID who last modified the event
/// 
/// Indexes:
/// - Compound: (status, startDate) for filtered chronological queries
/// - Compound: (type, startDate) for type-based filtering
/// - Single: (startDate DESC) for chronological listing
/// - Array: (responsibleIds, startDate) for responsible person queries
/// 
/// Security: Read/write for authenticated users, visibility restrictions apply

/// COLLECTION: event_forms
/// Purpose: Store customizable registration forms for events
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - eventId: String (required) - Reference to events.id
/// - title: String (required) - Form title
/// - description: String (default: '') - Form description
/// - fields: Array<EventFormField> (default: []) - Array of form fields
/// - confirmationMessage: String (default: 'Merci pour votre inscription !') - Success message
/// - confirmationEmailTemplate: String? (optional) - Email template for confirmations
/// - isActive: Boolean (default: true) - Whether form is active
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// 
/// EventFormField Structure:
/// - id: String - Field identifier
/// - label: String - Field label
/// - type: String - Field type ('text', 'email', 'phone', 'number', 'select', 'checkbox', 'textarea')
/// - isRequired: Boolean - Whether field is required
/// - options: Array<String> - Options for select/checkbox fields
/// - placeholder: String? - Field placeholder text
/// - helpText: String? - Help text for field
/// - validation: Map<String, dynamic>? - Validation rules
/// - order: Number - Field order in form
/// 
/// Indexes:
/// - Single: (eventId) for event form lookup
/// 
/// Security: Read/write for authenticated users

/// COLLECTION: event_registrations
/// Purpose: Store individual registrations for events
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - eventId: String (required) - Reference to events.id
/// - personId: String? (optional) - Reference to persons.id if registered user
/// - firstName: String (required) - Registrant first name
/// - lastName: String (required) - Registrant last name
/// - email: String (required) - Registrant email
/// - phone: String? (optional) - Registrant phone
/// - formResponses: Map<String, dynamic> (default: {}) - Form field responses
/// - status: String (default: 'confirmed') - Registration status ('confirmed', 'waiting', 'cancelled')
/// - registrationDate: Timestamp (required) - When registration was made
/// - isPresent: Boolean (default: false) - Whether person attended
/// - attendanceRecordedAt: Timestamp? (optional) - When attendance was recorded
/// - notes: String? (optional) - Additional notes
/// 
/// Indexes:
/// - Compound: (eventId, status) for event registration queries
/// - Compound: (personId, eventId) for person's event registrations
/// - Single: (registrationDate DESC) for chronological listing
/// 
/// Security: Read/write for authenticated users, personal data restrictions

/// COLLECTION: event_activity_logs
/// Purpose: Audit trail of all event-related modifications
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - eventId: String (required) - Reference to events.id
/// - action: String (required) - Action type ('event_created', 'registration_created', etc.)
/// - details: Map<String, dynamic> (required) - Details of what changed
/// - timestamp: Timestamp (required) - When action occurred
/// - userId: String? (optional) - ID of user who performed action
/// 
/// Indexes:
/// - Compound: (eventId, timestamp DESC) for event activity history
/// 
/// Security: Read/create for authenticated users, no updates/deletes

/// COLLECTION: forms
/// Purpose: Store custom forms for data collection and surveys
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - title: String (required) - Form title
/// - description: String (required) - Form description and purpose
/// - headerImageUrl: String? (optional) - Header image URL
/// - status: String (default: 'brouillon') - Form status ('brouillon', 'publie', 'archive')
/// - publishDate: Timestamp? (optional) - When form was published
/// - closeDate: Timestamp? (optional) - When form closes for submissions
/// - submissionLimit: Number? (optional) - Maximum number of submissions allowed
/// - accessibility: String (default: 'public') - Who can access ('public', 'membres', 'groupe', 'role')
/// - accessibilityTargets: Array<String> (default: []) - Group/Role IDs if restricted access
/// - displayMode: String (default: 'single_page') - Display mode ('single_page', 'multi_step')
/// - fields: Array<FormField> (default: []) - Array of form fields
/// - settings: FormSettings (required) - Form configuration and post-submission actions
/// - createdAt: Timestamp (required) - Creation timestamp
/// - updatedAt: Timestamp (required) - Last modification timestamp
/// - createdBy: String? (optional) - User ID who created the form
/// - lastModifiedBy: String? (optional) - User ID who last modified the form
/// 
/// FormField Structure:
/// - id: String - Field identifier
/// - type: String - Field type ('text', 'textarea', 'email', 'phone', 'checkbox', 'radio', 'select', 'date', 'time', 'file', 'section', 'title', 'instructions', 'person_field', 'signature')
/// - label: String - Field label/question
/// - placeholder: String? - Input placeholder text
/// - helpText: String? - Help text for the field
/// - isRequired: Boolean - Whether field is required
/// - options: Array<String> - Options for radio/checkbox/select fields
/// - validation: Map<String, dynamic> - Validation rules (minLength, maxLength, etc.)
/// - conditional: Map<String, dynamic> - Conditional logic rules
/// - personField: Map<String, dynamic> - Person field mapping for auto-fill
/// - order: Number - Field order in form
/// - styling: Map<String, dynamic> - Field styling options
/// 
/// FormSettings Structure:
/// - confirmationMessage: String - Message shown after submission
/// - redirectUrl: String? - URL to redirect after submission
/// - sendConfirmationEmail: Boolean - Whether to send confirmation email
/// - confirmationEmailTemplate: String? - Email template for confirmations
/// - notificationEmails: Array<String> - Emails to notify on new submissions
/// - autoAddToGroup: Boolean - Whether to automatically add submitter to a group
/// - targetGroupId: String? - Group ID for auto-addition
/// - autoAddToWorkflow: Boolean - Whether to start a workflow for submitter
/// - targetWorkflowId: String? - Workflow ID to start
/// - allowMultipleSubmissions: Boolean - Whether to allow multiple submissions per user
/// - showProgressBar: Boolean - Whether to show progress bar (multi-step forms)
/// - postSubmissionActions: Map<String, dynamic> - Additional actions to perform
/// 
/// Indexes:
/// - Compound: (status, updatedAt DESC) for filtered chronological queries
/// - Compound: (accessibility, publishDate) for access-based filtering
/// - Single: (createdBy) for user's forms
/// 
/// Security: Read/write for authenticated users, visibility restrictions apply

/// COLLECTION: form_submissions
/// Purpose: Store individual form submissions and responses
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - formId: String (required) - Reference to forms.id
/// - personId: String? (optional) - Reference to persons.id if authenticated submission
/// - firstName: String? (optional) - Submitter's first name
/// - lastName: String? (optional) - Submitter's last name
/// - email: String? (optional) - Submitter's email address
/// - responses: Map<String, dynamic> (default: {}) - Field ID to response value mapping
/// - fileUrls: Array<String> (default: []) - URLs of uploaded files
/// - status: String (default: 'submitted') - Submission status ('submitted', 'processed', 'archived')
/// - submittedAt: Timestamp (required) - When submission was made
/// - submitterIp: String? (optional) - IP address of submitter
/// - submitterUserAgent: String? (optional) - User agent string
/// - metadata: Map<String, dynamic> (default: {}) - Additional metadata
/// 
/// Indexes:
/// - Compound: (formId, submittedAt DESC) for form submissions chronologically
/// - Compound: (formId, status) for filtering by status
/// - Compound: (personId, submittedAt DESC) for user's submissions
/// 
/// Security: Read/write for authenticated users, personal data restrictions

/// COLLECTION: form_templates
/// Purpose: Store reusable form templates for quick form creation
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - name: String (required) - Template name
/// - description: String (required) - Template description
/// - category: String (required) - Template category
/// - fields: Array<FormField> (required) - Template fields structure
/// - defaultSettings: FormSettings (required) - Default form settings
/// - isBuiltIn: Boolean (default: false) - Whether template is built-in or user-created
/// - createdAt: Timestamp (required) - Creation timestamp
/// - createdBy: String? (optional) - User ID who created template
/// 
/// Security: Read for authenticated users, write for admins and template creators

/// COLLECTION: form_activity_logs
/// Purpose: Audit trail of all form-related modifications
/// 
/// Fields:
/// - id: String (auto-generated document ID)
/// - formId: String (required) - Reference to forms.id
/// - action: String (required) - Action type ('form_created', 'form_published', 'form_submitted', etc.)
/// - details: Map<String, dynamic> (required) - Details of what changed
/// - timestamp: Timestamp (required) - When action occurred
/// - userId: String? (optional) - ID of user who performed action
/// 
/// Indexes:
/// - Compound: (formId, timestamp DESC) for form activity history
/// 
/// Security: Read/create for authenticated users, no updates/deletes

/// DATA RELATIONSHIPS SUMMARY:
/// 
/// persons ←→ families (many-to-one via familyId)
/// persons ←→ roles (many-to-many via roles array) 
/// persons → person_workflows (one-to-many)
/// workflows → person_workflows (one-to-many)
/// persons → activity_logs (one-to-many)
/// groups ←→ group_members (one-to-many)
/// persons ←→ group_members (one-to-many)
/// groups → group_meetings (one-to-many)
/// group_meetings → group_attendance (one-to-many)
/// persons → group_attendance (one-to-many via personId)
/// groups → group_activity_logs (one-to-many)
/// services → service_sheets (one-to-one)
/// services ←→ service_assignments (one-to-many)
/// teams → positions (one-to-many)
/// positions ←→ service_assignments (one-to-many)
/// persons ←→ service_assignments (one-to-many)
/// persons → person_availability (one-to-many)
/// services → service_activity_logs (one-to-many)
/// events → event_forms (one-to-one)
/// events → event_registrations (one-to-many)
/// persons → event_registrations (one-to-many via personId)
/// events → event_activity_logs (one-to-many)
/// forms → form_submissions (one-to-many)
/// persons → form_submissions (one-to-many via personId)
/// form_templates → forms (template relationship)
/// forms → form_activity_logs (one-to-many)
/// 
/// BUSINESS RULES:
/// 
/// 1. A person can belong to only one family
/// 2. A person can have multiple roles
/// 3. A person can have multiple active workflows
/// 4. Family head must be a member of that family
/// 5. Activity logs are immutable once created
/// 6. Soft deletes used (isActive flag) to preserve data integrity
/// 7. All timestamps stored in UTC
/// 8. Profile images stored as base64 data URLs in person documents
/// 9. A service can have only one service sheet
/// 10. A person can be assigned to multiple positions in the same service
/// 11. Position assignments have statuses to track confirmation workflow
/// 12. Service status determines visibility and editability
/// 13. Teams and positions form hierarchical structure
/// 14. Availability constraints are enforced during assignment
/// 15. Event registrations can be linked to persons or external
/// 16. Event forms are customizable with multiple field types
/// 17. Event visibility controls who can see and register
/// 18. Waiting lists automatically promote when space available
/// 19. Forms can have multiple accessibility levels (public, members, groups, roles)
/// 20. Form submissions are linked to persons when authenticated
/// 21. Form fields support conditional logic and validation rules
/// 22. Published forms cannot be deleted, only archived
/// 23. Form submission limits are enforced when specified
/// 24. Test submissions are separate from real submissions
/// 25. File uploads in forms are stored in Firebase Storage
/// 26. Person fields in forms auto-populate for authenticated users
/// 27. Form templates enable quick form creation with predefined structures
/// 
/// PERFORMANCE CONSIDERATIONS:
/// 
/// 1. Compound indexes optimize common query patterns
/// 2. Arrays used sparingly to avoid document size limits
/// 3. Pagination implemented for large result sets
/// 4. Client-side filtering for text search to avoid index limitations
/// 5. Batch operations used for bulk updates
/// 6. Activity logging is async to avoid blocking main operations
/// 7. Form statistics calculated on-demand to avoid real-time overhead
/// 8. Large form responses paginated for better performance
/// 9. File uploads handled asynchronously with progress tracking
/// 10. Form field validation performed client-side before submission
/// 11. Template loading cached to reduce database queries