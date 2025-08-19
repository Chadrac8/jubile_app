import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/thematic_passage_model.dart';
import '../services/thematic_passage_service.dart';
import '../bible_service.dart';
import '../widgets/theme_creation_dialog.dart';
import '../widgets/add_passage_dialog.dart';

class ThematicPassagesView extends StatefulWidget {
  final String? selectedThemeId;
  
  const ThematicPassagesView({
    Key? key,
    this.selectedThemeId,
  }) : super(key: key);

  @override
  State<ThematicPassagesView> createState() => _ThematicPassagesViewState();
}

class _ThematicPassagesViewState extends State<ThematicPassagesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedThemeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedThemeId = widget.selectedThemeId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          'Passages thématiques',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Thèmes'),
            Tab(text: 'Mes passages'),
          ]),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: theme.colorScheme.primary),
            onPressed: () => _showCreateThemeDialog()),
        ]),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemesTab(),
          _buildUserPassagesTab(),
        ]));
  }

  Widget _buildThemesTab() {
    return StreamBuilder<List<BiblicalTheme>>(
      stream: ThematicPassageService.getPublicThemes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.error)));
        }
        
        final themes = snapshot.data ?? [];
        
        if (themes.isEmpty) {
          return _buildEmptyThemes();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final theme = themes[index];
            final isSelected = theme.id == _selectedThemeId;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showThemeDetails(theme),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.color.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.color
                          : Colors.transparent,
                      width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                    ]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          theme.icon,
                          color: theme.color,
                          size: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              theme.description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    '${theme.passages.length} passages',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.color))),
                              ]),
                          ])),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    ]))));
          });
      });
  }

  Widget _buildUserPassagesTab() {
    return StreamBuilder<List<BiblicalTheme>>(
      stream: ThematicPassageService.getUserThemes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('Erreur dans _buildUserPassagesTab: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                  Text(
                    'Impossible de charger vos thèmes personnels',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {}); // Rebuilder la vue
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer')),
                ])));
        }
        
        final userThemes = snapshot.data ?? [];
        
        if (userThemes.isEmpty) {
          return _buildEmptyUserThemes();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userThemes.length,
          itemBuilder: (context, index) {
            final theme = userThemes[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showThemeDetails(theme),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                    ]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          theme.icon,
                          color: theme.color,
                          size: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                              theme.description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    '${theme.passages.length} passages',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.color))),
                              ]),
                          ])),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditThemeDialog(theme);
                          } else if (value == 'delete') {
                            _showDeleteThemeDialog(theme);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ])),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: AppTheme.errorColor,
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: AppTheme.errorColor),
                              ])),
                        ]),
                    ]))));
          });
      });
  }

  Widget _buildEmptyThemes() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Aucun thème disponible',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Text(
              'Initialisez les thèmes par défaut pour commencer',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ThematicPassageService.initializeDefaultThemes();
              },
              child: Text(
                'Initialiser les thèmes',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ])));
  }

  Widget _buildEmptyUserThemes() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour créer des thèmes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Créez vos propres collections de passages bibliques en vous connectant à votre compte',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Vous pouvez ajouter ici la navigation vers la page de connexion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité de connexion à implémenter'),
                        backgroundColor: AppTheme.warningColor));
                  },
                  icon: const Icon(Icons.login),
                  label: Text(
                    'Se connecter',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCreateThemeDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Créer un thème',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              ]),
          ])));
  }

  void _showThemeDetails(BiblicalTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ThemeDetailsSheet(theme: theme));
  }

  void _showCreateThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => const ThemeCreationDialog());
  }

  void _showEditThemeDialog(BiblicalTheme theme) {
    showDialog(
      context: context,
      builder: (context) => ThemeCreationDialog(themeToEdit: theme));
  }

  void _showDeleteThemeDialog(BiblicalTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le thème',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le thème "${theme.name}" ?',
          style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter())),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ThematicPassageService.deleteTheme(theme.id);
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600))),
        ]));
  }
}

class _ThemeDetailsSheet extends StatelessWidget {
  final BiblicalTheme theme;
  
  const _ThemeDetailsSheet({required this.theme});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    theme.icon,
                    color: theme.color,
                    size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeData.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: themeData.colorScheme.onSurface.withOpacity(0.7))),
                    ])),
                if (!theme.isPublic || theme.createdBy == 'current_user') // TODO: Vérifier l'utilisateur actuel
                  IconButton(
                    onPressed: () => _showAddPassageDialog(context, theme),
                    icon: Icon(
                      Icons.add,
                      color: theme.color),
                    tooltip: 'Ajouter un passage'),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: themeData.colorScheme.onSurface)),
              ])),
          
          // Passages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: theme.passages.length,
              itemBuilder: (context, index) {
                final passage = theme.passages[index];
                return _PassageCard(passage: passage);
              })),
        ]));
  }

  void _showAddPassageDialog(BuildContext context, BiblicalTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AddPassageDialog(
        themeId: theme.id,
        themeName: theme.name));
  }
}

class _PassageCard extends StatelessWidget {
  final ThematicPassage passage;
  
  const _PassageCard({required this.passage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            passage.reference,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _getVerseText(passage),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Chargement...');
              }
              
              if (snapshot.hasError || !snapshot.hasData) {
                return Text(
                  'Erreur de chargement du verset',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.error));
              }
              
              return Text(
                snapshot.data!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.5));
            }),
          if (passage.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                passage.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.7)))),
          ],
        ]));
  }

  Future<String> _getVerseText(ThematicPassage passage) async {
    try {
      final bibleService = BibleService();
      await bibleService.loadBible();
      final verse = bibleService.getVerse(passage.book, passage.chapter, passage.startVerse);
      
      if (passage.endVerse != null && passage.endVerse! > passage.startVerse) {
        // Récupérer plusieurs versets
        final List<String> verses = [];
        for (int v = passage.startVerse; v <= passage.endVerse!; v++) {
          final currentVerse = bibleService.getVerse(passage.book, passage.chapter, v);
          if (currentVerse != null) {
            verses.add('${v}. ${currentVerse.text}');
          }
        }
        return verses.join(' ');
      } else {
        return verse?.text ?? 'Verset non trouvé';
      }
    } catch (e) {
      return 'Erreur de chargement';
    }
  }
}
