import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointments_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class AvailabilityManagementPage extends StatefulWidget {
  final String? responsableId;

  const AvailabilityManagementPage({
    super.key,
    this.responsableId,
  });

  @override
  State<AvailabilityManagementPage> createState() => _AvailabilityManagementPageState();
}

class _AvailabilityManagementPageState extends State<AvailabilityManagementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadData() async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  Future<void> _addWeeklyAvailability() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _WeeklyAvailabilityDialog(),
    );

    if (result != null && widget.responsableId != null) {
      try {
        final disponibilite = DisponibiliteModel(
          id: '',
          responsableId: widget.responsableId!,
          type: 'recurrence_hebdo',
          jours: List<String>.from(result['jours']),
          creneaux: List<CreneauHoraire>.from(result['creneaux']),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await AppointmentsFirebaseService.createDisponibilite(disponibilite);
        
        _showSuccessSnackBar('Disponibilité ajoutée avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _addSpecificDate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _SpecificDateDialog(),
    );

    if (result != null && widget.responsableId != null) {
      try {
        final disponibilite = DisponibiliteModel(
          id: '',
          responsableId: widget.responsableId!,
          type: 'ponctuel',
          dateSpecifique: result['date'],
          creneaux: List<CreneauHoraire>.from(result['creneaux']),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await AppointmentsFirebaseService.createDisponibilite(disponibilite);
        
        _showSuccessSnackBar('Créneaux ajoutés avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _deleteDisponibilite(String disponibiliteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la disponibilité'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette disponibilité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppointmentsFirebaseService.deleteDisponibilite(disponibiliteId);
        _showSuccessSnackBar('Disponibilité supprimée');
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.responsableId == null) {
      return const Center(
        child: Text('Erreur: Responsable non identifié'),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildAvailabilityList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gérer mes disponibilités',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez vos créneaux disponibles pour les rendez-vous',
            style: TextStyle(
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addWeeklyAvailability,
                  icon: const Icon(Icons.repeat),
                  label: const Text('Récurrence hebdo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addSpecificDate,
                  icon: const Icon(Icons.today),
                  label: const Text('Date spécifique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityList() {
    return StreamBuilder<List<DisponibiliteModel>>(
      stream: AppointmentsFirebaseService.getDisponibilitesStream(widget.responsableId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final disponibilites = snapshot.data ?? [];

        if (disponibilites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 80,
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aucune disponibilité définie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez vos créneaux disponibles pour recevoir des demandes de rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disponibilites.length,
          itemBuilder: (context, index) {
            return _buildDisponibiliteCard(disponibilites[index]);
          },
        );
      },
    );
  }

  Widget _buildDisponibiliteCard(DisponibiliteModel disponibilite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  disponibilite.isRecurrenceHebdo ? Icons.repeat : Icons.today,
                  color: Theme.of(context).colorScheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDisponibiliteTitle(disponibilite),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteDisponibilite(disponibilite.id),
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (disponibilite.isRecurrenceHebdo) ...[
              Wrap(
                spacing: 8,
                children: disponibilite.jours.map((jour) {
                  return Chip(
                    label: Text(_formatJour(jour)),
                    backgroundColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primaryColor),
                  );
                }).toList(),
              ),
            ] else if (disponibilite.dateSpecifique != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDate(disponibilite.dateSpecifique!),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Créneaux horaires:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...disponibilite.creneaux.map((creneau) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.textTertiaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${creneau.debut} - ${creneau.fin}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${creneau.dureeRendezVous} min/RDV)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.textTertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getDisponibiliteTitle(DisponibiliteModel disponibilite) {
    if (disponibilite.isRecurrenceHebdo) {
      return 'Récurrence hebdomadaire';
    } else if (disponibilite.isPonctuel) {
      return 'Date spécifique';
    } else {
      return 'Disponibilité';
    }
  }

  String _formatJour(String jour) {
    return jour[0].toUpperCase() + jour.substring(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class _WeeklyAvailabilityDialog extends StatefulWidget {
  const _WeeklyAvailabilityDialog();

  @override
  State<_WeeklyAvailabilityDialog> createState() => _WeeklyAvailabilityDialogState();
}

class _WeeklyAvailabilityDialogState extends State<_WeeklyAvailabilityDialog> {
  final _formKey = GlobalKey<FormState>();
  Set<String> _selectedDays = {};
  List<CreneauHoraire> _creneaux = [];

  final List<String> _weekDays = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];

  final Map<String, String> _dayLabels = {
    'lundi': 'Lundi',
    'mardi': 'Mardi', 
    'mercredi': 'Mercredi',
    'jeudi': 'Jeudi',
    'vendredi': 'Vendredi',
    'samedi': 'Samedi',
    'dimanche': 'Dimanche',
  };

  void _addCreneau() {
    showDialog(
      context: context,
      builder: (context) => _CreneauDialog(
        onSave: (creneau) {
          setState(() => _creneaux.add(creneau));
        },
      ),
    );
  }

  void _removeCreneau(int index) {
    setState(() => _creneaux.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Disponibilité hebdomadaire'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jours de la semaine:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekDays.map((day) {
                  return FilterChip(
                    label: Text(_dayLabels[day]!),
                    selected: _selectedDays.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Créneaux horaires:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addCreneau,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              if (_creneaux.isEmpty)
                const Text('Aucun créneau défini')
              else
                ..._creneaux.asMap().entries.map((entry) {
                  final index = entry.key;
                  final creneau = entry.value;
                  return ListTile(
                    title: Text('${creneau.debut} - ${creneau.fin}'),
                    subtitle: Text('${creneau.dureeRendezVous} min/RDV'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeCreneau(index),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedDays.isNotEmpty && _creneaux.isNotEmpty
              ? () {
                  Navigator.pop(context, {
                    'jours': _selectedDays.toList(),
                    'creneaux': _creneaux,
                  });
                }
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _SpecificDateDialog extends StatefulWidget {
  const _SpecificDateDialog();

  @override
  State<_SpecificDateDialog> createState() => _SpecificDateDialogState();
}

class _SpecificDateDialogState extends State<_SpecificDateDialog> {
  DateTime? _selectedDate;
  List<CreneauHoraire> _creneaux = [];

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _addCreneau() {
    showDialog(
      context: context,
      builder: (context) => _CreneauDialog(
        onSave: (creneau) {
          setState(() => _creneaux.add(creneau));
        },
      ),
    );
  }

  void _removeCreneau(int index) {
    setState(() => _creneaux.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créneaux pour une date spécifique'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(_selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                        : 'Sélectionner une date'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Créneaux horaires:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addCreneau,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            if (_creneaux.isEmpty)
              const Text('Aucun créneau défini')
            else
              ..._creneaux.asMap().entries.map((entry) {
                final index = entry.key;
                final creneau = entry.value;
                return ListTile(
                  title: Text('${creneau.debut} - ${creneau.fin}'),
                  subtitle: Text('${creneau.dureeRendezVous} min/RDV'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeCreneau(index),
                  ),
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedDate != null && _creneaux.isNotEmpty
              ? () {
                  Navigator.pop(context, {
                    'date': _selectedDate,
                    'creneaux': _creneaux,
                  });
                }
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _CreneauDialog extends StatefulWidget {
  final Function(CreneauHoraire) onSave;

  const _CreneauDialog({required this.onSave});

  @override
  State<_CreneauDialog> createState() => _CreneauDialogState();
}

class _CreneauDialogState extends State<_CreneauDialog> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? _debut;
  TimeOfDay? _fin;
  int _duree = 30;

  Future<void> _selectDebut() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _debut = time);
    }
  }

  Future<void> _selectFin() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _fin = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau créneau'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDebut,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Début', style: TextStyle(fontSize: 12)),
                          Text(_debut?.format(context) ?? 'Sélectionner'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectFin,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fin', style: TextStyle(fontSize: 12)),
                          Text(_fin?.format(context) ?? 'Sélectionner'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _duree,
              decoration: const InputDecoration(
                labelText: 'Durée par rendez-vous',
                border: OutlineInputBorder(),
              ),
              items: [15, 30, 45, 60, 90, 120].map((duree) {
                return DropdownMenuItem(
                  value: duree,
                  child: Text('$duree minutes'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _duree = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _debut != null && _fin != null
              ? () {
                  final creneau = CreneauHoraire(
                    debut: '${_debut!.hour.toString().padLeft(2, '0')}:${_debut!.minute.toString().padLeft(2, '0')}',
                    fin: '${_fin!.hour.toString().padLeft(2, '0')}:${_fin!.minute.toString().padLeft(2, '0')}',
                    dureeRendezVous: _duree,
                  );
                  widget.onSave(creneau);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}