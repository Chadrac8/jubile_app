import 'package:flutter/material.dart';

/// Widget simple pour basculer entre les modes de lecture média
class MediaPlayerModeToggle extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;
  final String componentType; // 'video' ou 'audio'

  const MediaPlayerModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.componentType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  componentType == 'video' ? Icons.video_settings : Icons.audiotrack,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode de lecture',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mode intégré
            Container(
              decoration: BoxDecoration(
                color: currentMode == 'integrated' ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentMode == 'integrated' ? Colors.green : Colors.grey[300]!,
                  width: currentMode == 'integrated' ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: const Text(
                  'Lecteur intégré',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  componentType == 'video' 
                    ? 'Lit la vidéo directement dans l\'application'
                    : 'Lit l\'audio directement dans l\'application',
                ),
                value: 'integrated',
                groupValue: currentMode,
                onChanged: (value) => onModeChanged(value!),
                activeColor: Colors.green,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Mode externe
            Container(
              decoration: BoxDecoration(
                color: currentMode == 'external' ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentMode == 'external' ? Colors.blue : Colors.grey[300]!,
                  width: currentMode == 'external' ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: const Text(
                  'Ouverture externe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  componentType == 'video' 
                    ? 'Ouvre YouTube dans l\'application native'
                    : 'Ouvre l\'audio dans l\'application appropriée',
                ),
                value: 'external',
                groupValue: currentMode,
                onChanged: (value) => onModeChanged(value!),
                activeColor: Colors.blue,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations sur le mode sélectionné
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDescription(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeDescription() {
    if (currentMode == 'integrated') {
      return componentType == 'video'
        ? 'Le lecteur YouTube sera intégré directement dans votre page avec tous les contrôles natifs.'
        : 'Le lecteur audio sera intégré avec des contrôles de lecture avancés.';
    } else {
      return componentType == 'video'
        ? 'Un aperçu sera affiché avec un bouton pour ouvrir la vidéo sur YouTube.'
        : 'Un aperçu sera affiché avec un bouton pour ouvrir l\'audio dans l\'application appropriée.';
    }
  }
}