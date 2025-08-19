import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/thematic_passage_service.dart';
import '../bible_service.dart';

class AddPassageDialog extends StatefulWidget {
  final String themeId;
  final String themeName;
  
  const AddPassageDialog({
    Key? key,
    required this.themeId,
    required this.themeName,
  }) : super(key: key);

  @override
  State<AddPassageDialog> createState() => _AddPassageDialogState();
}

class _AddPassageDialogState extends State<AddPassageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bookController = TextEditingController();
  final _chapterController = TextEditingController();
  final _startVerseController = TextEditingController();
  final _endVerseController = TextEditingController();
  
  bool _isLoading = false;
  String? _previewText;

  final List<String> _bibleBooks = [
    'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
    'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
    'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaumes',
    'Proverbes', 'Ecclésiaste', 'Cantique des cantiques',
    'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel',
    'Daniel', 'Osée', 'Joël', 'Amos', 'Abdias',
    'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie',
    'Aggée', 'Zacharie', 'Malachie',
    'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
    'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates',
    'Éphésiens', 'Philippiens', 'Colossiens',
    '1 Thessaloniciens', '2 Thessaloniciens',
    '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
    'Hébreux', 'Jacques', '1 Pierre', '2 Pierre',
    '1 Jean', '2 Jean', '3 Jean', 'Jude', 'Apocalypse'
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    _descriptionController.dispose();
    _bookController.dispose();
    _chapterController.dispose();
    _startVerseController.dispose();
    _endVerseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter un passage',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface)),
                        Text(
                          'au thème "${widget.themeName}"',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ])),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface)),
                ]),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Référence complète
                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Référence complète',
                          hintText: 'Ex: Jean 3:16 ou Matthieu 5:3-12',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.bookmark_border)),
                        onChanged: (value) => _parseReference(value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La référence est requise';
                          }
                          return null;
                        }),
                      
                      const SizedBox(height: 16),
                      
                      // Détails séparés
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _bookController.text.isEmpty ? null : _bookController.text,
                              decoration: InputDecoration(
                                labelText: 'Livre',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                              items: _bibleBooks.map((book) {
                                return DropdownMenuItem(
                                  value: book,
                                  child: Text(book));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _bookController.text = value ?? '';
                                });
                                _updateReference();
                              })),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _chapterController,
                              decoration: InputDecoration(
                                labelText: 'Chapitre',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateReference(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Nombre';
                                }
                                return null;
                              })),
                        ]),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startVerseController,
                              decoration: InputDecoration(
                                labelText: 'Verset début',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateReference(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Nombre';
                                }
                                return null;
                              })),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _endVerseController,
                              decoration: InputDecoration(
                                labelText: 'Verset fin (optionnel)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateReference())),
                        ]),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description ou note personnelle',
                          hintText: 'Pourquoi ce passage est-il important pour ce thème ?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Une description est requise';
                          }
                          return null;
                        }),
                      
                      const SizedBox(height: 20),
                      
                      // Aperçu du texte
                      if (_previewText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aperçu du texte :',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary)),
                              const SizedBox(height: 8),
                              Text(
                                _previewText!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.4)),
                            ])),
                        const SizedBox(height: 16),
                      ],
                      
                      // Bouton pour prévisualiser
                      if (_canPreview())
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _loadPreview,
                            icon: const Icon(Icons.preview),
                            label: Text(
                              'Prévisualiser le texte',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
                    ]))),
              
              const SizedBox(height: 20),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePassage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: AppTheme.surfaceColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Text(
                              'Ajouter',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
                ]),
            ]))));
  }

  void _parseReference(String reference) {
    // Exemple: "Jean 3:16" ou "Matthieu 5:3-12"
    final parts = reference.trim().split(' ');
    if (parts.length >= 2) {
      final bookPart = parts.sublist(0, parts.length - 1).join(' ');
      final versePart = parts.last;
      
      setState(() {
        _bookController.text = bookPart;
      });
      
      if (versePart.contains(':')) {
        final chapterVerse = versePart.split(':');
        if (chapterVerse.length == 2) {
          setState(() {
            _chapterController.text = chapterVerse[0];
          });
          
          if (chapterVerse[1].contains('-')) {
            final verses = chapterVerse[1].split('-');
            if (verses.length == 2) {
              setState(() {
                _startVerseController.text = verses[0];
                _endVerseController.text = verses[1];
              });
            }
          } else {
            setState(() {
              _startVerseController.text = chapterVerse[1];
              _endVerseController.text = '';
            });
          }
        }
      }
    }
  }

  void _updateReference() {
    if (_bookController.text.isNotEmpty &&
        _chapterController.text.isNotEmpty &&
        _startVerseController.text.isNotEmpty) {
      String reference = '${_bookController.text} ${_chapterController.text}:${_startVerseController.text}';
      
      if (_endVerseController.text.isNotEmpty &&
          _endVerseController.text != _startVerseController.text) {
        reference += '-${_endVerseController.text}';
      }
      
      setState(() {
        _referenceController.text = reference;
      });
    }
  }

  bool _canPreview() {
    return _bookController.text.isNotEmpty &&
        _chapterController.text.isNotEmpty &&
        _startVerseController.text.isNotEmpty &&
        int.tryParse(_chapterController.text) != null &&
        int.tryParse(_startVerseController.text) != null;
  }

  Future<void> _loadPreview() async {
    if (!_canPreview()) return;
    
    try {
      final bibleService = BibleService();
      await bibleService.loadBible();
      
      final startVerse = int.parse(_startVerseController.text);
      final endVerse = _endVerseController.text.isNotEmpty
          ? int.parse(_endVerseController.text)
          : startVerse;
      
      if (endVerse > startVerse) {
        List<String> verseTexts = [];
        for (int v = startVerse; v <= endVerse; v++) {
          final verse = bibleService.getVerse(
            _bookController.text,
            int.parse(_chapterController.text),
            v);
          if (verse != null) {
            verseTexts.add('${v}. ${verse.text}');
          }
        }
        setState(() {
          _previewText = verseTexts.join('\n');
        });
      } else {
        final verse = bibleService.getVerse(
          _bookController.text,
          int.parse(_chapterController.text),
          startVerse);
        setState(() {
          _previewText = verse?.text ?? 'Verset non trouvé';
        });
      }
    } catch (e) {
      setState(() {
        _previewText = 'Erreur lors du chargement : $e';
      });
    }
  }

  Future<void> _savePassage() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final startVerse = int.parse(_startVerseController.text);
      final endVerse = _endVerseController.text.isNotEmpty
          ? int.parse(_endVerseController.text)
          : null;
      
      await ThematicPassageService.addPassageToTheme(
        themeId: widget.themeId,
        reference: _referenceController.text,
        book: _bookController.text,
        chapter: int.parse(_chapterController.text),
        startVerse: startVerse,
        endVerse: endVerse,
        description: _descriptionController.text.trim());
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passage ajouté avec succès'),
            backgroundColor: AppTheme.successColor));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        String actionMessage;
        
        if (e.toString().contains('Connexion requise') || 
            e.toString().contains('authentification anonyme') ||
            e.toString().contains('admin-restricted-operation')) {
          errorMessage = 'Authentification requise';
          actionMessage = 'L\'authentification anonyme n\'est pas activée. Contactez l\'administrateur pour l\'activer dans Firebase Console.';
        } else {
          errorMessage = 'Erreur lors de l\'ajout';
          actionMessage = e.toString();
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.errorColor,
                const SizedBox(width: 8),
                Text(errorMessage),
              ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionMessage),
                const SizedBox(height: 16),
                const Text(
                  'Solutions possibles:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('• Activez l\'authentification anonyme dans Firebase'),
                const Text('• Connectez-vous avec un compte utilisateur'),
                const Text('• Contactez l\'administrateur de l\'application'),
              ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer')),
            ]));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
