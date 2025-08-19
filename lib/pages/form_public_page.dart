import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';

class FormPublicPage extends StatefulWidget {
  final String formId;

  const FormPublicPage({
    super.key,
    required this.formId,
  });

  @override
  State<FormPublicPage> createState() => _FormPublicPageState();
}

class _FormPublicPageState extends State<FormPublicPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  FormModel? _form;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  
  // Form responses
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _loadForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      final form = await FormsFirebaseService.getPublicForm(widget.formId);
      if (form != null) {
        setState(() {
          _form = form;
          _isLoading = false;
        });
        _initializeForm();
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Formulaire introuvable ou non disponible';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeForm() {
    if (_form == null) return;
    
    // Initialize controllers and focus nodes for input fields
    for (final field in _form!.fields) {
      if (field.isInputField) {
        _controllers[field.id] = TextEditingController();
        _focusNodes[field.id] = FocusNode();
        
        // Pre-fill person fields if user is authenticated
        if (field.type == 'person_field' && AuthService.isSignedIn) {
          _prefillPersonField(field);
        }
      }
    }
  }

  void _prefillPersonField(CustomFormField field) {
    // TODO: Implement person field prefilling
    // This would require access to the current user's person data
    final personFieldType = field.personField['field'];
    switch (personFieldType) {
      case 'firstName':
        // _controllers[field.id]?.text = currentPerson?.firstName ?? '';
        break;
      case 'lastName':
        // _controllers[field.id]?.text = currentPerson?.lastName ?? '';
        break;
      case 'email':
        _controllers[field.id]?.text = AuthService.currentUser?.email ?? '';
        break;
      // Add other person fields as needed
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Collect responses
      final responses = <String, dynamic>{};
      for (final field in _form!.fields) {
        if (field.isInputField) {
          final value = _getFieldValue(field);
          if (value != null) {
            responses[field.id] = value;
          }
        }
      }

      // Create submission
      final submission = FormSubmissionModel(
        id: '',
        formId: _form!.id,
        personId: AuthService.currentUser?.uid,
        firstName: _getResponseValue('firstName') ?? '',
        lastName: _getResponseValue('lastName') ?? '',
        email: _getResponseValue('email') ?? AuthService.currentUser?.email,
        responses: responses,
        submittedAt: DateTime.now(),
        isTestSubmission: _form!.settings.enableTestMode,
      );

      await FormsFirebaseService.submitForm(submission);
      
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  dynamic _getFieldValue(CustomFormField field) {
    switch (field.type) {
      case 'checkbox':
        return _responses[field.id] ?? [];
      case 'radio':
      case 'select':
        return _responses[field.id];
      case 'date':
        final dateStr = _controllers[field.id]?.text;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            return DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (e) {
            return null;
          }
        }
        return null;
      default:
        return _controllers[field.id]?.text;
    }
  }

  String? _getResponseValue(String key) {
    // Helper to get specific response values
    for (final field in _form!.fields) {
      if (field.type == 'person_field' && field.personField['field'] == key) {
        return _controllers[field.id]?.text;
      }
      if (field.type == key || (field.type == 'email' && key == 'email')) {
        return _controllers[field.id]?.text;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_form?.title ?? 'Formulaire'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadForm,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_isSubmitted) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Formulaire soumis !',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  _form!.settings.confirmationMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (_form!.settings.redirectUrl != null)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement redirect
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuer'),
                ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_form!.headerImageUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_form!.headerImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form header
                      Text(
                        _form!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (_form!.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _form!.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Form fields
                      ...List.generate(_form!.fields.length, (index) {
                        final field = _form!.fields[index];
                        return _buildField(field);
                      }),
                      
                      const SizedBox(height: 32),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Envoi en cours...'),
                                  ],
                                )
                              : const Text(
                                  'Soumettre le formulaire',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Form info
                      if (_form!.hasSubmissionLimit)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.warningColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Limite de ${_form!.submissionLimit} soumissions',
                                style: TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.isContentField) ...[
            _buildContentField(field),
          ] else ...[
            _buildInputField(field),
          ],
        ],
      ),
    );
  }

  Widget _buildContentField(CustomFormField field) {
    switch (field.type) {
      case 'section':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                field.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (field.helpText != null) ...[
                const SizedBox(height: 4),
                Text(
                  field.helpText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        );
      case 'title':
        return Text(
          field.label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
      case 'instructions':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  field.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputField(CustomFormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Expanded(
              child: Text(
                field.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (field.isRequired)
              Text(
                '*',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Input widget
        _buildInputWidget(field),
      ],
    );
  }

  Widget _buildInputWidget(CustomFormField field) {
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'person_field':
        return _buildTextInput(field);
      case 'textarea':
        return _buildTextAreaInput(field);
      case 'select':
        return _buildSelectInput(field);
      case 'radio':
        return _buildRadioInput(field);
      case 'checkbox':
        return _buildCheckboxInput(field);
      case 'date':
        return _buildDateInput(field);
      case 'time':
        return _buildTimeInput(field);
      case 'file':
        return _buildFileInput(field);
      case 'signature':
        return _buildSignatureInput(field);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      focusNode: _focusNodes[field.id],
      decoration: InputDecoration(
        hintText: field.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: _getKeyboardType(field.type),
      validator: (value) => _validateField(field, value),
      inputFormatters: _getInputFormatters(field.type),
    );
  }

  Widget _buildTextAreaInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      focusNode: _focusNodes[field.id],
      decoration: InputDecoration(
        hintText: field.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 4,
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildSelectInput(CustomFormField field) {
    return DropdownButtonFormField<String>(
      value: _responses[field.id],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: Text(field.placeholder ?? 'Sélectionnez une option'),
      items: field.options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _responses[field.id] = value;
        });
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildRadioInput(CustomFormField field) {
    return Column(
      children: field.options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: _responses[field.id],
          onChanged: (value) {
            setState(() {
              _responses[field.id] = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput(CustomFormField field) {
    final selectedOptions = _responses[field.id] as List<String>? ?? [];
    
    return Column(
      children: field.options.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: selectedOptions.contains(option),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
              _responses[field.id] = selectedOptions;
            });
          },
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildDateInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        hintText: 'JJ/MM/AAAA',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          _controllers[field.id]?.text = DateFormat('dd/MM/yyyy').format(date);
        }
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildTimeInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        hintText: 'HH:MM',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.access_time),
      ),
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          _controllers[field.id]?.text = time.format(context);
        }
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildFileInput(CustomFormField field) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement file picker
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité de téléchargement de fichiers en développement'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 48,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez pour télécharger un fichier',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureInput(CustomFormField field) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 48,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Zone de signature',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fonctionnalité en développement',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextInputType _getKeyboardType(String type) {
    switch (type) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters(String type) {
    switch (type) {
      case 'phone':
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  String? _validateField(CustomFormField field, dynamic value) {
    if (field.isRequired && (value == null || value.toString().isEmpty)) {
      return 'Ce champ est obligatoire';
    }

    switch (field.type) {
      case 'email':
        if (value != null && value.toString().isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.toString())) {
            return 'Email invalide';
          }
        }
        break;
      case 'phone':
        if (value != null && value.toString().isNotEmpty) {
          if (value.toString().length < 10) {
            return 'Numéro de téléphone invalide';
          }
        }
        break;
    }

    // Apply validation rules
    if (field.validation.isNotEmpty && value != null && value.toString().isNotEmpty) {
      final minLength = field.validation['minLength'];
      final maxLength = field.validation['maxLength'];
      
      if (minLength != null && value.toString().length < minLength) {
        return 'Minimum $minLength caractères requis';
      }
      
      if (maxLength != null && value.toString().length > maxLength) {
        return 'Maximum $maxLength caractères autorisés';
      }
    }

    return null;
  }
}