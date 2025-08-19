import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/page_model.dart';
import '../services/pages_firebase_service.dart';
import '../widgets/page_card.dart';
import 'page_builder_page.dart';
import 'page_preview_page.dart';
import '../theme.dart';

class PagesHomePage extends StatefulWidget {
const PagesHomePage({super.key});

@override
State<PagesHomePage> createState() => _PagesHomePageState();
}

class _PagesHomePageState extends State<PagesHomePage>
with TickerProviderStateMixin {
final TextEditingController _searchController = TextEditingController();
final ScrollController _scrollController = ScrollController();

String _searchQuery = '';
String _statusFilter = '';
String _visibilityFilter = '';

late AnimationController _fabAnimationController;
late Animation<double> _fabAnimation;
late TabController _tabController;

List<CustomPageModel> _selectedPages = [];
bool _isSelectionMode = false;

final List<Map<String, String>> _statusFilters = [
{'value': '', 'label': 'Tous les statuts'},
{'value': 'draft', 'label': 'Brouillons'},
{'value': 'published', 'label': 'Publiées'},
{'value': 'archived', 'label': 'Archivées'},
];

final List<Map<String, String>> _visibilityFilters = [
{'value': '', 'label': 'Toutes les visibilités'},
{'value': 'public', 'label': 'Public'},
{'value': 'members', 'label': 'Membres connectés'},
{'value': 'groups', 'label': 'Groupes spécifiques'},
{'value': 'roles', 'label': 'Rôles spécifiques'},
];

@override
void initState() {
super.initState();
_fabAnimationController = AnimationController(
duration: const Duration(milliseconds: 200),
vsync: this,
);
_fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
);
_tabController = TabController(length: 2, vsync: this);
_fabAnimationController.forward();
}

@override
void dispose() {
_searchController.dispose();
_scrollController.dispose();
_fabAnimationController.dispose();
_tabController.dispose();
super.dispose();
}

void _onSearchChanged(String query) {
setState(() => _searchQuery = query);
}

void _onStatusFilterChanged(String? status) {
setState(() => _statusFilter = status ?? '');
}

void _onVisibilityFilterChanged(String? visibility) {
setState(() => _visibilityFilter = visibility ?? '');
}

void _toggleSelectionMode() {
setState(() {
_isSelectionMode = !_isSelectionMode;
_selectedPages.clear();
});
}

void _onPageSelected(CustomPageModel page, bool isSelected) {
setState(() {
if (isSelected) {
_selectedPages.add(page);
} else {
_selectedPages.remove(page);
}
});
}

Future<void> _createNewPage() async {
final result = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const PageBuilderPage(),
),
);

if (result == true) {
// Page créée avec succès
_showSnackBar('Page créée avec succès', Colors.green);
}
}

Future<void> _createFromTemplate() async {
final templates = await PagesFirebaseService.getPageTemplates();

if (!mounted) return;

showDialog(
context: context,
builder: (context) => _TemplateSelectionDialog(templates: templates),
).then((selectedTemplate) async {
if (selectedTemplate != null) {
final result = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => PageBuilderPage(template: selectedTemplate),
),
);

if (result == true) {
_showSnackBar('Page créée à partir du modèle', Colors.green);
}
}
});
}

Future<void> _performBulkAction(String action) async {
if (_selectedPages.isEmpty) return;

switch (action) {
case 'publish':
await _publishSelectedPages();
break;
case 'archive':
await _archiveSelectedPages();
break;
case 'delete':
await _showDeleteConfirmation();
break;
}
}

Future<void> _publishSelectedPages() async {
try {
for (final page in _selectedPages) {
if (page.status == 'draft') {
await PagesFirebaseService.publishPage(page.id);
}
}
_showSnackBar('${_selectedPages.length} page(s) publiée(s)', Colors.green);
_toggleSelectionMode();
} catch (e) {
_showSnackBar('Erreur lors de la publication: $e', Colors.red);
}
}

Future<void> _archiveSelectedPages() async {
try {
for (final page in _selectedPages) {
if (page.status != 'archived') {
await PagesFirebaseService.archivePage(page.id);
}
}
_showSnackBar('${_selectedPages.length} page(s) archivée(s)', Colors.orange);
_toggleSelectionMode();
} catch (e) {
_showSnackBar('Erreur lors de l\'archivage: $e', Colors.red);
}
}

Future<void> _showDeleteConfirmation() async {
final confirm = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: const Text('Confirmer la suppression'),
content: Text(
'Êtes-vous sûr de vouloir supprimer ${_selectedPages.length} page(s) ? '
'Cette action est irréversible.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Annuler'),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
child: const Text('Supprimer'),
),
],
),
);

if (confirm == true) {
try {
for (final page in _selectedPages) {
await PagesFirebaseService.deletePage(page.id);
}
_showSnackBar('${_selectedPages.length} page(s) supprimée(s)', Colors.red);
_toggleSelectionMode();
} catch (e) {
_showSnackBar('Erreur lors de la suppression: $e', Colors.red);
}
}
}

