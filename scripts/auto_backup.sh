#!/bin/bash

# Script de sauvegarde automatique pour le projet ChurchFlow
# Usage: ./scripts/auto_backup.sh [message_commit_optionnel]

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Ce script doit être exécuté dans un dépôt Git"
    exit 1
fi

# Message de commit par défaut ou personnalisé
COMMIT_MESSAGE=${1:-"Auto backup - $(date '+%Y-%m-%d %H:%M:%S')"}

print_info "🔄 Début de la sauvegarde automatique..."

# Vérifier s'il y a des changements
if git diff --quiet && git diff --cached --quiet; then
    print_warning "Aucun changement détecté. Sauvegarde annulée."
    exit 0
fi

# Afficher le statut des fichiers
print_info "📊 Statut des fichiers :"
git status --short

# Ajouter tous les fichiers modifiés
print_info "➕ Ajout des fichiers modifiés..."
git add .

# Créer le commit
print_info "💾 Création du commit..."
if git commit -m "$COMMIT_MESSAGE"; then
    print_info "✅ Commit créé avec succès"
else
    print_error "❌ Échec de la création du commit"
    exit 1
fi

# Pousser vers le dépôt distant
print_info "🚀 Push vers GitHub..."
if git push origin main; then
    print_info "✅ Sauvegarde terminée avec succès !"
    print_info "🔗 Votre code est maintenant sauvegardé sur : https://github.com/Chadrac8/jubile_app"
else
    print_error "❌ Échec du push vers GitHub"
    print_warning "Le commit local a été créé mais pas synchronisé avec GitHub"
    exit 1
fi

print_info "📈 Historique des derniers commits :"
git log --oneline -5
