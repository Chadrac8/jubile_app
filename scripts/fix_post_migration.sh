#!/bin/bash

# Script de correction post-migration
# Corrige les erreurs de références et imports après migration

PERFECT17_PATH="/Users/chadracntsouassouani/Downloads/perfect 17"

echo "🔧 Correction des erreurs post-migration..."

cd "$PERFECT17_PATH"

# Créer les imports manquants si nécessaire
echo "📝 Ajout des imports AppTheme manquants..."

# Corriger les références AppTheme vers Theme
find lib -name "*.dart" -exec sed -i '' 's/AppTheme\./Theme.of(context).colorScheme./g' {} \;

# Mettre à jour les imports pour utiliser le bon thème
find lib -name "*.dart" -exec sed -i '' "s|import '../theme.dart';|import '../../theme.dart';|g" {} \;

# Corriger les chemins d'imports relatifs pour les nouveaux modules
echo "🔗 Correction des chemins d'imports..."

# Bible module
find lib/modules/bible -name "*.dart" -exec sed -i '' "s|import '../models/|import '../../models/|g" {} \;
find lib/modules/bible -name "*.dart" -exec sed -i '' "s|import '../services/|import '../../services/|g" {} \;

# Message module  
find lib/modules/message -name "*.dart" -exec sed -i '' "s|import '../models/|import '../../models/|g" {} \;
find lib/modules/message -name "*.dart" -exec sed -i '' "s|import '../services/|import '../../services/|g" {} \;

# Pages admin
find lib/pages/admin -name "*.dart" -exec sed -i '' "s|import '../models/|import '../../models/|g" {} \;
find lib/pages/admin -name "*.dart" -exec sed -i '' "s|import '../services/|import '../../services/|g" {} \;

echo "✅ Corrections appliquées !"

# Test de compilation
echo "🧪 Test de compilation après corrections..."
if flutter analyze > /tmp/perfect17_after_fixes.log 2>&1; then
    echo "✅ Compilation réussie !"
else
    echo "⚠️ Erreurs restantes - voir /tmp/perfect17_after_fixes.log"
    head -20 /tmp/perfect17_after_fixes.log
fi
