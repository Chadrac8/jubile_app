import 'package:flutter/material.dart';

/// Service de navigation global
/// Permet la navigation depuis n'importe où dans l'application
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Obtenir le contexte de navigation
  static BuildContext? get context => navigatorKey.currentContext;

  /// Naviguer vers une route
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Naviguer et remplacer la route actuelle
  static Future<T?> navigateToReplacement<T extends Object?>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T, T>(routeName, arguments: arguments);
  }

  /// Naviguer et supprimer toutes les routes précédentes
  static Future<T?> navigateToAndClearStack<T extends Object?>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Revenir en arrière
  static void goBack<T>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }

  /// Vérifier si on peut revenir en arrière
  static bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }

  /// Revenir à une route spécifique
  static void popUntil(String routeName) {
    return navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Naviguer vers une page avec un widget
  static Future<T?> navigateToPage<T>(Widget page) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Afficher un dialog
  static Future<T?> showCustomDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }

  /// Afficher un bottom sheet
  static Future<T?> showCustomBottomSheet<T>({
    required Widget content,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context!,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => content,
    );
  }

  /// Afficher un snackbar
  static void showSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    if (context != null) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Afficher un snackbar de succès
  static void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Afficher un snackbar d'erreur
  static void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Afficher un snackbar d'information
  static void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  /// Afficher un snackbar d'avertissement
  static void showWarningSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// Fermer tous les dialogs et bottom sheets ouverts
  static void closeOverlays() {
    if (context != null) {
      Navigator.of(context!, rootNavigator: true).popUntil((route) => route is! PopupRoute);
    }
  }
}

/// Extension pour simplifier l'utilisation du NavigationService
extension NavigationExtension on BuildContext {
  /// Naviguer vers une route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Naviguer et remplacer
  Future<T?> pushReplacementNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushReplacementNamed<T, T>(routeName, arguments: arguments);
  }

  /// Revenir en arrière
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Afficher un snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}