void _copyPageUrl(CustomPageModel page) {
final url = 'https://app.churchflow.com/pages/${page.slug}';
Clipboard.setData(ClipboardData(text: url));
_showSnackBar('URL copiée: ${page.slug}', AppTheme.primaryColor);
}

void _showSnackBar(String message, Color color) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: color,
behavior: SnackBarBehavior.floating,
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Constructeur de Pages'),
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
elevation: 0,
actions: [
if (_isSelectionMode) ...[
IconButton(
onPressed: () => _showBulkActionsMenu(),
icon: const Icon(Icons.more_vert),
),
] else ...[
IconButton(
onPressed: _createFromTemplate,
icon: const Icon(Icons.file_copy),
tooltip: 'Créer depuis un modèle',
),
IconButton(
onPressed: _toggleSelectionMode,
icon: const Icon(Icons.checklist),
tooltip: 'Mode sélection',
),
],
],
bottom: TabBar(
controller: _tabController,
indicatorColor: Colors.white,
labelColor: Colors.white,
unselectedLabelColor: Colors.white70,
tabs: const [
Tab(text: 'Mes Pages', icon: Icon(Icons.web)),
Tab(text: 'Modèles', icon: Icon(Icons.web_asset)),
],
),
),
body: TabBarView(
controller: _tabController,
children: [
_buildPagesTab(),
_buildTemplatesTab(),
],
),
floatingActionButton: ScaleTransition(
scale: _fabAnimation,
child: FloatingActionButton.extended(
onPressed: _isSelectionMode ? null : _createNewPage,
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
icon: const Icon(Icons.add),
label: const Text('Nouvelle Page'),
),
),
);
}

Widget _buildPagesTab() {
return Column(
children: [
_buildSearchAndFilters(),
Expanded(
child: _buildPagesList(),
),
],
);
}

Widget _buildTemplatesTab() {
return FutureBuilder<List<PageTemplate>>(
future: PagesFirebaseService.getPageTemplates(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(child: CircularProgressIndicator());
}

if (snapshot.hasError) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.error, size: 64, color: Colors.grey[400]),
const SizedBox(height: 16),
Text(
'Erreur: ${snapshot.error}',
style: Theme.of(context).textTheme.bodyLarge,
textAlign: TextAlign.center,
),
],
),
);
}

final templates = snapshot.data ?? [];

if (templates.isEmpty) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.web_asset, size: 64, color: Colors.grey[400]),
const SizedBox(height: 16),
Text(
'Aucun modèle disponible',
style: Theme.of(context).textTheme.headlineSmall,
),
const SizedBox(height: 8),
Text(
'Les modèles vous permettent de créer rapidement des pages prédéfinies',
style: Theme.of(context).textTheme.bodyMedium,
textAlign: TextAlign.center,
),
],
),
);
}

return _buildTemplatesList(templates);
},
);
}

Widget _buildSearchAndFilters() {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 4,
offset: const Offset(0, 2),
),
],
),
child: Column(
children: [
// Barre de recherche
TextField(
controller: _searchController,
onChanged: _onSearchChanged,
decoration: InputDecoration(
hintText: 'Rechercher une page...',
prefixIcon: const Icon(Icons.search),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
onPressed: () {
_searchController.clear();
_onSearchChanged('');
},
icon: const Icon(Icons.clear),
)
: null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
filled: true,
fillColor: Colors.grey[100],
),
),
const SizedBox(height: 16),
// Filtres
Row(
children: [
Expanded(
child: DropdownButtonFormField<String>(
value: _statusFilter.isEmpty ? null : _statusFilter,
decoration: InputDecoration(
labelText: 'Statut',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(8),
),
contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
),
items: _statusFilters.map((filter) {
return DropdownMenuItem(
value: filter['value']!.isEmpty ? null : filter['value'],
child: Text(filter['label']!),
);
}).toList(),
onChanged: _onStatusFilterChanged,
),
),
const SizedBox(width: 16),
Expanded(
child: DropdownButtonFormField<String>(
value: _visibilityFilter.isEmpty ? null : _visibilityFilter,
decoration: InputDecoration(
labelText: 'Visibilité',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(8),
),
contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
),
items: _visibilityFilters.map((filter) {
return DropdownMenuItem(
value: filter['value']!.isEmpty ? null : filter['value'],
child: Text(filter['label']!),
);
}).toList(),
onChanged: _onVisibilityFilterChanged,
),
),
],
),
],
),
);
}

Widget _buildPagesList() {
return StreamBuilder<List<CustomPageModel>>(
stream: PagesFirebaseService.getPagesStream(
searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
visibilityFilter: _visibilityFilter.isEmpty ? null : _visibilityFilter,
),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(child: CircularProgressIndicator());
}

if (snapshot.hasError) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.error, size: 64, color: Colors.grey[400]),
const SizedBox(height: 16),
Text(
'Erreur: ${snapshot.error}',
style: Theme.of(context).textTheme.bodyLarge,
textAlign: TextAlign.center,
),
],
),
);
}

