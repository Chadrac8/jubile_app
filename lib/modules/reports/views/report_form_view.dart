import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/base_page.dart';
import '../services/reports_service.dart';
import '../models/report.dart';

class ReportFormView extends StatefulWidget {
  final Report? report;
  final Map<String, dynamic>? initialData;
  final ReportTemplate? template;

  const ReportFormView({
    Key? key,
    this.report,
    this.initialData,
    this.template,
  }) : super(key: key);

  @override
  State<ReportFormView> createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<ReportFormView> {
  final _formKey = GlobalKey<FormState>();
  final ReportsService _service = ReportsService();
  
  // Contrôleurs de formulaire
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Variables d'état
  bool _isLoading = false;
  String _selectedType = 'custom';
  String _selectedFrequency = 'monthly';
  String? _selectedChartType;
  bool _isPublic = false;
  List<String> _selectedColumns = [];
  Map<String, dynamic> _parameters = {};
  Map<String, dynamic> _filters = {};
  
  // Options disponibles
  final List<String> _reportTypes = [
    'attendance',
    'financial',
    'membership',
    'event',
    'custom',
  ];
  
  final Map<String, String> _typeLabels = {
    'attendance': '👥 Présence',
    'financial': '💰 Financier',
    'membership': '👤 Membres',
    'event': '📅 Événements',
    'custom': '🔧 Personnalisé',
  };
  
  final List<String> _frequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
    'custom',
  ];
  
  final Map<String, String> _frequencyLabels = {
    'daily': 'Quotidien',
    'weekly': 'Hebdomadaire',
    'monthly': 'Mensuel',
    'yearly': 'Annuel',
    'custom': 'Personnalisé',
  };
  
  final List<String> _chartTypes = [
    'bar',
    'line',
    'pie',
    'table',
  ];
  
