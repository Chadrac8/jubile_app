#!/bin/bash

# Script de migration ciblée : Accueil Membre + Bible + Message
# Migration sécurisée des 3 modules prioritaires de Perfect 13 → Perfect 17

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

PERFECT13_PATH="/Users/chadracntsouassouani/Downloads/perfect 13"
PERFECT17_PATH="/Users/chadracntsouassouani/Downloads/perfect 17"

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  🎯 MIGRATION CIBLÉE : ACCUEIL + BIBLE + MESSAGE${NC}"
    echo -e "${BLUE}============================================================${NC}"
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

print_priority() {
    echo -e "${PURPLE}🎯 $1${NC}"
}

# Fonction pour tester la sécurité d'un module
test_module_safety() {
    local module_path="$1"
    local module_name="$2"
    
    print_info "Test de sécurité du module: $module_name"
    
    if [ ! -d "$module_path" ]; then
        print_warning "Module $module_name introuvable: $module_path"
        return 1
    fi
    
    local total_files=0
    local safe_files=0
    local error_files=0
    
    # Tester chaque fichier .dart du module
    while IFS= read -r -d '' dart_file; do
        ((total_files++))
        if dart analyze "$dart_file" > /dev/null 2>&1; then
            ((safe_files++))
        else
            ((error_files++))
            echo "    ❌ $(basename "$dart_file")"
        fi
    done < <(find "$module_path" -name "*.dart" -print0)
    
    if [ $total_files -eq 0 ]; then
        print_warning "Module $module_name vide"
        return 1
    fi
    
    local safety_percentage=$((safe_files * 100 / total_files))
    
    echo "    📊 $safe_files/$total_files fichiers sains ($safety_percentage%)"
    
    if [ $safety_percentage -ge 80 ]; then
        print_success "Module $module_name SAIN (≥80% de fichiers valides)"
        return 0
    elif [ $safety_percentage -ge 50 ]; then
        print_warning "Module $module_name PARTIELLEMENT SAIN (50-79% valides)"
        return 2
    else
        print_error "Module $module_name DANGEREUX (<50% de fichiers valides)"
        return 3
    fi
}

# Fonction pour copier sélectivement les fichiers sains
copy_safe_files() {
    local source_dir="$1"
    local dest_dir="$2"
    local module_name="$3"
    
    print_info "Migration sélective: $module_name"
    
    local copied_count=0
    local skipped_count=0
    
    # Créer le répertoire de destination
    mkdir -p "$dest_dir"
    
    # Copier seulement les fichiers sains
    while IFS= read -r -d '' dart_file; do
        if dart analyze "$dart_file" > /dev/null 2>&1; then
            local rel_path=$(realpath --relative-to="$source_dir" "$dart_file")
            local dest_file="$dest_dir/$rel_path"
            local dest_file_dir=$(dirname "$dest_file")
            
            mkdir -p "$dest_file_dir"
            cp "$dart_file" "$dest_file"
            ((copied_count++))
            echo "    ✓ $(basename "$dart_file")"
        else
            ((skipped_count++))
            echo "    ✗ $(basename "$dart_file") (erreurs détectées)"
        fi
    done < <(find "$source_dir" -name "*.dart" -print0)
    
    print_info "Résultat: $copied_count copiés, $skipped_count ignorés"
}

print_header

# Vérifier que Perfect 13 existe
if [ ! -d "$PERFECT13_PATH" ]; then
    print_error "Perfect 13 non trouvé: $PERFECT13_PATH"
    exit 1
fi

cd "$PERFECT17_PATH"

echo ""
print_priority "🏠 MODULE 1: ACCUEIL MEMBRE"

# Rechercher les fichiers d'accueil membre
ACCUEIL_FILES=(
    "$PERFECT13_PATH/lib/models/home_config_model.dart"
    "$PERFECT13_PATH/lib/models/home_widget_model.dart"
    "$PERFECT13_PATH/lib/models/home_cover_config_model.dart"
    "$PERFECT13_PATH/lib/models/home_cover_carousel_config_model.dart"
    "$PERFECT13_PATH/lib/admin/home_config_admin_page.dart"
    "$PERFECT13_PATH/lib/admin/home_config_menu_page.dart"
    "$PERFECT13_PATH/lib/admin/home_cover_admin_page.dart"
)

safe_accueil=0
total_accueil=0

for file in "${ACCUEIL_FILES[@]}"; do
    if [ -f "$file" ]; then
        ((total_accueil++))
        if dart analyze "$file" > /dev/null 2>&1; then
            ((safe_accueil++))
            # Copier le fichier
            rel_path=$(realpath --relative-to="$PERFECT13_PATH" "$file")
            dest_file="$PERFECT17_PATH/$rel_path"
            dest_dir=$(dirname "$dest_file")
            mkdir -p "$dest_dir"
            cp "$file" "$dest_file"
            print_success "✓ $(basename "$file")"
        else
            print_error "✗ $(basename "$file") (erreurs détectées)"
        fi
    else
        print_warning "Fichier manquant: $(basename "$file")"
    fi
done

if [ $safe_accueil -gt 0 ]; then
    print_success "Module Accueil: $safe_accueil/$total_accueil fichiers migrés"
else
    print_warning "Aucun fichier d'accueil migré"
fi

echo ""
print_priority "📖 MODULE 2: LA BIBLE"

