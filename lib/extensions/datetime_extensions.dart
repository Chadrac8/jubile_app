import '../utils/date_formatter.dart';

/// Extensions pour DateTime pour faciliter le formatage en français
extension DateTimeExtensions on DateTime {
  /// Formate une date courte (ex: 15/03/2024)
  String get shortDate => DateFormatter.formatShortDate(this);

  /// Formate une date longue (ex: vendredi 15 mars 2024)
  String get longDate => DateFormatter.formatLongDate(this);

  /// Formate une date médium (ex: 15 mars 2024)
  String get mediumDate => DateFormatter.formatMediumDate(this);

  /// Formate une heure (ex: 14:30)
  String get timeOnly => DateFormatter.formatTime(this);

  /// Formate une date et heure complète (ex: vendredi 15 mars 2024 à 14:30)
  String get dateTime => DateFormatter.formatDateTime(this);

  /// Formate une date et heure courte (ex: 15/03/2024 14:30)
  String get shortDateTime => DateFormatter.formatShortDateTime(this);

  /// Formate une date et heure médium (ex: 15 mars 2024 à 14:30)
  String get mediumDateTime => DateFormatter.formatMediumDateTime(this);

  /// Formate une date relative (ex: "Aujourd'hui", "Hier", "Il y a 2 jours")
  String get relativeDate => DateFormatter.formatRelativeDate(this);

  /// Formate une date relative avec l'heure (ex: "Aujourd'hui à 14:30")
  String get relativeDateTime => DateFormatter.formatRelativeDateTime(this);

  /// Formate le nom d'un jour de la semaine (ex: "Lundi")
  String get dayName => DateFormatter.formatDayName(this);

  /// Formate le nom d'un mois (ex: "Mars")
  String get monthName => DateFormatter.formatMonthName(this);

  /// Formate le mois et l'année (ex: "Mars 2024")
  String get monthYear => DateFormatter.formatMonthYear(this);

  /// Formate une date pour l'affichage dans un calendrier (ex: "15 Mar")
  String get calendarDate => DateFormatter.formatCalendarDate(this);

  /// Formate une date pour un sélecteur de date (ex: "15 mars 2024")
  String get datePickerFormat => DateFormatter.formatDatePicker(this);

  /// Calcule et formate l'âge par rapport à aujourd'hui (ex: "25 ans")
  String get age => DateFormatter.formatAge(this);

  /// Retourne la date de début de semaine (lundi) pour cette date
  DateTime get weekStart => DateFormatter.getWeekStart(this);

  /// Retourne la date de fin de semaine (dimanche) pour cette date
  DateTime get weekEnd => DateFormatter.getWeekEnd(this);

  /// Retourne le premier jour du mois pour cette date
  DateTime get monthStart => DateFormatter.getMonthStart(this);

  /// Retourne le dernier jour du mois pour cette date
  DateTime get monthEnd => DateFormatter.getMonthEnd(this);

  /// Vérifie si cette date est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifie si cette date est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Vérifie si cette date est demain
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Vérifie si cette date est dans cette semaine
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.weekStart;
    final weekEnd = now.weekEnd;
    return isAfter(weekStart.subtract(const Duration(days: 1))) && 
           isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Vérifie si cette date est dans ce mois
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Vérifie si cette date est dans cette année
  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  /// Calcule le nombre de jours depuis cette date
  int get daysSince {
    final now = DateTime.now();
    return now.difference(this).inDays;
  }

  /// Calcule le nombre de jours jusqu'à cette date
  int get daysUntil {
    final now = DateTime.now();
    return difference(now).inDays;
  }
}

/// Extensions pour Duration pour le formatage en français
extension DurationExtensions on Duration {
  /// Formate une durée en français (ex: "2 heures 30 minutes")
  String get french => DateFormatter.formatDuration(this);
}