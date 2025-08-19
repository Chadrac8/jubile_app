import 'package:flutter/material.dart';

/// Page de base avec structure commune
/// Fournit une structure cohérente pour toutes les pages de l'application
class BasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const BasePage({
    Key? key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
              bottom: bottom,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
              elevation: 0,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Page de liste de base avec structure commune
class BaseListPage<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function() loadItems;
  final Widget Function(T item) buildItem;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? searchWidget;
  final String emptyMessage;
  final bool showRefresh;

  const BaseListPage({
    Key? key,
    required this.title,
    required this.loadItems,
    required this.buildItem,
    this.floatingActionButton,
    this.actions,
    this.searchWidget,
    this.emptyMessage = 'Aucun élément trouvé',
    this.showRefresh = true,
  }) : super(key: key);

  @override
  State<BaseListPage<T>> createState() => _BaseListPageState<T>();
}

class _BaseListPageState<T> extends State<BaseListPage<T>> {
  bool _isLoading = true;
  List<T> _items = [];
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

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.title,
      actions: widget.actions,
      floatingActionButton: widget.floatingActionButton,
      body: Column(
        children: [
          if (widget.searchWidget != null) widget.searchWidget!,
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
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
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    Widget listView = ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) => widget.buildItem(_items[index]),
    );

    if (widget.showRefresh) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: listView,
      );
    }

    return listView;
  }
}

/// Page de formulaire de base
class BaseFormPage extends StatefulWidget {
  final String title;
  final Widget form;
  final VoidCallback? onSave;
  final bool isLoading;
  final String saveButtonText;

  const BaseFormPage({
    Key? key,
    required this.title,
    required this.form,
    this.onSave,
    this.isLoading = false,
    this.saveButtonText = 'Enregistrer',
  }) : super(key: key);

  @override
  State<BaseFormPage> createState() => _BaseFormPageState();
}

class _BaseFormPageState extends State<BaseFormPage> {
  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.title,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.form,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.saveButtonText),
            ),
          ),
        ],
      ),
    );
  }
}