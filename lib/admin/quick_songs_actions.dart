import 'package:flutter/material.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget pour des actions rapides sur les chants
class QuickSongsActions extends StatelessWidget {
  const QuickSongsActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700)),
            ]),
          const SizedBox(height: 16),
          
          // Publier tous les brouillons
          _QuickActionButton(
            icon: Icons.publish,
            title: 'Publier tous les brouillons',
            subtitle: 'Rendre tous les chants en "draft" visibles aux membres',
            color: Theme.of(context).colorScheme.successColor,
            onPressed: () => _publishAllDrafts(context)),
          
          const SizedBox(height: 12),
          
          // Mettre en brouillon tous les chants publiés
          _QuickActionButton(
            icon: Icons.edit_note,
            title: 'Mettre en brouillon tous les publiés',
            subtitle: 'Masquer temporairement tous les chants publiés',
            color: Theme.of(context).colorScheme.warningColor,
            onPressed: () => _draftAllPublished(context)),
          
          const SizedBox(height: 12),
          
          // Archiver les anciens chants
          _QuickActionButton(
            icon: Icons.archive,
            title: 'Archiver les chants anciens',
            subtitle: 'Archiver les chants non utilisés depuis 6 mois',
            color: Theme.of(context).colorScheme.textTertiaryColor,
            onPressed: () => _archiveOldSongs(context)),
        ]));
  }

  static Future<void> _publishAllDrafts(BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Publier tous les brouillons',
      'Cette action va changer le statut de TOUS les chants en "draft" vers "published".\n\n'
      'Êtes-vous sûr de vouloir continuer ?');
    
    if (!confirmed) return;

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Publication en cours...'),
            ])));

      // Récupérer tous les brouillons
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('status', isEqualTo: 'draft')
          .get();

      // Mettre à jour par batch
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'published',
          'updatedAt': FieldValue.serverTimestamp(),
          'modifiedBy': 'quick_action_publish_all',
        });
      }
      
      await batch.commit();

      // Fermer le dialog de chargement
      Navigator.of(context).pop();

      // Afficher le succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${snapshot.docs.length} chants ont été publiés'),
          backgroundColor: Theme.of(context).colorScheme.successColor));

    } catch (e) {
      // Fermer le dialog de chargement
      Navigator.of(context).pop();
      
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la publication: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor));
    }
  }

  static Future<void> _draftAllPublished(BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Mettre en brouillon tous les publiés',
      'Cette action va changer le statut de TOUS les chants "published" vers "draft".\n\n'
      'Les chants ne seront plus visibles par les membres.\n\n'
      'Êtes-vous sûr de vouloir continuer ?');
    
    if (!confirmed) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mise en brouillon en cours...'),
            ])));

      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('status', isEqualTo: 'published')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'draft',
          'updatedAt': FieldValue.serverTimestamp(),
          'modifiedBy': 'quick_action_draft_all',
        });
      }
      
      await batch.commit();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${snapshot.docs.length} chants ont été mis en brouillon'),
          backgroundColor: Theme.of(context).colorScheme.warningColor));

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise en brouillon: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor));
    }
  }

  static Future<void> _archiveOldSongs(BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Archiver les chants anciens',
      'Cette action va archiver tous les chants qui n\'ont pas été utilisés depuis 6 mois.\n\n'
      'Les chants archivés restent dans la base mais sont masqués de la liste principale.\n\n'
      'Êtes-vous sûr de vouloir continuer ?');
    
    if (!confirmed) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Archivage en cours...'),
            ])));

      // Date limite : 6 mois avant maintenant
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('lastUsedAt', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .where('status', whereIn: ['published', 'draft'])
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'archived',
          'updatedAt': FieldValue.serverTimestamp(),
          'modifiedBy': 'quick_action_archive_old',
        });
      }
      
      await batch.commit();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${snapshot.docs.length} chants anciens ont été archivés'),
          backgroundColor: Theme.of(context).colorScheme.textTertiaryColor));

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'archivage: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor));
    }
  }

  static Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorColor,
              foregroundColor: Theme.of(context).colorScheme.surfaceColor),
            child: const Text('Confirmer')),
        ])) ?? false;
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.1)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: Theme.of(context).colorScheme.surfaceColor)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.9))),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.textTertiaryColor)),
                ])),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ])));
  }
}
