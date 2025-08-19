import 'package:flutter/material.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import '../../models/dashboard_widget_model.dart';
import '../../services/dashboard_firebase_service.dart';
import '../../services/statistics_service.dart';
import '../../widgets/dashboard_widgets/dashboard_stat_widget.dart';
import '../../widgets/dashboard_widgets/dashboard_chart_widget.dart';
import '../../widgets/dashboard_widgets/dashboard_list_widget.dart';
import '../../widgets/member_view_toggle_button.dart';
import '../../widgets/bottom_navigation_wrapper.dart';
import 'dashboard_configuration_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<DashboardWidgetModel> _widgets = [];
  Map<String, dynamic> _preferences = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Vérifier si l'utilisateur a des widgets configurés
      final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets();
      
      if (!hasWidgets) {
        // Initialiser les widgets par défaut
        await DashboardFirebaseService.initializeDefaultWidgets();
      }

      // Charger les préférences
      _preferences = await DashboardFirebaseService.getDashboardPreferences();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation du dashboard: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement du dashboard: $e';
      });
    }
  }

  Future<void> _refreshDashboard() async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      // Recharger les préférences
      _preferences = await DashboardFirebaseService.getDashboardPreferences();

      setState(() {
        _isRefreshing = false;
      });

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard actualisé'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'actualisation: $e');
      setState(() {
        _isRefreshing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton de basculement vers la vue membre
          AppBarMemberViewToggle(
            onToggle: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
                ),
                (route) => false,
              );
            },
          ),
          // Bouton de rafraîchissement
          IconButton(
            onPressed: _isRefreshing ? null : _refreshDashboard,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          // Bouton de configuration
          IconButton(
            onPressed: () => _navigateToConfiguration(),
            icon: const Icon(Icons.settings),
            tooltip: 'Configurer le dashboard',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du dashboard...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeDashboard,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<DashboardWidgetModel>>(
      stream: DashboardFirebaseService.getDashboardWidgetsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeDashboard,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final widgets = snapshot.data!;
        
        if (widgets.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: _buildDashboardGrid(widgets),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun widget configuré',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configurez votre dashboard pour afficher les statistiques importantes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToConfiguration,
            icon: const Icon(Icons.settings),
            label: const Text('Configurer le Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(List<DashboardWidgetModel> widgets) {
    final compactView = _preferences['compactView'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        itemCount: widgets.length,
        itemBuilder: (context, index) {
          final widget = widgets[index];
          return _buildDashboardWidget(widget, compactView);
        },
        staggeredTileBuilder: (index) {
          final widget = widgets[index];
          return _getStaggeredTile(widget, compactView);
        },
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
    );
  }

  StaggeredTile _getStaggeredTile(DashboardWidgetModel widget, bool compactView) {
    switch (widget.type) {
      case 'stat':
        return compactView 
            ? const StaggeredTile.count(2, 1)
            : const StaggeredTile.count(2, 1.2);
      case 'chart':
        return compactView 
            ? const StaggeredTile.count(4, 2)
            : const StaggeredTile.count(4, 2.5);
      case 'list':
        return compactView 
            ? const StaggeredTile.count(4, 2)
            : const StaggeredTile.count(4, 3);
      default:
        return const StaggeredTile.count(2, 1);
    }
  }

  Widget _buildDashboardWidget(DashboardWidgetModel widget, bool compactView) {
    switch (widget.type) {
      case 'stat':
        return FutureBuilder<DashboardStatModel>(
          future: StatisticsService.calculateWidgetStatistics(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardStatWidget(
                stat: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      case 'chart':
        return FutureBuilder<DashboardChartModel>(
          future: StatisticsService.calculateChartData(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardChartWidget(
                chart: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      case 'list':
        return FutureBuilder<DashboardListModel>(
          future: StatisticsService.calculateListData(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardListWidget(
                listData: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('Widget non supporté: ${widget.type}'),
            ),
          ),
        );
    }
  }

  Widget _buildLoadingWidget(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToConfiguration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DashboardConfigurationPage(),
      ),
    );
  }
}