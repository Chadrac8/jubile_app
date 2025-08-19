import 'package:flutter/material.dart';
import '../config/app_modules.dart';

/// Interface pour les modules
abstract class AppModule {
  /// Configuration du module
  ModuleConfig get config;
  
  /// Routes du module
  Map<String, WidgetBuilder> get routes;
  
  /// Widgets du menu pour l'interface membre
  List<Widget> getMemberMenuItems(BuildContext context);
  
  /// Widgets du menu pour l'interface admin
  List<Widget> getAdminMenuItems(BuildContext context);
  
  /// Initialisation du module
  Future<void> initialize();
  
  /// Nettoyage du module
  Future<void> dispose();
}

/// Gestionnaire central des modules
class ModuleManager {
  static final ModuleManager _instance = ModuleManager._internal();
  factory ModuleManager() => _instance;
  ModuleManager._internal();

  final Map<String, AppModule> _modules = {};
  final Map<String, WidgetBuilder> _routes = {};

  /// Enregistrer un module
  void registerModule(AppModule module) {
    if (!module.config.isEnabled) {
      return;
    }

    _modules[module.config.id] = module;
    
    // Ajouter les routes du module
    _routes.addAll(module.routes);
    
    print('Module ${module.config.name} enregistré');
  }

  /// Initialiser tous les modules
  Future<void> initializeModules() async {
    for (final module in _modules.values) {
      try {
        await module.initialize();
        print('Module ${module.config.name} initialisé');
      } catch (e) {
        print('Erreur lors de l\'initialisation du module ${module.config.name}: $e');
      }
    }
  }

  /// Obtenir un module par son ID
  AppModule? getModule(String moduleId) {
    return _modules[moduleId];
  }

  /// Obtenir tous les modules actifs
  List<AppModule> getActiveModules() {
    return _modules.values.toList();
  }

  /// Obtenir toutes les routes
  Map<String, WidgetBuilder> getRoutes() {
    return Map.unmodifiable(_routes);
  }

  /// Obtenir les éléments de menu pour l'interface membre
  List<Widget> getMemberMenuItems(BuildContext context) {
    final items = <Widget>[];
    
    for (final module in _modules.values) {
      if (module.config.hasPermission(ModulePermission.member)) {
        items.addAll(module.getMemberMenuItems(context));
      }
    }
    
    return items;
  }

  /// Obtenir les éléments de menu pour l'interface admin
  List<Widget> getAdminMenuItems(BuildContext context) {
    final items = <Widget>[];
    
    for (final module in _modules.values) {
      if (module.config.hasPermission(ModulePermission.admin)) {
        items.addAll(module.getAdminMenuItems(context));
      }
    }
    
    return items;
  }

  /// Vérifier si un module est chargé
  bool isModuleLoaded(String moduleId) {
    return _modules.containsKey(moduleId);
  }

  /// Décharger un module
  Future<void> unloadModule(String moduleId) async {
    final module = _modules[moduleId];
    if (module != null) {
      try {
        await module.dispose();
        _modules.remove(moduleId);
        
        // Retirer les routes du module
        final routesToRemove = module.routes.keys.toList();
        for (final route in routesToRemove) {
          _routes.remove(route);
        }
        
        print('Module ${module.config.name} déchargé');
      } catch (e) {
        print('Erreur lors du déchargement du module ${module.config.name}: $e');
      }
    }
  }

  /// Recharger un module
  Future<void> reloadModule(AppModule module) async {
    await unloadModule(module.config.id);
    registerModule(module);
    await module.initialize();
  }

  /// Nettoyer tous les modules
  Future<void> disposeAll() async {
    for (final module in _modules.values) {
      try {
        await module.dispose();
      } catch (e) {
        print('Erreur lors du nettoyage du module ${module.config.name}: $e');
      }
    }
    _modules.clear();
    _routes.clear();
  }

  /// Obtenir les statistiques des modules
  Map<String, dynamic> getModuleStats() {
    return {
      'totalModules': _modules.length,
      'enabledModules': _modules.values.where((m) => m.config.isEnabled).length,
      'memberModules': _modules.values.where((m) => m.config.hasPermission(ModulePermission.member)).length,
      'adminModules': _modules.values.where((m) => m.config.hasPermission(ModulePermission.admin)).length,
      'publicModules': _modules.values.where((m) => m.config.hasPermission(ModulePermission.public)).length,
      'totalRoutes': _routes.length,
    };
  }
}

/// Classe de base pour simplifier la création de modules
abstract class BaseModule implements AppModule {
  @override
  final ModuleConfig config;

  BaseModule(this.config);

  @override
  Future<void> initialize() async {
    // Implémentation par défaut - peut être surchargée
  }

  @override
  Future<void> dispose() async {
    // Implémentation par défaut - peut être surchargée
  }

  @override
  List<Widget> getMemberMenuItems(BuildContext context) {
    // Implémentation par défaut - peut être surchargée
    return [];
  }

  @override
  List<Widget> getAdminMenuItems(BuildContext context) {
    // Implémentation par défaut - peut être surchargée
    return [];
  }
}