  final Map<String, String> _chartTypeLabels = {
    'bar': 'Barres',
    'line': 'Courbes',
    'pie': 'Secteurs',
    'table': 'Tableau',
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.report != null) {
      // Mode édition
      final report = widget.report!;
      _nameController.text = report.name;
      _descriptionController.text = report.description ?? '';
      _selectedType = report.type;
      _selectedFrequency = report.frequency;
      _selectedChartType = report.chartType;
      _isPublic = report.isPublic;
      _selectedColumns = List.from(report.dataColumns);
      _parameters = Map.from(report.parameters);
      _filters = Map.from(report.filters ?? {});
    } else if (widget.template != null) {
      // Création depuis template (nouveau paramètre)
      final template = widget.template!;
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedType = template.type;
      _selectedChartType = template.chartType;
      _selectedColumns = List.from(template.dataColumns);
      _parameters = Map.from(template.defaultParameters);
    } else if (widget.initialData != null) {
      // Création depuis template ou données initiales (ancien système)
      final data = widget.initialData!;
      final template = data['template'] as ReportTemplate?;
      
      if (template != null) {
        _nameController.text = template.name;
        _descriptionController.text = template.description;
        _selectedType = template.type;
        _selectedChartType = template.chartType;
        _selectedColumns = List.from(template.dataColumns);
        _parameters = Map.from(template.defaultParameters);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.report == null ? 'Nouveau rapport' : 'Modifier le rapport',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              // Configuration du rapport
              _buildConfigurationSection(),
              const SizedBox(height: 24),
              
              // Colonnes de données
              _buildDataColumnsSection(),
              const SizedBox(height: 24),
              
              // Filtres (section avancée)
              _buildFiltersSection(),
              const SizedBox(height: 24),
              
              // Paramètres avancés
              _buildAdvancedSection(),
              const SizedBox(height: 32),
              
              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nom du rapport
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du rapport *',
                hintText: 'Ex: Rapport mensuel de présence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez l\'objectif et le contenu de ce rapport',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Type de rapport
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de rapport *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _reportTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_typeLabels[type] ?? type),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _updateColumnsForType(value);
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sélectionnez un type de rapport';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Fréquence de génération
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence de génération',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _frequencies.map((frequency) => DropdownMenuItem(
                value: frequency,
                child: Text(_frequencyLabels[frequency] ?? frequency),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Type de graphique
            DropdownButtonFormField<String>(
              value: _selectedChartType,
              decoration: const InputDecoration(
                labelText: 'Type de visualisation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Aucune visualisation'),
                ),
                ..._chartTypes.map((chartType) => DropdownMenuItem(
                  value: chartType,
                  child: Text(_chartTypeLabels[chartType] ?? chartType),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedChartType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Visibilité publique
            SwitchListTile(
              title: const Text('Rapport public'),
              subtitle: const Text('Visible par tous les membres'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
              secondary: const Icon(Icons.public),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumnsSection() {
    final availableColumns = _getAvailableColumnsForType(_selectedType);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colonnes de données',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les données à inclure dans le rapport',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            if (availableColumns.isNotEmpty) 
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableColumns.map((column) {
                  final isSelected = _selectedColumns.contains(column);
                  return FilterChip(
                    label: Text(_formatColumnName(column)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedColumns.add(column);
                        } else {
                          _selectedColumns.remove(column);
                        }
                      });
                    },
                  );
                }).toList(),
              )
            else 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune colonne prédéfinie pour ce type de rapport. '
                        'Vous pourrez configurer les colonnes après la création.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Colonnes personnalisées
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Colonne personnalisée',
                      hintText: 'Ex: total_amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addCustomColumn,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres de données',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addFilter,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un filtre'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Définissez des critères pour filtrer les données du rapport',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            if (_filters.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.filter_list_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Aucun filtre défini - toutes les données seront incluses',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._filters.entries.map((entry) => _buildFilterItem(entry.key, entry.value)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Paramètres avancés'),
        subtitle: const Text('Configuration optionnelle'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Période de données par défaut
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Période de données par défaut',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'last_week', child: Text('Dernière semaine')),
                    DropdownMenuItem(value: 'last_month', child: Text('Dernier mois')),
                    DropdownMenuItem(value: 'last_quarter', child: Text('Dernier trimestre')),
                    DropdownMenuItem(value: 'last_year', child: Text('Dernière année')),
                    DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _parameters['default_period'] = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Nombre maximum de résultats
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre maximum de résultats',
                    hintText: 'Laissez vide pour illimité',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _parameters['max_results'] = int.tryParse(value);
                    } else {
                      _parameters.remove('max_results');
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Tri par défaut
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tri par défaut',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name_asc', child: Text('Nom (A-Z)')),
                    DropdownMenuItem(value: 'name_desc', child: Text('Nom (Z-A)')),
                    DropdownMenuItem(value: 'date_asc', child: Text('Date (croissant)')),
                    DropdownMenuItem(value: 'date_desc', child: Text('Date (décroissant)')),
                    DropdownMenuItem(value: 'value_asc', child: Text('Valeur (croissant)')),
                    DropdownMenuItem(value: 'value_desc', child: Text('Valeur (décroissant)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _parameters['default_sort'] = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String key, dynamic value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(_formatColumnName(key)),
        subtitle: Text('Filtre: ${value.toString()}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _filters.remove(key);
            });
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveReport,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isLoading
                  ? 'Enregistrement...'
                  : widget.report == null
                      ? 'Créer le rapport'
                      : 'Mettre à jour',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        if (widget.report == null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _saveAndGenerate,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Créer et générer maintenant'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Méthodes d'action
  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reportData = _buildReportData();

      if (widget.report == null) {
        // Création
        final docRef = await _service.collection.add(reportData);
        final reportId = docRef.id;
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rapport créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Modification
        await _service.collection.doc(widget.report!.id).update(reportData);
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rapport modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reportData = _buildReportData();
      final docRef = await _service.collection.add(reportData);
      final reportId = docRef.id;
      
      // Créer l'objet Report pour la génération
      final report = Report(
        id: reportId,
        name: reportData['name'],
        description: reportData['description'],
        type: reportData['type'],
        createdAt: DateTime.now(),
        createdBy: reportData['createdBy'],
        parameters: reportData['parameters'],
        chartType: reportData['chartType'],
        dataColumns: List<String>.from(reportData['dataColumns']),
        filters: reportData['filters'],
        frequency: reportData['frequency'],
        isPublic: reportData['isPublic'],
      );
      
      // Générer le rapport
      await _service.generateReportData(report);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport créé et généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Naviguer vers la vue détail
        Navigator.of(context).pushNamed('/reports/detail', arguments: report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildReportData() {
    return {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      'type': _selectedType,
      'frequency': _selectedFrequency,
      'chartType': _selectedChartType,
      'isPublic': _isPublic,
      'dataColumns': _selectedColumns,
      'parameters': _parameters,
      'filters': _filters.isEmpty ? null : _filters,
      'createdBy': 'current_user_id', // TODO: Obtenir l'ID utilisateur réel
      'isActive': true,
      'generationCount': 0,
      'sharedWith': [],
      if (widget.report == null) 'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  // Méthodes utilitaires
  void _updateColumnsForType(String type) {
    final availableColumns = _getAvailableColumnsForType(type);
    setState(() {
      _selectedColumns = _selectedColumns
          .where((column) => availableColumns.contains(column))
          .toList();
    });
  }

  List<String> _getAvailableColumnsForType(String type) {
    switch (type) {
      case 'attendance':
        return ['date', 'service_name', 'attendance_count', 'registered_count', 'attendance_rate'];
      case 'financial':
        return ['date', 'amount', 'donor_name', 'donation_type', 'category'];
      case 'membership':
        return ['name', 'join_date', 'age_group', 'status', 'groups'];
      case 'event':
        return ['event_name', 'date', 'registered', 'attended', 'satisfaction_score'];
      default:
        return [];
    }
  }

  void _addCustomColumn() {
    // TODO: Implémenter l'ajout de colonne personnalisée
  }

  void _addFilter() {
    // TODO: Implémenter l'ajout de filtre
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un filtre'),
        content: const Text('Fonctionnalité à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatColumnName(String column) {
    return column
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}