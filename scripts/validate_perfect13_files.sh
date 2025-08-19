#!/bin/bash

# Script de validation des fichiers Perfect 13 avant migration
# Usage: ./scripts/validate_perfect13_files.sh

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PERFECT13_PATH="/Users/chadracntsouassouani/Downloads/perfect 13"
PERFECT17_PATH="/Users/chadracntsouassouani/Downloads/perfect 17"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  🔍 ANALYSE DE PERFECT 13 AVANT MIGRATION${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Vérifier si Perfect 13 existe
if [ ! -d "$PERFECT13_PATH" ]; then
    print_error "Le dossier Perfect 13 n'existe pas: $PERFECT13_PATH"
    exit 1
fi

print_header

# 1. Analyse Flutter des erreurs de syntaxe
print_info "🔍 Analyse des erreurs de syntaxe dans Perfect 13..."
cd "$PERFECT13_PATH"

echo ""
echo "📊 Résumé des fichiers Dart:"
find lib -name "*.dart" | wc -l | xargs echo "Nombre total de fichiers .dart:"

echo ""
print_info "🚨 Test de compilation Flutter..."

# Sauvegarder la sortie d'analyse
flutter analyze > /tmp/perfect13_analysis.log 2>&1
ANALYZE_EXIT_CODE=$?

if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
    print_success "Aucune erreur de syntaxe détectée dans Perfect 13 !"
else
    print_error "ERREURS DÉTECTÉES dans Perfect 13:"
    echo ""
    # Afficher seulement les erreurs critiques
    grep -E "(error|Error|ERROR)" /tmp/perfect13_analysis.log | head -20
    echo ""
    print_warning "Fichier complet d'analyse sauvé: /tmp/perfect13_analysis.log"
fi

echo ""
print_info "🔧 Vérification des dépendances (pubspec.yaml)..."

# Vérifier si pubspec.yaml est valide
if flutter pub get > /tmp/perfect13_pubget.log 2>&1; then
    print_success "pubspec.yaml est valide"
else
    print_error "Problème avec pubspec.yaml:"
    tail -10 /tmp/perfect13_pubget.log
fi

echo ""
print_info "📋 Fichiers spécifiques à analyser individuellement:"

# Liste des fichiers critiques à vérifier
CRITICAL_FILES=(
    "lib/main.dart"
    "lib/theme.dart"
    "lib/data_schema.dart"
    "lib/colors.dart"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Vérification syntaxe basique
        if dart analyze "$file" > /tmp/file_check.log 2>&1; then
            print_success "$file - OK"
        else
            print_error "$file - ERREURS DÉTECTÉES"
            grep -E "(error|Error)" /tmp/file_check.log | head -3
        fi
    else
        print_warning "$file - FICHIER MANQUANT"
    fi
done

echo ""
print_info "💾 Création d'une sauvegarde de Perfect 17 avant migration..."
cd "/Users/chadracntsouassouani/Downloads"
tar -czf "perfect17_backup_$(date +%Y%m%d_%H%M%S).tar.gz" "perfect 17/"
print_success "Sauvegarde créée: perfect17_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

echo ""
if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
    print_success "🎉 Perfect 13 semble sain - Migration recommandée"
    echo -e "${GREEN}Vous pouvez procéder à la migration des fichiers.${NC}"
else
    print_error "🚨 Perfect 13 contient des erreurs - Migration à risque"
    echo -e "${RED}Recommandation: Corrigez d'abord les erreurs ou migrez sélectivement.${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