# Tester le module Bible
bible_status=0
if test_module_safety "$PERFECT13_PATH/lib/modules/bible" "Bible"; then
    bible_status=1
    print_info "Migration complète du module Bible..."
    cp -r "$PERFECT13_PATH/lib/modules/bible" "$PERFECT17_PATH/lib/modules/"
    print_success "Module Bible migré complètement"
elif [ $? -eq 2 ]; then
    bible_status=2
    print_info "Migration sélective du module Bible..."
    copy_safe_files "$PERFECT13_PATH/lib/modules/bible" "$PERFECT17_PATH/lib/modules/bible" "Bible"
    print_warning "Module Bible migré partiellement"
else
    bible_status=3
    print_error "Module Bible trop corrompu - migration annulée"
fi

echo ""
print_priority "💬 MODULE 3: LE MESSAGE"

# Rechercher le module Message
MESSAGE_DIRS=(
    "$PERFECT13_PATH/lib/modules/message"
    "$PERFECT13_PATH/lib/modules/messages"
    "$PERFECT13_PATH/lib/modules/branham"
    "$PERFECT13_PATH/lib/modules/sermons"
)

message_found=false
for message_dir in "${MESSAGE_DIRS[@]}"; do
    if [ -d "$message_dir" ]; then
        message_found=true
        module_name=$(basename "$message_dir")
        print_info "Module Message trouvé: $module_name"
        
        if test_module_safety "$message_dir" "Message ($module_name)"; then
            cp -r "$message_dir" "$PERFECT17_PATH/lib/modules/"
            print_success "Module Message ($module_name) migré complètement"
        elif [ $? -eq 2 ]; then
            copy_safe_files "$message_dir" "$PERFECT17_PATH/lib/modules/$module_name" "Message ($module_name)"
            print_warning "Module Message ($module_name) migré partiellement"
        else
            print_error "Module Message ($module_name) trop corrompu"
        fi
        break
    fi
done

if [ "$message_found" = false ]; then
    print_warning "Module Message non trouvé dans Perfect 13"
    print_info "Recherche des fichiers liés aux messages..."
    
    # Rechercher les fichiers de message individuels
    while IFS= read -r -d '' message_file; do
        if dart analyze "$message_file" > /dev/null 2>&1; then
            rel_path=$(realpath --relative-to="$PERFECT13_PATH" "$message_file")
            dest_file="$PERFECT17_PATH/$rel_path"
            dest_dir=$(dirname "$dest_file")
            mkdir -p "$dest_dir"
            cp "$message_file" "$dest_file"
            print_success "✓ $(basename "$message_file")"
        fi
    done < <(find "$PERFECT13_PATH/lib" -name "*message*" -o -name "*sermon*" -o -name "*branham*" -print0 2>/dev/null)
fi

echo ""
print_info "🔧 MISE À JOUR DES DÉPENDANCES"

# Vérifier si de nouveaux packages sont nécessaires
if [ -f "$PERFECT13_PATH/pubspec.yaml" ]; then
    print_info "Vérification des nouvelles dépendances..."
    # Extraire les dépendances de Perfect 13 qui ne sont pas dans Perfect 17
    grep -A 100 "dependencies:" "$PERFECT13_PATH/pubspec.yaml" | grep -B 100 "dev_dependencies:" | head -n -1 > /tmp/perfect13_deps.txt
    grep -A 100 "dependencies:" "$PERFECT17_PATH/pubspec.yaml" | grep -B 100 "dev_dependencies:" | head -n -1 > /tmp/perfect17_deps.txt
    
    new_deps=$(comm -23 <(sort /tmp/perfect13_deps.txt) <(sort /tmp/perfect17_deps.txt) | grep -v "dependencies:" | grep -v "^$")
    
    if [ -n "$new_deps" ]; then
        print_warning "Nouvelles dépendances détectées dans Perfect 13:"
        echo "$new_deps"
        print_info "Vous devrez peut-être les ajouter manuellement à pubspec.yaml"
    else
        print_success "Aucune nouvelle dépendance requise"
    fi
fi

echo ""
print_info "🧪 TEST DE COMPILATION POST-MIGRATION"

if flutter analyze > /tmp/perfect17_post_priority_migration.log 2>&1; then
    print_success "🎉 Perfect 17 compile toujours sans erreur après migration !"
else
    print_warning "⚠️ Nouvelles erreurs détectées après migration"
    echo "Vérifiez le fichier: /tmp/perfect17_post_priority_migration.log"
    print_info "Rollback possible avec Git si nécessaire"
fi

echo ""
print_info "💾 SAUVEGARDE AUTOMATIQUE"
git add .
git commit -m "Migration prioritaire: Accueil Membre + Bible + Message de Perfect 13"

echo ""
print_priority "🏆 RÉSUMÉ DE LA MIGRATION"
echo "📊 Modules traités:"
echo "  🏠 Accueil Membre: $safe_accueil/$total_accueil fichiers migrés"
echo "  📖 Bible: $([ $bible_status -eq 1 ] && echo "Migration complète" || [ $bible_status -eq 2 ] && echo "Migration partielle" || echo "Échec")"
echo "  💬 Message: $([ "$message_found" = true ] && echo "Trouvé et traité" || echo "Recherche individuelle effectuée")"

echo ""
print_success "🎯 Migration prioritaire terminée !"
print_info "Vérifiez le fonctionnement des nouveaux modules dans l'application."

echo ""
echo -e "${BLUE}============================================================${NC}"
