import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Configuration centralisée de la localisation française
class LocaleConfig {
  /// Locale française par défaut
  static const Locale defaultLocale = Locale('fr', 'FR');

  /// Liste des locales supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'),
  ];

  /// Délégués de localisation
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Configuration de date picker française
  static Map<String, String> get datePickerLabels => {
    'selectDateButtonText': 'Sélectionner une date',
    'cancelButtonText': 'Annuler',
    'confirmButtonText': 'OK',
    'dayOfMonthColumnLabel': 'Jour',
    'monthOfYearColumnLabel': 'Mois',
    'yearColumnLabel': 'Année',
    'dateRangeStartLabel': 'Date de début',
    'dateRangeEndLabel': 'Date de fin',
    'dateRangePickerHelpText': 'Sélectionnez une plage de dates',
    'saveButtonText': 'Enregistrer',
    'datePickerHelpText': 'Sélectionnez une date',
    'dateOutOfRangeLabel': 'Hors limite',
    'invalidDateFormatLabel': 'Format de date invalide',
    'invalidDateRangeLabel': 'Plage de dates invalide',
    'dateInputLabel': 'Entrez une date',
  };

  /// Noms des jours de la semaine en français
  static const List<String> weekDays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  /// Noms des jours de la semaine en français (abrégés)
  static const List<String> weekDaysShort = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  /// Noms des mois en français
  static const List<String> months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// Noms des mois en français (abrégés)
  static const List<String> monthsShort = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Jun',
    'Jul',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  /// Configuration pour les widgets de calendrier français
  static MaterialLocalizations get frenchMaterialLocalizations {
    return const DefaultMaterialLocalizations();
  }

  /// Configuration de Material Theme en français
  static ThemeData configureThemeForFrench(ThemeData theme) {
    return theme.copyWith(
      // Configuration spécifique à la locale française si nécessaire
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  /// Validation si une locale est supportée
  static bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode &&
        supportedLocale.countryCode == locale.countryCode);
  }

  /// Résolution de locale - retourne la locale française par défaut
  static Locale? localeResolutionCallback(
      List<Locale>? locales, Iterable<Locale> supportedLocales) {
    if (locales != null) {
      for (Locale locale in locales) {
        if (isLocaleSupported(locale)) {
          return locale;
        }
      }
    }
    return defaultLocale;
  }
}