import 'package:flutter/material.dart';
import '../../compatibility/app_theme_bridge.dart';

/// Page d'information sur les statuts des chants
class SongStatusInfoPage extends StatelessWidget {
  const SongStatusInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos des statuts des chants')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Container(
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
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Système de statuts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700)),
                    ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Le système de statuts permet de contrôler la visibilité et la gestion des chants dans l\'application. '
                    'Chaque chant a un statut qui détermine qui peut le voir et dans quel contexte.',
                    style: TextStyle(fontSize: 16)),
                ])),
            
            const SizedBox(height: 24),
            
            // Statuts disponibles
            const Text(
              'Statuts disponibles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildStatusCard(
              'Draft (Brouillon)',
              'Statut par défaut pour les nouveaux chants',
              [
                'Visible uniquement par les administrateurs',
                'Permet de travailler sur le chant avant publication',
                'Idéal pour les chants en cours de création ou révision',
                'Ne s\'affiche pas dans la vue membre standard',
              ],
              Theme.of(context).colorScheme.warningColor,
              Icons.edit_note),
            
            const SizedBox(height: 16),
            
            _buildStatusCard(
              'Published (Publié)',
              'Chant validé et accessible à tous',
              [
                'Visible par tous les membres de l\'église',
                'Apparaît dans les recherches et listes',
                'Peut être utilisé lors des services',
                'Recommandé pour les chants finalisés',
              ],
              Theme.of(context).colorScheme.successColor,
              Icons.publish),
            
            const SizedBox(height: 16),
            
            _buildStatusCard(
              'Pending (En attente)',
              'Chant en attente d\'approbation',
              [
                'Soumis pour révision par un administrateur',
                'Pas encore visible par les membres',
                'Permet un processus de validation',
                'Utile pour les contributions externes',
              ],
              Colors.blue,
              Icons.pending),
            
            const SizedBox(height: 16),
            
            _buildStatusCard(
              'Archived (Archivé)',
              'Chant retiré de la circulation active',
              [
                'Masqué des listes principales',
                'Conservé pour l\'historique',
                'Peut être restauré si nécessaire',
                'Idéal pour les chants obsolètes ou saisonniers',
              ],
              Theme.of(context).colorScheme.textTertiaryColor,
              Icons.archive),
            
            const SizedBox(height: 24),
            
            // Bonnes pratiques
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.successColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.successColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.successColor),
                      const SizedBox(width: 8),
                      Text(
                        'Bonnes pratiques',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.successColor)),
                    ]),
                  const SizedBox(height: 12),
                  _buildPracticeItem('Utilisez "Draft" pour préparer de nouveaux chants'),
                  _buildPracticeItem('Passez en "Published" les chants validés et prêts'),
                  _buildPracticeItem('Archivez les chants qui ne sont plus utilisés'),
                  _buildPracticeItem('Utilisez la gestion en masse pour des changements globaux'),
                  _buildPracticeItem('Vérifiez régulièrement les statuts pour maintenir l\'ordre'),
                ])),
            
            const SizedBox(height: 24),
            
            // Actions recommandées
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Actions recommandées',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700)),
                    ]),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    'Si vous venez d\'importer des chants',
                    'Utilisez "Publier tous les brouillons" pour les rendre visibles',
                    Icons.publish),
                  _buildActionItem(
                    'Pour organiser votre bibliothèque',
                    'Utilisez la gestion en masse pour trier par statut',
                    Icons.manage_accounts),
                  _buildActionItem(
                    'Pour nettoyer votre collection',
                    'Archivez les chants anciens ou non utilisés',
                    Icons.cleaning_services),
                ])),
          ])));
  }

  Widget _buildStatusCard(
    String title,
    String subtitle,
    List<String> features,
    Color color,
    IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: Theme.of(context).colorScheme.surfaceColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.9))),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.textTertiaryColor)),
                  ])),
            ]),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 14))),
              ]))),
        ]));
  }

  Widget _buildPracticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.successColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14))),
        ]));
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.textTertiaryColor)),
              ])),
        ]));
  }
}