final pages = snapshot.data ?? [];

if (pages.isEmpty) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.web, size: 64, color: Colors.grey[400]),
const SizedBox(height: 16),
Text(
'Aucune page trouvée',
style: Theme.of(context).textTheme.headlineSmall,
),
const SizedBox(height: 8),
Text(
'Créez votre première page personnalisée',
style: Theme.of(context).textTheme.bodyMedium,
),
const SizedBox(height: 24),
ElevatedButton.icon(
onPressed: _createNewPage,
icon: const Icon(Icons.add),
label: const Text('Créer une page'),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
),
),
],
),
);
}

return ListView.separated(
controller: _scrollController,
padding: const EdgeInsets.all(16),
itemCount: pages.length,
separatorBuilder: (context, index) => const SizedBox(height: 16),
itemBuilder: (context, index) {
final page = pages[index];
return PageCard(
page: page,
onTap: () => _onPageTap(page),
onLongPress: () => _onPageLongPress(page),
isSelectionMode: _isSelectionMode,
isSelected: _selectedPages.contains(page),
onSelectionChanged: (isSelected) => _onPageSelected(page, isSelected),
onCopyUrl: () => _copyPageUrl(page),
);
},
);
},
);
}

Widget _buildTemplatesList(List<PageTemplate> templates) {
final categories = templates
.map((t) => t.category)
.toSet()
.toList()
..sort();

return ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: categories.length,
itemBuilder: (context, index) {
final category = categories[index];
final categoryTemplates = templates
.where((t) => t.category == category)
.toList();

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (index > 0) const SizedBox(height: 24),
Text(
category,
style: Theme.of(context).textTheme.headlineSmall?.copyWith(
color: AppTheme.primaryColor,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
...categoryTemplates.map((template) => Padding(
padding: const EdgeInsets.only(bottom: 12),
child: _buildTemplateCard(template),
)),
],
);
},
);
}

Widget _buildTemplateCard(PageTemplate template) {
return Card(
child: ListTile(
leading: CircleAvatar(
backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
child: Icon(
template.iconName != null ? Icons.web_asset : Icons.web,
color: AppTheme.primaryColor,
),
),
title: Text(template.name),
subtitle: Text(template.description),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
if (template.isBuiltIn)
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: Colors.blue.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Text(
'Intégré',
style: TextStyle(
color: Colors.blue[700],
fontSize: 12,
fontWeight: FontWeight.w500,
),
),
),
const SizedBox(width: 8),
const Icon(Icons.arrow_forward_ios, size: 16),
],
),
onTap: () async {
final result = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => PageBuilderPage(template: template),
),
);

if (result == true) {
_showSnackBar('Page créée à partir du modèle', Colors.green);
}
},
),
);
}

void _onPageTap(CustomPageModel page) {
if (_isSelectionMode) {
_onPageSelected(page, !_selectedPages.contains(page));
} else {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => PagePreviewPage(page: page),
),
);
}
}

void _onPageLongPress(CustomPageModel page) {
if (!_isSelectionMode) {
_toggleSelectionMode();
_onPageSelected(page, true);
}
}

void _showBulkActionsMenu() {
showModalBottomSheet(
context: context,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
),
builder: (context) => Container(
padding: const EdgeInsets.all(16),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
height: 4,
width: 40,
decoration: BoxDecoration(
color: Colors.grey[300],
borderRadius: BorderRadius.circular(2),
),
),
const SizedBox(height: 16),
Text(
'${_selectedPages.length} page(s) sélectionnée(s)',
style: Theme.of(context).textTheme.titleMedium,
),
const SizedBox(height: 16),
ListTile(
leading: const Icon(Icons.publish, color: Colors.green),
title: const Text('Publier'),
onTap: () {
Navigator.pop(context);
_performBulkAction('publish');
},
),
ListTile(
leading: const Icon(Icons.archive, color: Colors.orange),
title: const Text('Archiver'),
onTap: () {
Navigator.pop(context);
_performBulkAction('archive');
},
),
ListTile(
leading: const Icon(Icons.delete, color: Colors.red),
title: const Text('Supprimer'),
onTap: () {
Navigator.pop(context);
_performBulkAction('delete');
},
),
],
),
),
);
}
}

class _TemplateSelectionDialog extends StatelessWidget {
final List<PageTemplate> templates;

const _TemplateSelectionDialog({required this.templates});

@override
Widget build(BuildContext context) {
return AlertDialog(
title: const Text('Choisir un modèle'),
content: SizedBox(
width: double.maxFinite,
child: ListView.builder(
shrinkWrap: true,
itemCount: templates.length,
itemBuilder: (context, index) {
final template = templates[index];
return ListTile(
leading: Icon(
template.iconName != null ? Icons.web_asset : Icons.web,
color: AppTheme.primaryColor,
),
title: Text(template.name),
subtitle: Text(template.description),
onTap: () => Navigator.pop(context, template),
);
},
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Annuler'),
),
],
);
}
}