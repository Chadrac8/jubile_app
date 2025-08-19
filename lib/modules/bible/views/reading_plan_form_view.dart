import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/reading_plan.dart';

class ReadingPlanFormView extends StatefulWidget {
  final ReadingPlan? plan;
  final VoidCallback? onSaved;

  const ReadingPlanFormView({
    Key? key,
    this.plan,
    this.onSaved,
  }) : super(key: key);

  @override
  State<ReadingPlanFormView> createState() => _ReadingPlanFormViewState();
}

class _ReadingPlanFormViewState extends State<ReadingPlanFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  // Contrôleurs pour les champs de base
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalDaysController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  
  String _selectedCategory = 'Classique';
  String _selectedDifficulty = 'beginner';
  bool _isPopular = false;
  bool _isSaving = false;
  
  // Liste des jours du plan
  List<ReadingPlanDay> _days = [];
  
  // Contrôleurs pour l'ajout de jour
  final _dayTitleController = TextEditingController();
  final _dayReflectionController = TextEditingController();
  final _dayPrayerController = TextEditingController();
  List<BibleReference> _dayReadings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.plan != null) {
      _loadExistingPlan();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _totalDaysController.dispose();
    _estimatedTimeController.dispose();
    _dayTitleController.dispose();
    _dayReflectionController.dispose();
    _dayPrayerController.dispose();
    super.dispose();
  }

  void _loadExistingPlan() {
    final plan = widget.plan!;
    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _totalDaysController.text = plan.totalDays.toString();
    _estimatedTimeController.text = plan.estimatedReadingTime.toString();
    _selectedCategory = plan.category;
    _selectedDifficulty = plan.difficulty;
    _isPopular = plan.isPopular;
    _days = List.from(plan.days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.plan == null ? 'Nouveau plan' : 'Modifier le plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePlan,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    'Sauvegarder',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
              ]),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary),
              labelColor: AppTheme.surfaceColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Informations'),
                Tab(text: 'Jours'),
                Tab(text: 'Aperçu'),
              ])))),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildDaysTab(),
            _buildPreviewTab(),
          ])));
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du plan
          Text(
            'Informations de base',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom du plan *',
              hintText: 'Ex: Bible en 1 an',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est obligatoire';
              }
              return null;
            }),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez le contenu et l\'objectif de ce plan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La description est obligatoire';
              }
              return null;
            }),
          
          const SizedBox(height: 20),
          
          // Catégorie et difficulté
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  items: [
                    'Classique',
                    'Nouveau Testament',
                    'Psaumes',
                    'Évangiles',
                    'Sagesse',
                    'Prophétique',
                    'Historique',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  })),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: 'Difficulté',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDifficulty = value!);
                  })),
            ]),
          
          const SizedBox(height: 16),
          
          // Durée et temps estimé
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _totalDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nombre de jours *',
                    hintText: '365',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Obligatoire';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days <= 0) {
                      return 'Nombre invalide';
                    }
                    return null;
                  })),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _estimatedTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Temps/jour (min) *',
                    hintText: '15',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Obligatoire';
                    }
                    final time = int.tryParse(value);
                    if (time == null || time <= 0) {
                      return 'Temps invalide';
                    }
                    return null;
                  })),
            ]),
          
          const SizedBox(height: 20),
          
          // Options
          Text(
            'Options',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          SwitchListTile(
            title: Text(
              'Plan populaire',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            subtitle: Text(
              'Mettre en avant ce plan dans la section populaires',
              style: GoogleFonts.inter(fontSize: 12)),
            value: _isPopular,
            onChanged: (value) {
              setState(() => _isPopular = value);
            }),
        ]));
  }

  Widget _buildDaysTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // En-tête avec compteur
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${_days.length} jour(s) configuré(s)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addDay,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter')),
            ])),
        
        // Liste des jours
        Expanded(
          child: _days.isEmpty
              ? _buildEmptyDaysState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    return _buildDayCard(_days[index], index);
                  })),
      ]);
  }

  Widget _buildPreviewTab() {
    if (_days.isEmpty) {
      return const Center(
        child: Text('Ajoutez des jours pour voir l\'aperçu'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu du plan',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Informations générales
          _buildPreviewInfo(),
          
          const SizedBox(height: 24),
          
          // Premiers jours
          Text(
            'Premiers jours (aperçu)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ..._days.take(3).map((day) => _buildPreviewDayCard(day)),
          
          if (_days.length > 3)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                '... et ${_days.length - 3} autres jours',
                style: GoogleFonts.inter(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))),
        ]));
  }

  Widget _buildPreviewInfo() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameController.text.isEmpty ? 'Nom du plan' : _nameController.text,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty 
                ? 'Description du plan' 
                : _descriptionController.text,
            style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPreviewChip('Catégorie: $_selectedCategory'),
              const SizedBox(width: 8),
              _buildPreviewChip('${_totalDaysController.text} jours'),
              const SizedBox(width: 8),
              _buildPreviewChip('${_estimatedTimeController.text}min/jour'),
            ]),
        ]));
  }

  Widget _buildPreviewChip(String label) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12)));
  }

  Widget _buildPreviewDayCard(ReadingPlanDay day) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jour ${day.day}: ${day.title}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Lectures: ${day.readings.map((r) => r.displayText).join(', ')}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
        ]));
  }

  Widget _buildEmptyDaysState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucun jour configuré',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des jours pour construire votre plan',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addDay,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un jour')),
        ]));
  }

  Widget _buildDayCard(ReadingPlanDay day, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Jour ${day.day}: ${day.title}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Lectures: ${day.readings.map((r) => r.displayText).join(', ')}',
          style: GoogleFonts.inter(fontSize: 12)),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleDayAction(action, index),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ]),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.reflection != null) ...[
                  Text(
                    'Réflexion:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(day.reflection!),
                  const SizedBox(height: 8),
                ],
                if (day.prayer != null) ...[
                  Text(
                    'Prière:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(day.prayer!),
                ],
              ])),
        ]));
  }

  void _addDay() {
    _showDayDialog();
  }

  void _handleDayAction(String action, int index) {
    switch (action) {
      case 'edit':
        _editDay(index);
        break;
      case 'duplicate':
        _duplicateDay(index);
        break;
      case 'delete':
        _deleteDay(index);
        break;
    }
  }

  void _editDay(int index) {
    _showDayDialog(day: _days[index], index: index);
  }

  void _duplicateDay(int index) {
    final originalDay = _days[index];
    final newDay = ReadingPlanDay(
      day: _days.length + 1,
      title: '${originalDay.title} (copie)',
      readings: List.from(originalDay.readings),
      reflection: originalDay.reflection,
      prayer: originalDay.prayer);
    
    setState(() {
      _days.add(newDay);
    });
  }

  void _deleteDay(int index) {
    setState(() {
      _days.removeAt(index);
      // Réorganiser les numéros de jours
      for (int i = 0; i < _days.length; i++) {
        _days[i] = ReadingPlanDay(
          day: i + 1,
          title: _days[i].title,
          readings: _days[i].readings,
          reflection: _days[i].reflection,
          prayer: _days[i].prayer);
      }
    });
  }

  void _showDayDialog({ReadingPlanDay? day, int? index}) {
    // Réinitialiser les contrôleurs
    _dayTitleController.clear();
    _dayReflectionController.clear();
    _dayPrayerController.clear();
    _dayReadings.clear();
    
    if (day != null) {
      _dayTitleController.text = day.title;
      _dayReflectionController.text = day.reflection ?? '';
      _dayPrayerController.text = day.prayer ?? '';
      _dayReadings = List.from(day.readings);
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(day == null ? 'Ajouter un jour' : 'Modifier le jour'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _dayTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre du jour',
                    hintText: 'Ex: Les commencements')),
                const SizedBox(height: 16),
                
                // Lectures
                Row(
                  children: [
                    Text(
                      'Lectures (${_dayReadings.length})',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _addReading(setState),
                      child: const Text('Ajouter')),
                  ]),
                
                ..._dayReadings.asMap().entries.map((entry) {
                  return ListTile(
                    dense: true,
                    title: Text(entry.value.displayText),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        setState(() {
                          _dayReadings.removeAt(entry.key);
                        });
                      }));
                }),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _dayReflectionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Réflexion (optionnel)',
                    hintText: 'Réflexion pour ce jour...')),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _dayPrayerController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Prière (optionnel)',
                    hintText: 'Prière pour ce jour...')),
              ])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                if (_dayTitleController.text.trim().isNotEmpty) {
                  _saveDayDialog(day, index);
                  Navigator.pop(context);
                }
              },
              child: const Text('Sauvegarder')),
          ])));
  }

  void _addReading(StateSetter setState) {
    showDialog(
      context: context,
      builder: (context) {
        String book = 'Genèse';
        int? chapter;
        int? startVerse;
        int? endVerse;
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Ajouter une lecture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: book,
                  decoration: const InputDecoration(labelText: 'Livre'),
                  items: [
                    'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
                    'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
                    'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
                    'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique',
                    // Ajoutez d'autres livres selon vos besoins
                  ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (value) {
                    setDialogState(() => book = value!);
                  }),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Chapitre',
                    hintText: '1'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    chapter = int.tryParse(value);
                  }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Verset début',
                          hintText: '1'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          startVerse = int.tryParse(value);
                        })),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Verset fin',
                          hintText: '10'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          endVerse = int.tryParse(value);
                        })),
                  ]),
              ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
              TextButton(
                onPressed: () {
                  final reading = BibleReference(
                    book: book,
                    chapter: chapter,
                    startVerse: startVerse,
                    endVerse: endVerse);
                  
                  setState(() {
                    _dayReadings.add(reading);
                  });
                  
                  Navigator.pop(context);
                },
                child: const Text('Ajouter')),
            ]));
      });
  }

  void _saveDayDialog(ReadingPlanDay? existingDay, int? index) {
    final newDay = ReadingPlanDay(
      day: existingDay?.day ?? _days.length + 1,
      title: _dayTitleController.text.trim(),
      readings: List.from(_dayReadings),
      reflection: _dayReflectionController.text.trim().isEmpty 
          ? null 
          : _dayReflectionController.text.trim(),
      prayer: _dayPrayerController.text.trim().isEmpty 
          ? null 
          : _dayPrayerController.text.trim());
    
    setState(() {
      if (index != null) {
        _days[index] = newDay;
      } else {
        _days.add(newDay);
      }
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Aller à l'onglet info
      return;
    }
    
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un jour au plan')));
      _tabController.animateTo(1); // Aller à l'onglet jours
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final plan = ReadingPlan(
        id: widget.plan?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        totalDays: int.parse(_totalDaysController.text),
        estimatedReadingTime: int.parse(_estimatedTimeController.text),
        difficulty: _selectedDifficulty,
        days: _days,
        createdAt: widget.plan?.createdAt ?? DateTime.now(),
        isPopular: _isPopular);
      
      // TODO: Sauvegarder le plan via le service
      await _savePlanToStorage(plan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.plan == null 
                  ? 'Plan créé avec succès' 
                  : 'Plan mis à jour avec succès'
            ),
            backgroundColor: AppTheme.successColor));
        
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _savePlanToStorage(ReadingPlan plan) async {
    // TODO: Implémenter la sauvegarde réelle
    // Pour l'instant, on simule une sauvegarde
    await Future.delayed(const Duration(seconds: 1));
    
    // Dans une vraie implémentation, on sauvegarderait dans:
    // - Firestore pour la persistance
    // - Le cache local pour l'accès rapide
  }
}
