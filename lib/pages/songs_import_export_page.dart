import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_import_export_service.dart';
import '../services/songs_firebase_service.dart';
// import '../examples/sample_songs_data.dart';

/// Page pour l'import/export des chants
class SongsImportExportPage extends StatefulWidget {
  const SongsImportExportPage({super.key});

  @override
  State<SongsImportExportPage> createState() => _SongsImportExportPageState();
}

class _SongsImportExportPageState extends State<SongsImportExportPage> {
  bool _isLoading = false;
  List<SongModel>? _importedSongs;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import/Export des Chants'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Guide d\'utilisation',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Export
            _buildExportSection(),
            
            const SizedBox(height: 32),
            
            // Section Import
            _buildImportSection(),
            
            const SizedBox(height: 32),
            
            // Prévisualisation des chants importés
            if (_importedSongs != null) _buildImportPreview(),
            
            // Section développement (optionnelle)
            const SizedBox(height: 32),
            _buildDeveloperSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Exporter les chants',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Exportez tous vos chants dans un fichier pour sauvegarde ou partage.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Boutons d'export
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _exportSongs('csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Exporter en CSV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _exportSongs('txt'),
                    icon: const Icon(Icons.text_snippet),
                    label: const Text('Exporter en TXT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations sur les formats
            ExpansionTile(
              title: const Text('Informations sur les formats'),
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Format CSV'),
                  subtitle: const Text('Idéal pour Excel, Google Sheets ou autres tableurs. Conserve toutes les données structurées.'),
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet),
                  title: const Text('Format TXT'),
                  subtitle: const Text('Format texte simple, facile à lire. Parfait pour l\'archivage ou l\'impression.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_upload, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Importer des chants',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Importez des chants depuis un fichier CSV ou TXT.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Boutons d'import
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _importSongs('csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Importer CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _importSongs('txt'),
                    icon: const Icon(Icons.text_snippet),
                    label: const Text('Importer TXT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Instructions d'import
            ExpansionTile(
              title: const Text('Instructions d\'import'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Format CSV requis:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('• Première ligne: en-têtes (doit contenir au moins "Titre")'),
                      const Text('• Colonnes recommandées: Titre, Auteurs, Paroles, Tonalité originale, Style'),
                      const Text('• Séparateur: virgule (,)'),
                      const Text('• Encodage: UTF-8'),
                      const SizedBox(height: 16),
                      Text(
                        'Format TXT:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('• Un chant par section'),
                      const Text('• Séparateur entre chants: --- (3 tirets)'),
                      const Text('• Format: CHAMP: valeur'),
                      const Text('• Paroles après "PAROLES:"'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Prévisualisation (${_importedSongs!.length} chants)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Liste des chants importés
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _importedSongs!.length > 5 ? 5 : _importedSongs!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final song = _importedSongs![index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (song.authors.isNotEmpty) Text('Auteurs: ${song.authors}'),
                      Text('Style: ${song.style} • Tonalité: ${song.originalKey}'),
                    ],
                  ),
                  trailing: Icon(
                    song.title.isEmpty ? Icons.warning : Icons.check_circle,
                    color: song.title.isEmpty ? Colors.orange : Colors.green,
                  ),
                );
              },
            ),
            
            if (_importedSongs!.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '... et ${_importedSongs!.length - 5} autres chants',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveImportedSongs,
                    icon: const Icon(Icons.save),
                    label: const Text('Sauvegarder tous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearImport,
                    icon: const Icon(Icons.clear),
                    label: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSongs(String format) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer tous les chants
      final songs = await SongsFirebaseService.getAllSongs();
      
      if (songs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun chant à exporter'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Exporter selon le format
      if (format == 'csv') {
        await SongsImportExportService.exportToCSV(songs);
      } else {
        await SongsImportExportService.exportToTXT(songs);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${songs.length} chants exportés en ${format.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
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

  Future<void> _importSongs(String format) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<SongModel> songs;
      
      if (format == 'csv') {
        songs = await SongsImportExportService.importFromCSV();
      } else {
        songs = await SongsImportExportService.importFromTXT();
      }

      setState(() {
        _importedSongs = songs;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${songs.length} chants importés. Vérifiez et sauvegardez.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
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

  Future<void> _saveImportedSongs() async {
    if (_importedSongs == null || _importedSongs!.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SongsImportExportService.saveSongs(_importedSongs!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_importedSongs!.length} chants sauvegardés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _clearImport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
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

  void _clearImport() {
    setState(() {
      _importedSongs = null;
    });
  }

  Widget _buildDeveloperSection() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Outils de développement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Générez des données d\'exemple pour tester les fonctionnalités d\'import/export.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadSampleData,
              icon: const Icon(Icons.data_usage),
              label: const Text('Charger des données d\'exemple'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadSampleData() {
    setState(() {
      _importedSongs = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aucune donnée d\'exemple disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Guide d\'utilisation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Formats supportés',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text('• CSV : Compatible avec Excel, Google Sheets'),
              const Text('• TXT : Format texte simple et lisible'),
              const SizedBox(height: 16),
              
              Text(
                'Champs requis pour l\'import',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text('• Titre (obligatoire)'),
              const Text('• Auteurs (recommandé)'),
              const Text('• Paroles (recommandé)'),
              const Text('• Tonalité originale (recommandé)'),
              const SizedBox(height: 16),
              
              Text(
                'Conseils',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text('• Testez avec les données d\'exemple'),
              const Text('• Vérifiez la prévisualisation avant de sauvegarder'),
              const Text('• Assurez-vous que vos fichiers sont en UTF-8'),
              const Text('• Utilisez "---" pour séparer les chants en TXT'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}