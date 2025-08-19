import 'package:intl/intl.dart';

/// Service utilitaire pour le formatage des dates en français
class DateFormatter {
  /// Initialise la locale française pour les dates
  static void initializeFrenchLocale() {
    Intl.defaultLocale = 'fr_FR';
  }

  /// Formate une date courte (ex: 15/03/2024)
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  /// Formate une date longue (ex: vendredi 15 mars 2024)
  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une date médium (ex: 15 mars 2024)
  static String formatMediumDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une heure (ex: 14:30)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date et heure complète (ex: vendredi 15 mars 2024 à 14:30)
  static String formatDateTime(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date et heure courte (ex: 15/03/2024 14:30)
  static String formatShortDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date et heure médium (ex: 15 mars 2024 à 14:30)
  static String formatMediumDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date relative (ex: "Aujourd'hui", "Hier", "Il y a 2 jours")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else if (dateOnly == tomorrow) {
      return 'Demain';
    } else {
      final difference = today.difference(dateOnly).inDays;
      if (difference > 0 && difference <= 7) {
        return 'Il y a $difference jour${difference > 1 ? 's' : ''}';
      } else if (difference < 0 && difference >= -7) {
        return 'Dans ${-difference} jour${-difference > 1 ? 's' : ''}';
      } else {
        return formatMediumDate(date);
      }
    }
  }

  /// Formate une date relative avec l'heure (ex: "Aujourd'hui à 14:30")
  static String formatRelativeDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final timeStr = formatTime(date);
    
    if (dateOnly == today) {
      return 'Aujourd\'hui à $timeStr';
    } else if (dateOnly == yesterday) {
      return 'Hier à $timeStr';
    } else if (dateOnly == tomorrow) {
      return 'Demain à $timeStr';
    } else {
      return formatMediumDateTime(date);
    }
  }

  /// Formate le nom d'un jour de la semaine (ex: "Lundi")
  static String formatDayName(DateTime date) {
    return DateFormat('EEEE', 'fr_FR').format(date);
  }

  /// Formate le nom d'un mois (ex: "Mars")
  static String formatMonthName(DateTime date) {
    return DateFormat('MMMM', 'fr_FR').format(date);
  }

  /// Formate le mois et l'année (ex: "Mars 2024")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une date pour l'affichage dans un calendrier (ex: "15 Mar")
  static String formatCalendarDate(DateTime date) {
    return DateFormat('d MMM', 'fr_FR').format(date);
  }

  /// Formate une date pour un sélecteur de date (ex: "15 mars 2024")
  static String formatDatePicker(DateTime date) {
    return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une durée en français (ex: "2 heures 30 minutes")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0 && minutes > 0) {
      return '$hours heure${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours heure${hours > 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return 'Moins d\'une minute';
    }
  }

  /// Formate l'âge en français (ex: "25 ans")
  static String formatAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final hasHadBirthdayThisYear = now.month > birthDate.month || 
        (now.month == birthDate.month && now.day >= birthDate.day);
    
    final finalAge = hasHadBirthdayThisYear ? age : age - 1;
    return '$finalAge an${finalAge > 1 ? 's' : ''}';
  }

  /// Parse une date depuis un string au format français
  static DateTime? parseDate(String dateString) {
    try {
      // Essaie différents formats
      final formats = [
        'dd/MM/yyyy',
        'd/M/yyyy',
        'dd/MM/yy',
        'd/M/yy',
        'yyyy-MM-dd',
        'd MMMM yyyy',
        'dd MMMM yyyy',
      ];
      
      for (final format in formats) {
        try {
          return DateFormat(format, 'fr_FR').parse(dateString);
        } catch (e) {
          continue;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Valide si une string est une date valide
  static bool isValidDate(String dateString) {
    return parseDate(dateString) != null;
  }

  /// Retourne la date de début de semaine (lundi)
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Retourne la date de fin de semaine (dimanche)
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// Retourne le premier jour du mois
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Retourne le dernier jour du mois
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Formate une plage de dates
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && 
        startDate.month == endDate.month && 
        startDate.day == endDate.day) {
      return formatMediumDate(startDate);
    } else if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return 'Du ${startDate.day} au ${endDate.day} ${formatMonthName(startDate)} ${startDate.year}';
    } else if (startDate.year == endDate.year) {
      return 'Du ${startDate.day} ${formatMonthName(startDate)} au ${endDate.day} ${formatMonthName(endDate)} ${startDate.year}';
    } else {
      return 'Du ${formatMediumDate(startDate)} au ${formatMediumDate(endDate)}';
    }
  }
}