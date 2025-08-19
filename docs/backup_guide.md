# 🔄 Guide des Sauvegardes Automatiques - ChurchFlow

## 🚀 Méthodes de sauvegarde disponibles

### 1. Script de sauvegarde manuelle
```bash
# Sauvegarde rapide avec message automatique
./scripts/auto_backup.sh

# Sauvegarde avec message personnalisé
./scripts/auto_backup.sh "Ajout de la fonctionnalité X"
```

### 2. Tâches VS Code
- **Ctrl+Shift+P** → "Tasks: Run Task"
- Choisir "Sauvegarde rapide" ou "Sauvegarde avec message personnalisé"

### 3. Sauvegarde automatique programmée (Cron)

#### Installation du cron job :
```bash
# Ouvrir l'éditeur cron
crontab -e

# Ajouter une des lignes suivantes :
# Sauvegarde quotidienne à 18h00
0 18 * * * cd "/Users/chadracntsouassouani/Downloads/perfect 17" && ./scripts/auto_backup.sh "Sauvegarde automatique quotidienne" >> /tmp/churchflow_backup.log 2>&1

# Sauvegarde toutes les 4 heures
0 9,13,17,21 * * * cd "/Users/chadracntsouassouani/Downloads/perfect 17" && ./scripts/auto_backup.sh "Sauvegarde auto - $(date '+%H:%M')" >> /tmp/churchflow_backup.log 2>&1
```

#### Vérifier les logs :
```bash
tail -f /tmp/churchflow_backup.log
```

### 4. GitHub Actions (Automatique)
- Se déclenche automatiquement sur chaque push
- Sauvegarde programmée quotidienne à 02:00 UTC
- Crée des artifacts de build
- Teste le code automatiquement

## 📊 Surveillance des sauvegardes

### Vérifier le statut :
```bash
# Voir les derniers commits
git log --oneline -10

# Vérifier si tout est synchronisé
git status

# Voir les branches de sauvegarde
git branch -a | grep backup
```

### Logs des sauvegardes automatiques :
```bash
# Logs du cron
tail -20 /tmp/churchflow_backup.log

# Logs système (macOS)
log show --predicate 'process == "cron"' --last 1h
```

## 🛠️ Configuration avancée

### Variables d'environnement
Créer un fichier `.env` pour personnaliser :
```bash
# Fréquence des sauvegardes (en heures)
BACKUP_FREQUENCY=4

# Message de commit par défaut
DEFAULT_COMMIT_MESSAGE="Auto backup"

# Notification webhook (optionnel)
WEBHOOK_URL="https://hooks.slack.com/services/..."
```

### Sauvegarde conditionnelle
Le script ne fait une sauvegarde que s'il y a des changements détectés.

### Gestion des erreurs
- Le script s'arrête en cas d'erreur
- Les logs sont sauvegardés pour diagnostic
- Notifications en cas d'échec (à configurer)

## 📱 Raccourcis clavier VS Code

Ajouter dans `keybindings.json` :
```json
[
  {
    "key": "ctrl+alt+s",
    "command": "workbench.action.tasks.runTask",
    "args": "Sauvegarde rapide"
  }
]
```

## ⚠️ Bonnes pratiques

1. **Testez avant de déployer** : Utilisez `flutter analyze` et `flutter test`
2. **Messages de commit descriptifs** : Décrivez ce qui a changé
3. **Surveillance régulière** : Vérifiez les logs de sauvegarde
4. **Backup local** : Gardez aussi des copies locales importantes
5. **Branches de fonctionnalités** : Créez des branches pour les gros changements

## 🔗 Liens utiles

- Dépôt GitHub : https://github.com/Chadrac8/jubile_app
- Actions GitHub : https://github.com/Chadrac8/jubile_app/actions
- Issues : https://github.com/Chadrac8/jubile_app/issues
