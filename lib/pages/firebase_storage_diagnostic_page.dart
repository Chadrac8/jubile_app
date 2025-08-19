import 'package:flutter/material.dart';
import '../services/firebase_storage_test.dart';
import '../../compatibility/app_theme_bridge.dart';

class FirebaseStorageDiagnosticPage extends StatefulWidget {
  const FirebaseStorageDiagnosticPage({super.key});

  @override
  State<FirebaseStorageDiagnosticPage> createState() => _FirebaseStorageDiagnosticPageState();
}

class _FirebaseStorageDiagnosticPageState extends State<FirebaseStorageDiagnosticPage> {
  bool _isRunning = false;
  Map<String, dynamic>? _connectionResult;
  Map<String, dynamic>? _uploadResult;

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _connectionResult = null;
      _uploadResult = null;
    });

    try {
      // Test de connexion
      final connectionTest = await FirebaseStorageTest.testStorageConnection();
      setState(() => _connectionResult = connectionTest);

      // Test d'upload
      final uploadTest = await FirebaseStorageTest.testImageUpload();
      setState(() => _uploadResult = uploadTest);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du diagnostic: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Firebase Storage'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Diagnostic Firebase Storage',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ce diagnostic teste la connectivité et les permissions Firebase Storage pour identifier les problèmes d\'upload d\'images.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton de test
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostic,
                icon: _isRunning 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Test en cours...' : 'Lancer le diagnostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Résultats de connexion
            if (_connectionResult != null) ...[
              _buildResultCard(
                'Test de Connexion',
                Icons.wifi,
                _connectionResult!,
                _getConnectionStatus(_connectionResult!),
              ),
              const SizedBox(height: 16),
            ],

            // Résultats d'upload
            if (_uploadResult != null) ...[
              _buildResultCard(
                'Test d\'Upload',
                Icons.cloud_upload,
                _uploadResult!,
                _getUploadStatus(_uploadResult!),
              ),
              const SizedBox(height: 16),
            ],

            // Guide de résolution
            if (_connectionResult != null || _uploadResult != null) ...[
              _buildTroubleshootingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, IconData icon, Map<String, dynamic> result, String status) {
    final isSuccess = !result.containsKey('errors') || (result['errors'] as List).isEmpty;
    final statusColor = isSuccess ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.entries.map((entry) => _buildResultLine(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultLine(String key, dynamic value) {
    IconData icon;
    Color color;

    if (value is bool) {
      icon = value ? Icons.check_circle : Icons.cancel;
      color = value ? Colors.green : Colors.red;
    } else if (key == 'errors' && value is List && value.isNotEmpty) {
      icon = Icons.error;
      color = Colors.red;
    } else {
      icon = Icons.info;
      color = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$key: ${_formatValue(value)}',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.isEmpty ? '[]' : value.join(', ');
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }

  String _getConnectionStatus(Map<String, dynamic> result) {
    if (result['canUpload'] == true) return 'EXCELLENT';
    if (result['canAccessStorage'] == true) return 'PARTIEL';
    if (result['isAuthenticated'] == true) return 'LIMITÉ';
    return 'ÉCHEC';
  }

  String _getUploadStatus(Map<String, dynamic> result) {
    return result['success'] == true ? 'RÉUSSI' : 'ÉCHEC';
  }

  Widget _buildTroubleshootingCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Guide de résolution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Vérifiez que Firebase Storage est activé dans la console Firebase',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '2. Configurez les règles de sécurité (voir FIREBASE_STORAGE_SETUP.md)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '3. Vérifiez que l\'utilisateur est connecté',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '4. Redémarrez l\'application après les changements',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}