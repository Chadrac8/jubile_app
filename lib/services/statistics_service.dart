import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_widget_model.dart';
import '../models/person_model.dart';
import 'firebase_service.dart';
import 'groups_firebase_service.dart';
import 'events_firebase_service.dart';
import 'tasks_firebase_service.dart';
import 'appointments_firebase_service.dart';
import 'blog_firebase_service.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculer les statistiques pour un widget donné
  static Future<DashboardStatModel> calculateWidgetStatistics(DashboardWidgetModel widget) async {
    try {
      switch (widget.id) {
        // Statistiques des personnes
        case 'persons_total':
          return await _getPersonsTotal(widget);
        case 'persons_active':
          return await _getPersonsActive(widget);
        case 'persons_new_this_month':
          return await _getPersonsNewThisMonth(widget);
          
        // Statistiques des groupes
        case 'groups_total':
          return await _getGroupsTotal(widget);
        case 'groups_active':
          return await _getGroupsActive(widget);
          
        // Statistiques des événements
        case 'events_upcoming':
          return await _getEventsUpcoming(widget);
        case 'events_this_month':
          return await _getEventsThisMonth(widget);
          
        // Statistiques des services
        case 'services_upcoming':
          return await _getServicesUpcoming(widget);
          
        // Statistiques des tâches
        case 'tasks_pending':
          return await _getTasksPending(widget);
          
        // Statistiques des rendez-vous
        case 'appointments_today':
          return await _getAppointmentsToday(widget);
          
        // Statistiques du blog
        case 'blog_posts_published':
          return await _getBlogPostsPublished(widget);
        case 'blog_posts_draft':
          return await _getBlogPostsDraft(widget);
        case 'blog_comments_total':
          return await _getBlogCommentsTotal(widget);
          
        default:
          return DashboardStatModel(
            label: widget.title,
            value: '0',
            icon: widget.config['icon'],
            color: widget.config['color'],
          );
      }
    } catch (e) {
      print('Erreur lors du calcul des statistiques pour ${widget.id}: $e');
      return DashboardStatModel(
        label: widget.title,
        value: 'Erreur',
        icon: widget.config['icon'],
        color: widget.config['color'],
      );
    }
  }

  // Calculer les données de graphique pour un widget
  static Future<DashboardChartModel> calculateChartData(DashboardWidgetModel widget) async {
    try {
      switch (widget.id) {
        case 'persons_by_age':
          return await _getPersonsByAge(widget);
        case 'groups_by_type':
          return await _getGroupsByType(widget);
        default:
          return DashboardChartModel(
            title: widget.title,
            type: widget.config['chartType'] ?? 'pie',
            data: [],
          );
      }
    } catch (e) {
      print('Erreur lors du calcul des données de graphique pour ${widget.id}: $e');
      return DashboardChartModel(
        title: widget.title,
        type: widget.config['chartType'] ?? 'pie',
        data: [],
      );
    }
  }

  // Calculer les données de liste pour un widget
  static Future<DashboardListModel> calculateListData(DashboardWidgetModel widget) async {
    try {
      switch (widget.id) {
        case 'recent_members':
          return await _getRecentMembers(widget);
        case 'upcoming_events':
          return await _getUpcomingEvents(widget);
        default:
          return DashboardListModel(
            title: widget.title,
            items: [],
          );
      }
    } catch (e) {
      print('Erreur lors du calcul des données de liste pour ${widget.id}: $e');
      return DashboardListModel(
        title: widget.title,
        items: [],
      );
    }
  }

  // MÉTHODES PRIVÉES POUR LES STATISTIQUES SPÉCIFIQUES

  static Future<DashboardStatModel> _getPersonsTotal(DashboardWidgetModel widget) async {
    final snapshot = await _firestore.collection('persons').get();
    final total = snapshot.docs.length;
    
    String? trend;
    String? trendValue;
    
    if (widget.config['showTrend'] == true) {
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));
      final lastMonthSnapshot = await _firestore
          .collection('persons')
          .where('createdAt', isLessThan: lastMonth.toIso8601String())
          .get();
      
      final lastMonthTotal = lastMonthSnapshot.docs.length;
      final currentMonthNew = total - lastMonthTotal;
      
      if (currentMonthNew > 0) {
        trend = 'up';
        trendValue = '+$currentMonthNew ce mois';
      } else if (currentMonthNew < 0) {
        trend = 'down';
        trendValue = '$currentMonthNew ce mois';
      } else {
        trend = 'stable';
      }
    }
    
    return DashboardStatModel(
      label: widget.title,
      value: total.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
      trend: trend,
      trendValue: trendValue,
    );
  }

  static Future<DashboardStatModel> _getPersonsActive(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('persons')
        .where('isActive', isEqualTo: true)
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getPersonsNewThisMonth(DashboardWidgetModel widget) async {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final snapshot = await _firestore
        .collection('persons')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getGroupsTotal(DashboardWidgetModel widget) async {
    final snapshot = await _firestore.collection('groups').get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getGroupsActive(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getEventsUpcoming(DashboardWidgetModel widget) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('events')
        .where('startDate', isGreaterThan: now.toIso8601String())
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getEventsThisMonth(DashboardWidgetModel widget) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection('events')
        .where('startDate', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('startDate', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getServicesUpcoming(DashboardWidgetModel widget) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('services')
        .where('date', isGreaterThan: now.toIso8601String())
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getTasksPending(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'pending')
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getAppointmentsToday(DashboardWidgetModel widget) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();
    
    return DashboardStatModel(
      label: widget.title,
      value: snapshot.docs.length.toString(),
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardChartModel> _getPersonsByAge(DashboardWidgetModel widget) async {
    final snapshot = await _firestore.collection('persons').get();
    final persons = snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
    
    final ageGroups = <String, int>{
      '0-17 ans': 0,
      '18-35 ans': 0,
      '36-55 ans': 0,
      '56+ ans': 0,
      'Non renseigné': 0,
    };
    
    for (final person in persons) {
      if (person.birthDate != null) {
        final age = DateTime.now().difference(person.birthDate!).inDays ~/ 365;
        if (age <= 17) {
          ageGroups['0-17 ans'] = ageGroups['0-17 ans']! + 1;
        } else if (age <= 35) {
          ageGroups['18-35 ans'] = ageGroups['18-35 ans']! + 1;
        } else if (age <= 55) {
          ageGroups['36-55 ans'] = ageGroups['36-55 ans']! + 1;
        } else {
          ageGroups['56+ ans'] = ageGroups['56+ ans']! + 1;
        }
      } else {
        ageGroups['Non renseigné'] = ageGroups['Non renseigné']! + 1;
      }
    }
    
    final colors = ['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9E9E9E'];
    var colorIndex = 0;
    
    return DashboardChartModel(
      title: widget.title,
      type: widget.config['chartType'] ?? 'pie',
      data: ageGroups.entries
          .where((entry) => entry.value > 0)
          .map((entry) => DashboardChartDataPoint(
                label: entry.key,
                value: entry.value.toDouble(),
                color: colors[colorIndex++ % colors.length],
              ))
          .toList(),
    );
  }

  static Future<DashboardChartModel> _getGroupsByType(DashboardWidgetModel widget) async {
    final snapshot = await _firestore.collection('groups').get();
    final groupTypes = <String, int>{};
    
    for (final doc in snapshot.docs) {
      final groupType = doc.data()['type'] ?? 'Non défini';
      groupTypes[groupType] = (groupTypes[groupType] ?? 0) + 1;
    }
    
    final colors = ['#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#00BCD4'];
    var colorIndex = 0;
    
    return DashboardChartModel(
      title: widget.title,
      type: widget.config['chartType'] ?? 'bar',
      data: groupTypes.entries
          .map((entry) => DashboardChartDataPoint(
                label: entry.key,
                value: entry.value.toDouble(),
                color: colors[colorIndex++ % colors.length],
              ))
          .toList(),
    );
  }

  static Future<DashboardListModel> _getRecentMembers(DashboardWidgetModel widget) async {
    final limit = widget.config['limit'] ?? 5;
    final snapshot = await _firestore
        .collection('persons')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    
    final items = snapshot.docs.map((doc) {
      final person = PersonModel.fromFirestore(doc);
      return DashboardListItem(
        title: '${person.firstName} ${person.lastName}',
        subtitle: person.email ?? 'Email non renseigné',
        icon: 'person',
        color: '#2196F3',
      );
    }).toList();
    
    return DashboardListModel(
      title: widget.title,
      items: items,
      actionLabel: 'Voir tous',
    );
  }

  static Future<DashboardListModel> _getUpcomingEvents(DashboardWidgetModel widget) async {
    final limit = widget.config['limit'] ?? 5;
    final now = DateTime.now();
    
    final snapshot = await _firestore
        .collection('events')
        .where('startDate', isGreaterThan: now.toIso8601String())
        .orderBy('startDate')
        .limit(limit)
        .get();
    
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      final startDate = DateTime.parse(data['startDate']);
      final title = data['title'] ?? 'Événement sans titre';
      
      return DashboardListItem(
        title: title,
        subtitle: '${startDate.day}/${startDate.month}/${startDate.year}',
        icon: 'event',
        color: '#3F51B5',
      );
    }).toList();
    
    return DashboardListModel(
      title: widget.title,
      items: items,
      actionLabel: 'Voir tous',
    );
  }

  // ==================== STATISTIQUES BLOG ====================

  static Future<DashboardStatModel> _getBlogPostsPublished(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('blog_posts')
        .where('status', isEqualTo: 'published')
        .get();
    
    final currentCount = snapshot.docs.length;
    
    // Comparer avec le mois précédent
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    
    final lastMonthSnapshot = await _firestore
        .collection('blog_posts')
        .where('status', isEqualTo: 'published')
        .where('publishedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth))
        .where('publishedAt', isLessThanOrEqualTo: Timestamp.fromDate(lastMonthEnd))
        .get();
    
    final previousCount = lastMonthSnapshot.docs.length;
    
    return DashboardStatModel(
      label: widget.title,
      value: currentCount.toString(),
      subtitle: 'Articles publiés',
      icon: widget.config['icon'],
      color: widget.config['color'],
      trend: _calculateTrend(currentCount, previousCount),
    );
  }

  static Future<DashboardStatModel> _getBlogPostsDraft(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('blog_posts')
        .where('status', isEqualTo: 'draft')
        .get();
    
    final currentCount = snapshot.docs.length;
    
    return DashboardStatModel(
      label: widget.title,
      value: currentCount.toString(),
      subtitle: 'Brouillons',
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  static Future<DashboardStatModel> _getBlogCommentsTotal(DashboardWidgetModel widget) async {
    final snapshot = await _firestore
        .collection('blog_comments')
        .where('isApproved', isEqualTo: true)
        .get();
    
    final currentCount = snapshot.docs.length;
    
    // Comparer avec le mois précédent
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final thisMonthSnapshot = await _firestore
        .collection('blog_comments')
        .where('isApproved', isEqualTo: true)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    
    final thisMonthCount = thisMonthSnapshot.docs.length;
    
    return DashboardStatModel(
      label: widget.title,
      value: currentCount.toString(),
      subtitle: '$thisMonthCount nouveaux ce mois',
      icon: widget.config['icon'],
      color: widget.config['color'],
    );
  }

  /// Calculer la tendance entre deux valeurs
  static String? _calculateTrend(int current, int previous) {
    if (previous == 0) {
      return current > 0 ? 'up' : null;
    }
    
    if (current > previous) {
      return 'up';
    } else if (current < previous) {
      return 'down';
    } else {
      return 'stable';
    }
  }

  // Statistiques globales pour les rapports
  static Future<Map<String, dynamic>> getGlobalStatistics() async {
    try {
      final futures = await Future.wait([
        _firestore.collection('persons').get(),
        _firestore.collection('groups').get(),
        _firestore.collection('events').get(),
        _firestore.collection('services').get(),
        _firestore.collection('tasks').get(),
        _firestore.collection('appointments').get(),
      ]);

      final personsSnapshot = futures[0];
      final groupsSnapshot = futures[1];
      final eventsSnapshot = futures[2];
      final servicesSnapshot = futures[3];
      final tasksSnapshot = futures[4];
      final appointmentsSnapshot = futures[5];

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Calculer les personnes actives
      final activePersons = personsSnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      // Calculer les nouveaux membres ce mois
      final newMembersThisMonth = personsSnapshot.docs
          .where((doc) {
            final createdAt = doc.data()['createdAt'];
            if (createdAt != null) {
              final date = DateTime.parse(createdAt);
              return date.isAfter(startOfMonth);
            }
            return false;
          })
          .length;

      // Calculer les événements à venir
      final upcomingEvents = eventsSnapshot.docs
          .where((doc) {
            final startDate = doc.data()['startDate'];
            if (startDate != null) {
              final date = DateTime.parse(startDate);
              return date.isAfter(now);
            }
            return false;
          })
          .length;

      return {
        'totalPersons': personsSnapshot.docs.length,
        'activePersons': activePersons,
        'newMembersThisMonth': newMembersThisMonth,
        'totalGroups': groupsSnapshot.docs.length,
        'totalEvents': eventsSnapshot.docs.length,
        'upcomingEvents': upcomingEvents,
        'totalServices': servicesSnapshot.docs.length,
        'totalTasks': tasksSnapshot.docs.length,
        'totalAppointments': appointmentsSnapshot.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques globales: $e');
      return {};
    }
  }
}