import 'package:flutter/material.dart';
import '../models/component_action_model.dart';
import '../services/component_action_service.dart';
import '../services/forms_firebase_service.dart';
import '../services/blog_firebase_service.dart';
import '../services/pages_firebase_service.dart';
import '../models/form_model.dart';
import '../models/blog_model.dart';
import '../models/page_model.dart';

class ComponentActionEditor extends StatefulWidget {
  final ComponentAction? action;
  final Function(ComponentAction?) onActionChanged;
  final String componentType;

  const ComponentActionEditor({
    super.key,
    this.action,
    required this.onActionChanged,
    required this.componentType,
  });

  @override
  State<ComponentActionEditor> createState() => _ComponentActionEditorState();
}

class _ComponentActionEditorState extends State<ComponentActionEditor> {
  late ComponentAction _currentAction;
  final _urlController = TextEditingController();
  List<FormModel> _availableForms = [];
  List<BlogCategory> _availableCategories = [];
  List<CustomPageModel> _availablePages = [];
  bool _isLoadingForms = false;
  bool _isLoadingCategories = false;
  bool _isLoadingPages = false;

  @override
  void initState() {
    super.initState();
    _currentAction = widget.action ?? ComponentActionService.getDefaultAction(widget.componentType);
    _urlController.text = _currentAction.url ?? '';
    _loadFormsAndCategories();
  }

  Future<void> _loadFormsAndCategories() async {
    setState(() {
      _isLoadingForms = true;
      _isLoadingCategories = true;
      _isLoadingPages = true;
    });

    try {
      // Récupérer les formulaires depuis le stream
      final formsStream = FormsFirebaseService.getFormsStream();
      final formsSnapshot = await formsStream.first;
      
      // Récupérer les catégories de blog depuis le stream  
      final blogStream = BlogFirebaseService.getCategoriesStream();
      final categoriesSnapshot = await blogStream.first;
      
      // Récupérer les pages personnalisées publiées
      final pagesStream = PagesFirebaseService.getPagesStream(statusFilter: 'published');
      final pagesSnapshot = await pagesStream.first;
      
      setState(() {
        _availableForms = formsSnapshot;
        _availableCategories = categoriesSnapshot;
        _availablePages = pagesSnapshot;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      setState(() {
        _isLoadingForms = false;
        _isLoadingCategories = false;
        _isLoadingPages = false;
      });
    }
  }

  void _updateAction() {
    widget.onActionChanged(_currentAction.type == ComponentActionType.none ? null : _currentAction);
  }

  @override
  Widget build(BuildContext context) {
    if (!ComponentActionService.supportsActions(widget.componentType)) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Action au clic',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type d'action
            DropdownButtonFormField<ComponentActionType>(
              value: _currentAction.type,
              decoration: const InputDecoration(
                labelText: 'Type d\'action',
                border: OutlineInputBorder(),
              ),
              items: ComponentActionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        ComponentActionService.getActionIcon(type),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(ComponentActionService.getActionTypeLabel(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _currentAction = _currentAction.copyWith(type: type);
                  });
                  _updateAction();
                }
              },
            ),
            const SizedBox(height: 16),

            // Configuration selon le type
            ..._buildTypeSpecificConfiguration(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificConfiguration() {
    switch (_currentAction.type) {
      case ComponentActionType.none:
        return [
          const Text(
            'Aucune action ne sera déclenchée au clic sur ce composant.',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ];

      case ComponentActionType.externalUrl:
        return [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL externe',
              helperText: 'Ex: https://example.com (s\'ouvre dans le navigateur)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.open_in_new),
            ),
            onChanged: (value) {
              setState(() {
                _currentAction = _currentAction.copyWith(url: value);
              });
              _updateAction();
            },
          ),
        ];

      case ComponentActionType.internalUrl:
        return [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL interne',
              helperText: 'Ex: https://example.com (s\'ouvre dans l\'application)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.web),
            ),
            onChanged: (value) {
              setState(() {
                _currentAction = _currentAction.copyWith(url: value);
              });
              _updateAction();
            },
          ),
        ];

      case ComponentActionType.memberPage:
        return [
          DropdownButtonFormField<MemberPageType>(
            value: _currentAction.memberPageType,
            decoration: const InputDecoration(
              labelText: 'Page destination',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pages),
            ),
            items: MemberPageType.values.map((pageType) {
              return DropdownMenuItem(
                value: pageType,
                child: Text(pageType.displayName),
              );
            }).toList(),
            onChanged: (pageType) {
              if (pageType != null) {
                setState(() {
                  _currentAction = _currentAction.copyWith(memberPageType: pageType);
                });
                _updateAction();
              }
            },
          ),
        ];

      case ComponentActionType.customPage:
        return [
          if (_isLoadingPages)
            const Center(child: CircularProgressIndicator())
          else if (_availablePages.isEmpty)
            const Text(
              'Aucune page personnalisée publiée disponible.',
              style: TextStyle(color: Colors.grey),
            )
          else
            DropdownButtonFormField<String>(
              value: _currentAction.customPageId,
              decoration: const InputDecoration(
                labelText: 'Page personnalisée',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pages),
              ),
              items: _availablePages.map((page) {
                return DropdownMenuItem(
                  value: page.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(page.title),
                      if (page.description.isNotEmpty)
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (pageId) {
                if (pageId != null) {
                  setState(() {
                    _currentAction = _currentAction.copyWith(customPageId: pageId);
                  });
                  _updateAction();
                }
              },
            ),
        ];

      case ComponentActionType.blogCategory:
        return [
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else if (_availableCategories.isEmpty)
            const Text(
              'Aucune catégorie de blog disponible.',
              style: TextStyle(color: Colors.grey),
            )
          else
            DropdownButtonFormField<String>(
              value: _currentAction.blogCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie de blog',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _availableCategories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (categoryId) {
                if (categoryId != null) {
                  setState(() {
                    _currentAction = _currentAction.copyWith(blogCategory: categoryId);
                  });
                  _updateAction();
                }
              },
            ),
        ];

      case ComponentActionType.specificForm:
        return [
          if (_isLoadingForms)
            const Center(child: CircularProgressIndicator())
          else if (_availableForms.isEmpty)
            const Text(
              'Aucun formulaire disponible.',
              style: TextStyle(color: Colors.grey),
            )
          else
            DropdownButtonFormField<String>(
              value: _currentAction.formId,
              decoration: const InputDecoration(
                labelText: 'Formulaire',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              items: _availableForms.map((form) {
                return DropdownMenuItem(
                  value: form.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(form.title),
                      if (form.description.isNotEmpty)
                        Text(
                          form.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (formId) {
                if (formId != null) {
                  setState(() {
                    _currentAction = _currentAction.copyWith(formId: formId);
                  });
                  _updateAction();
                }
              },
            ),
        ];
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}