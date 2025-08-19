import 'package:flutter/material.dart';
import 'base_page.dart';

/// Page de base pour les listes avec fonctionnalités communes
class BaseListPage<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function() loadItems;
  final Widget Function(T) buildItem;
  final Widget? searchWidget;
  final String emptyMessage;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showRefreshButton;
  final Function(T)? onItemTap;

  const BaseListPage({
    Key? key,
    required this.title,
    required this.loadItems,
    required this.buildItem,
    this.searchWidget,
    this.emptyMessage = 'Aucun élément trouvé',
    this.floatingActionButton,
    this.actions,
    this.showRefreshButton = true,
    this.onItemTap,
  }) : super(key: key);

  @override
  State<BaseListPage<T>> createState() => _BaseListPageState<T>();
}

class _BaseListPageState<T> extends State<BaseListPage<T>> {
  List<T> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.loadItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.title,
      actions: [
        if (widget.showRefreshButton)
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ...?widget.actions,
      ],
      floatingActionButton: widget.floatingActionButton,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            if (widget.searchWidget != null) widget.searchWidget!,
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return InkWell(
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
          child: widget.buildItem(item),
        );
      },
    );
  }
}