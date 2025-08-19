import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../services/appointments_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class AvailabilityEditor extends StatefulWidget {
  final String? responsableId;
  final VoidCallback? onChanged;

  const AvailabilityEditor({
    super.key,
    this.responsableId,
    this.onChanged,
  });

  @override
  State<AvailabilityEditor> createState() => _AvailabilityEditorState();
}

class _AvailabilityEditorState extends State<AvailabilityEditor>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _currentResponsableId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _initializeResponsable();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeResponsable() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        setState(() {
          _currentResponsableId = widget.responsableId ?? currentUser.uid;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWeeklyRecurrence() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _WeeklyRecurrenceDialog(),
    );
    
    if (result != null && _currentResponsableId != null) {
      try {
        final disponibilite = DisponibiliteModel(
          id: '',
          responsableId: _currentResponsableId!,
          type: 'recurrence_hebdo',
          jours: result['jours'] as List<String>,
          creneaux: result['creneaux'] as List<CreneauHoraire>,
          dateDebut: result['dateDebut'] as DateTime?,
          dateFin: result['dateFin'] as DateTime?,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await AppointmentsFirebaseService.createDisponibilite(disponibilite);
        widget.onChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Créneaux récurrents ajoutés avec succès'),
              backgroundColor: Theme.of(context).colorScheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSpecificDate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _SpecificDateDialog(),
    );
    
    if (result != null && _currentResponsableId != null) {
      try {
        final disponibilite = DisponibiliteModel(
          id: '',
          responsableId: _currentResponsableId!,
          type: 'ponctuel',
          creneaux: result['creneaux'] as List<CreneauHoraire>,
          dateSpecifique: result['date'] as DateTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await AppointmentsFirebaseService.createDisponibilite(disponibilite);
        widget.onChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Créneau spécifique ajouté avec succès'),
              backgroundColor: Theme.of(context).colorScheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.errorColor,
            ),
          );
        }
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await AppointmentsFirebaseService.deleteDisponibilite(disponibiliteId);
        widget.onChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disponibilité supprimée'),
              backgroundColor: Theme.of(context).colorScheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_currentResponsableId == null) {
      return const Center(
        child: Text('Impossible de charger les disponibilités'),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildDisponibilitesList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gestion des disponibilités',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addWeeklyRecurrence,
                  icon: const Icon(Icons.repeat, size: 16),
                  label: const Text('Récurrence hebdo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSpecificDate,
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Date spécifique'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primaryColor,
                    side: BorderSide(color: Theme.of(context).colorScheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisponibilitesList() {
    if (_currentResponsableId == null) {
      return const Center(child: Text('Aucun responsable sélectionné'));
    }

    return StreamBuilder<List<DisponibiliteModel>>(
      stream: AppointmentsFirebaseService.getDisponibilitesStream(_currentResponsableId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final disponibilites = snapshot.data ?? [];

        if (disponibilites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune disponibilité définie',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des créneaux pour permettre aux membres de prendre rendez-vous',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: disponibilites.length,
          itemBuilder: (context, index) {
            final disponibilite = disponibilites[index];
            return _buildDisponibiliteCard(disponibilite);
          },
        );
      },
    );
  }

  Widget _buildDisponibiliteCard(DisponibiliteModel disponibilite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    disponibilite.type == 'recurrence_hebdo' ? Icons.repeat : Icons.event,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDisponibiliteTitle(disponibilite),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.textPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteDisponibilite(disponibilite.id),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (disponibilite.type == 'recurrence_hebdo' && disponibilite.jours.isNotEmpty)
              Wrap(
                spacing: 8,
                children: disponibilite.jours.map((jour) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatJour(jour),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (disponibilite.dateSpecifique != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(disponibilite.dateSpecifique!),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: disponibilite.creneaux.map((creneau) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${creneau.debut} - ${creneau.fin}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.tertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisponibiliteTitle(DisponibiliteModel disponibilite) {
    switch (disponibilite.type) {
      case 'recurrence_hebdo':
        return 'Récurrence hebdomadaire';
      case 'recurrence_mensuelle':
        return 'Récurrence mensuelle';
      case 'ponctuel':
        return 'Créneau ponctuel';
      default:
        return 'Disponibilité';
    }
  }

  String _formatJour(String jour) {
    switch (jour.toLowerCase()) {
      case 'lundi':
        return 'Lun';
      case 'mardi':
        return 'Mar';
      case 'mercredi':
        return 'Mer';
      case 'jeudi':
        return 'Jeu';
      case 'vendredi':
        return 'Ven';
      case 'samedi':
        return 'Sam';
      case 'dimanche':
        return 'Dim';
      default:
        return jour;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }
}

// Dialog pour créer une récurrence hebdomadaire
class _WeeklyRecurrenceDialog extends StatefulWidget {
  const _WeeklyRecurrenceDialog();

  @override
  State<_WeeklyRecurrenceDialog> createState() => _WeeklyRecurrenceDialogState();
}

class _WeeklyRecurrenceDialogState extends State<_WeeklyRecurrenceDialog> {
  final _formKey = GlobalKey<FormState>();
  Set<String> _selectedDays = {};
  List<CreneauHoraire> _creneaux = [];
  DateTime? _dateDebut;
  DateTime? _dateFin;

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

  void _addCreneau() async {
    final creneau = await showDialog<CreneauHoraire>(
      context: context,
      builder: (context) => _CreneauDialog(),
    );
    
    if (creneau != null) {
      setState(() {
        _creneaux.add(creneau);
      });
    }
  }

  void _removeCreneau(int index) {
    setState(() {
      _creneaux.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Récurrence hebdomadaire'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jours de la semaine:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabels[day]!),
                    selected: isSelected,
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
                  const Text('Créneaux horaires:'),
                  IconButton(
                    onPressed: _addCreneau,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_creneaux.isEmpty)
                const Text('Aucun créneau défini', style: TextStyle(color: Colors.grey))
              else
                Column(
                  children: _creneaux.asMap().entries.map((entry) {
                    final index = entry.key;
                    final creneau = entry.value;
                    return ListTile(
                      title: Text('${creneau.debut} - ${creneau.fin}'),
                      trailing: IconButton(
                        onPressed: () => _removeCreneau(index),
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  }).toList(),
                ),
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
                    'dateDebut': _dateDebut,
                    'dateFin': _dateFin,
                  });
                }
              : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

// Dialog pour créer un créneau spécifique
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _addCreneau() async {
    final creneau = await showDialog<CreneauHoraire>(
      context: context,
      builder: (context) => _CreneauDialog(),
    );
    
    if (creneau != null) {
      setState(() {
        _creneaux.add(creneau);
      });
    }
  }

  void _removeCreneau(int index) {
    setState(() {
      _creneaux.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Date spécifique'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(_selectedDate != null 
                ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate!)
                : 'Sélectionner une date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Créneaux:'),
              IconButton(
                onPressed: _addCreneau,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_creneaux.isEmpty)
            const Text('Aucun créneau', style: TextStyle(color: Colors.grey))
          else
            Column(
              children: _creneaux.asMap().entries.map((entry) {
                final index = entry.key;
                final creneau = entry.value;
                return ListTile(
                  title: Text('${creneau.debut} - ${creneau.fin}'),
                  trailing: IconButton(
                    onPressed: () => _removeCreneau(index),
                    icon: const Icon(Icons.delete),
                  ),
                );
              }).toList(),
            ),
        ],
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
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

// Dialog pour créer un créneau horaire
class _CreneauDialog extends StatefulWidget {
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
      setState(() {
        _debut = time;
      });
    }
  }

  Future<void> _selectFin() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _debut ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _fin = time;
      });
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
            ListTile(
              title: Text(_debut != null ? '${_debut!.hour.toString().padLeft(2, '0')}:${_debut!.minute.toString().padLeft(2, '0')}' : 'Heure de début'),
              trailing: const Icon(Icons.access_time),
              onTap: _selectDebut,
            ),
            ListTile(
              title: Text(_fin != null ? '${_fin!.hour.toString().padLeft(2, '0')}:${_fin!.minute.toString().padLeft(2, '0')}' : 'Heure de fin'),
              trailing: const Icon(Icons.access_time),
              onTap: _selectFin,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _duree,
              decoration: const InputDecoration(
                labelText: 'Durée des RDV (minutes)',
                border: OutlineInputBorder(),
              ),
              items: [15, 30, 45, 60, 90, 120].map((duree) {
                return DropdownMenuItem(
                  value: duree,
                  child: Text('$duree minutes'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _duree = value;
                  });
                }
              },
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
                  Navigator.pop(context, creneau);
                }
              : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}