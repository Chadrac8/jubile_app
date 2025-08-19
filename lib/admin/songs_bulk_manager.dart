import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import 'quick_songs_actions.dart';
import 'song_status_info_page.dart';

/// Gestionnaire pour les opérations en masse sur les chants
class SongsBulkManager extends StatefulWidget {
  const SongsBulkManager({super.key});

  @override
  State<SongsBulkManager> createState() => _SongsBulkManagerState();
}

class _SongsBulkManagerState extends State<SongsBulkManager> {
  bool _isLoading = false;
  bool _showDraftsOnly = true;
  List<SongModel> _selectedSongs = [];
  Map<String, int> _statusCounts = {};
  String? _bulkStatusTarget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion en masse des chants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SongStatusInfoPage()));
            },
            tooltip: 'À propos des statuts'),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Aide'),
        ]),
      body: Column(
        children: [
          // Actions rapides
          const QuickSongsActions(),
          
          // Statistiques et filtres
          _buildStatsAndFilters(),
          
          // Actions en masse
          if (_selectedSongs.isNotEmpty) _buildBulkActions(),
          
          // Liste des chants
          Expanded(
            child: _buildSongsList()),
        ]));
  }

  Widget _buildStatsAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques
          FutureBuilder<Map<String, int>>(
            future: _getStatusStatistics(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _statusCounts = snapshot.data!;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusCounts.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: _getStatusColor(entry.key).withValues(alpha: 0.2));
                  }).toList());
              }
              return const CircularProgressIndicator();
            }),
          
          const SizedBox(height: 16),
          
          // Filtres
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Afficher uniquement les brouillons'),
                  subtitle: Text(_showDraftsOnly 
                      ? 'Seuls les chants en "draft" sont affichés'
                      : 'Tous les chants sont affichés'),
                  value: _showDraftsOnly,
                  onChanged: (value) {
                    setState(() {
                      _showDraftsOnly = value;
                      _selectedSongs.clear();
                    });
                  })),
            ]),
        ]));
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          top: BorderSide(color: Colors.blue.shade200),
          bottom: BorderSide(color: Colors.blue.shade200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedSongs.length} chant(s) sélectionné(s)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Nouveau statut',
                    border: OutlineInputBorder()),
                  value: _bulkStatusTarget,
                  items: const [
                    DropdownMenuItem(value: 'published', child: Text('Publié')),
                    DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                    DropdownMenuItem(value: 'pending', child: Text('En attente')),
                    DropdownMenuItem(value: 'archived', child: Text('Archivé')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _bulkStatusTarget = value;
                    });
                  })),
              const SizedBox(width: 16),
              
              ElevatedButton.icon(
                onPressed: _bulkStatusTarget != null && !_isLoading
                    ? _performBulkStatusChange
                    : null,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.update),
                label: Text(_isLoading ? 'Traitement...' : 'Appliquer')),
              
              const SizedBox(width: 8),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSongs.clear();
                  });
                },
                child: const Text('Tout désélectionner')),
            ]),
        ]));
  }

  Widget _buildSongsList() {
    return StreamBuilder<List<SongModel>>(
      stream: _showDraftsOnly 
          ? SongsFirebaseService.advancedSearchSongs(status: 'draft', includeAllStatuses: false)
          : SongsFirebaseService.getAllSongsNoFilter(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer')),
              ]));
        }

        final songs = snapshot.data ?? [];

        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, color: AppTheme.textTertiaryColor),
                const SizedBox(height: 16),
                Text(
                  _showDraftsOnly 
                      ? 'Aucun chant en brouillon'
                      : 'Aucun chant disponible',
                  style: TextStyle(color: AppTheme.textTertiaryColor)),
              ]));
        }

        return Column(
          children: [
            // Actions de sélection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: songs.isEmpty ? null : () {
                      setState(() {
                        _selectedSongs = List.from(songs);
                      });
                    },
                    icon: const Icon(Icons.select_all),
                    label: const Text('Tout sélectionner')),
                  
                  const SizedBox(width: 16),
                  
                  Text(
                    '${songs.length} chant(s) affiché(s)',
                    style: TextStyle(color: AppTheme.textTertiaryColor)),
                ])),
            
            // Liste
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isSelected = _selectedSongs.any((s) => s.id == song.id);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedSongs.add(song);
                        } else {
                          _selectedSongs.removeWhere((s) => s.id == song.id);
                        }
                      });
                    },
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auteur: ${song.authors}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(song.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                song.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(song.status)))),
                            const SizedBox(width: 8),
                            Text(
                              'Visibilité: ${song.visibility}',
                              style: TextStyle(fontSize: 12, color: AppTheme.textTertiaryColor)),
                          ]),
                      ]),
                    secondary: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showSongDetails(song)));
                })),
          ]);
      });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return AppTheme.successColor;
      case 'draft':
        return AppTheme.warningColor;
      case 'pending':
        return Colors.blue;
      case 'archived':
        return AppTheme.textTertiaryColor;
      default:
        return Colors.black;
    }
  }

  Future<Map<String, int>> _getStatusStatistics() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('songs').get();
      final statusCounts = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      
      return statusCounts;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  Future<void> _performBulkStatusChange() async {
    if (_bulkStatusTarget == null || _selectedSongs.isEmpty) return;

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final song in _selectedSongs) {
        final docRef = FirebaseFirestore.instance.collection('songs').doc(song.id);
        batch.update(docRef, {
          'status': _bulkStatusTarget,
          'updatedAt': FieldValue.serverTimestamp(),
          'modifiedBy': 'bulk_manager', // Vous pouvez mettre l'ID de l'utilisateur actuel ici
        });
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedSongs.length} chant(s) mis à jour vers le statut "$_bulkStatusTarget"'),
            backgroundColor: AppTheme.successColor));
        
        setState(() {
          _selectedSongs.clear();
          _bulkStatusTarget = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la modification'),
        content: Text(
          'Êtes-vous sûr de vouloir changer le statut de ${_selectedSongs.length} chant(s) vers "$_bulkStatusTarget" ?\n\n'
          'Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer')),
        ])) ?? false;
  }

  void _showSongDetails(SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(song.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Auteur', song.authors),
              _buildDetailRow('Statut', song.status),
              _buildDetailRow('Visibilité', song.visibility),
              _buildDetailRow('Clé', song.originalKey),
              _buildDetailRow('Tags', song.tags.join(', ')),
              _buildDetailRow('Créé le', song.createdAt.toString().split(' ')[0]),
              _buildDetailRow('Modifié le', song.updatedAt.toString().split(' ')[0]),
              _buildDetailRow('Utilisations', song.usageCount.toString()),
              if (song.lyrics.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Paroles:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiaryColor,
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    song.lyrics.length > 200 
                        ? '${song.lyrics.substring(0, 200)}...'
                        : song.lyrics,
                    style: const TextStyle(fontSize: 12))),
              ],
            ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer')),
        ]));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: Text(value.isEmpty ? 'Non défini' : value)),
        ]));
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Gestion en masse'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cette page vous permet de gérer les statuts des chants en masse.\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Statuts disponibles:'),
              SizedBox(height: 8),
              Text('• Draft: Brouillon, non visible par les membres'),
              Text('• Published: Publié, visible par tous'),
              Text('• Pending: En attente d\'approbation'),
              Text('• Archived: Archivé, masqué de la liste principale'),
              SizedBox(height: 16),
              Text('Utilisation:'),
              SizedBox(height: 8),
              Text('1. Filtrez les chants par statut si nécessaire'),
              Text('2. Sélectionnez les chants à modifier'),
              Text('3. Choisissez le nouveau statut'),
              Text('4. Cliquez sur "Appliquer"'),
              SizedBox(height: 16),
              Text(
                'Conseil: Utilisez le filtre "Brouillons uniquement" pour rapidement publier tous vos chants importés.',
                style: TextStyle(fontStyle: FontStyle.italic)),
            ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris')),
        ]));
  }
}
