import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';


class PositionFormPage extends StatefulWidget {
  final String teamId;
  final PositionModel? position;

  const PositionFormPage({
    super.key,
    required this.teamId,
    this.position,
  });

  @override
  State<PositionFormPage> createState() => _PositionFormPageState();
}

class _PositionFormPageState extends State<PositionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillController = TextEditingController();
  
  bool _isLeaderPosition = false;
  int _maxAssignments = 1;
  bool _isActive = true;
  List<String> _requiredSkills = [];
  bool _isLoading = false;
  TeamModel? _team;

  // Predefined skills suggestions
  final List<String> _skillSuggestions = [
    'Chant',
    'Guitare',
    'Piano',
    'Basse',
    'Batterie',
    'Violon',
    'Saxophone',
    'Direction musicale',
    'Sonorisation',
    'Éclairage',
    'Projection',
    'Caméra',
    'Streaming',
    'Accueil',
    'Organisation',
    'Animation',
    'Enseignement',
    'Prédication',
    'Prière',
    'Conseil',
    'Formation',
    'Leadership',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeam();
    if (widget.position != null) {
      _initializeForm();
    }
  }

  Future<void> _loadTeam() async {
    try {
      final team = await ServicesFirebaseService.getTeam(widget.teamId);
      setState(() {
        _team = team;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _initializeForm() {
    final position = widget.position!;
    _nameController.text = position.name;
    _descriptionController.text = position.description;
    _isLeaderPosition = position.isLeaderPosition;
    _maxAssignments = position.maxAssignments;
    _isActive = position.isActive;
    _requiredSkills = List.from(position.requiredSkills);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6F61EF);
    }
  }

  void _addSkill(String skill) {
    if (skill.trim().isNotEmpty && !_requiredSkills.contains(skill.trim())) {
      setState(() {
        _requiredSkills.add(skill.trim());
      });
      _skillController.clear();
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _requiredSkills.remove(skill);
    });
  }

  void _showSkillSuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compétences suggérées',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillSuggestions
                  .where((skill) => !_requiredSkills.contains(skill))
                  .map((skill) => ActionChip(
                        label: Text(skill),
                        onPressed: () {
                          _addSkill(skill);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePosition() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      
      if (widget.position != null) {
        // Update existing position
        final updatedPosition = PositionModel(
          id: widget.position!.id,
          teamId: widget.teamId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isLeaderPosition: _isLeaderPosition,
          requiredSkills: _requiredSkills,
          maxAssignments: _maxAssignments,
          isActive: _isActive,
          createdAt: widget.position!.createdAt,
        );
        
        await ServicesFirebaseService.updatePosition(updatedPosition);
      } else {
        // Create new position
        final newPosition = PositionModel(
          id: '',
          teamId: widget.teamId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isLeaderPosition: _isLeaderPosition,
          requiredSkills: _requiredSkills,
          maxAssignments: _maxAssignments,
          isActive: _isActive,
          createdAt: now,
        );
        
        await ServicesFirebaseService.createPosition(newPosition);
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.position != null;
    final teamColor = _team != null ? _parseColor(_team!.color) : const Color(0xFF6F61EF);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    child: CachedNetworkImage(
                      imageUrl: "https://images.unsplash.com/photo-1474649107449-ea4f014b7e9f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDk3NDE4MDl8&ixlib=rb-4.1.0&q=80&w=1080",
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.assignment_ind,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: teamColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isLeaderPosition 
                                    ? Icons.supervisor_account
                                    : Icons.assignment_ind,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? 'Modifier la position' : 'Nouvelle position',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_team != null)
                                    Text(
                                      'Équipe ${_team!.name}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing 
                              ? 'Modifiez les informations de cette position'
                              : 'Définissez les responsabilités et compétences requises',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de la position *',
                          hintText: 'Ex: Chanteur principal, Technicien son...',
                          prefixIcon: const Icon(Icons.assignment_ind),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez les responsabilités et tâches de cette position...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 24),

                      // Leader position toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isLeaderPosition 
                                  ? Icons.supervisor_account
                                  : Icons.assignment_ind,
                              color: _isLeaderPosition 
                                  ? teamColor
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Position de leadership',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Cette position a des responsabilités de direction',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isLeaderPosition,
                              onChanged: (value) {
                                setState(() => _isLeaderPosition = value);
                              },
                              activeColor: teamColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Max assignments
                      Text(
                        'Nombre maximum de personnes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Nombre maximum: $_maxAssignments',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _maxAssignments.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _maxAssignments.toString(),
                              activeColor: teamColor,
                              onChanged: (value) {
                                setState(() => _maxAssignments = value.round());
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Required skills
                      Text(
                        'Compétences requises',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _skillController,
                                    decoration: const InputDecoration(
                                      hintText: 'Ajouter une compétence...',
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: _addSkill,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _addSkill(_skillController.text),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  onPressed: _showSkillSuggestions,
                                  icon: const Icon(Icons.lightbulb_outline),
                                  tooltip: 'Suggestions',
                                ),
                              ],
                            ),
                            if (_requiredSkills.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _requiredSkills.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () => _removeSkill(skill),
                                    backgroundColor: teamColor.withOpacity(0.1),
                                    deleteIconColor: teamColor,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Active status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.check_circle : Icons.pause_circle,
                              color: _isActive 
                                  ? teamColor
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statut de la position',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _isActive 
                                        ? 'La position est active et peut recevoir des assignations'
                                        : 'La position est inactive',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() => _isActive = value);
                              },
                              activeColor: teamColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePosition,
                  style: FilledButton.styleFrom(
                    backgroundColor: teamColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Modifier' : 'Créer la position',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}