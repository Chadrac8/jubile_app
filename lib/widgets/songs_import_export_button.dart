import 'package:flutter/material.dart';
import '../pages/songs_import_export_page.dart';

/// Widget bouton pour accéder à l'import/export des chants
class SongsImportExportButton extends StatelessWidget {
  final bool isCompact;
  
  const SongsImportExportButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        icon: Icon(
          Icons.import_export,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () => _navigateToImportExport(context),
        tooltip: 'Import/Export des chants',
      );
    }
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToImportExport(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.import_export,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Import/Export',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Gérer vos chants',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToImportExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SongsImportExportPage(),
      ),
    );
  }
}