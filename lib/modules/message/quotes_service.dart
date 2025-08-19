import '../models/quote_model.dart';

/// Service pour gérer les citations de William Marrion Branham
class QuotesService {
  static final QuotesService _instance = QuotesService._internal();
  factory QuotesService() => _instance;
  QuotesService._internal();

  List<Quote>? _cachedQuotes;
  List<String>? _cachedThemes;

  /// Récupère toutes les citations
  Future<List<Quote>> getAllQuotes() async {
    if (_cachedQuotes != null) {
      return _cachedQuotes!;
    }

    try {
      // Pour l'instant, on utilise des données de démonstration
      // Plus tard, on pourra charger depuis un fichier JSON ou une API
      _cachedQuotes = _generateDemoQuotes();
      return _cachedQuotes!;
    } catch (e) {
      throw Exception('Erreur lors du chargement des citations: $e');
    }
  }

  /// Récupère tous les thèmes disponibles
  Future<List<String>> getThemes() async {
    if (_cachedThemes != null) {
      return _cachedThemes!;
    }

    final quotes = await getAllQuotes();
    _cachedThemes = quotes
        .map((q) => q.theme)
        .toSet()
        .toList()
        ..sort();

    return _cachedThemes!;
  }

  /// Recherche des citations par mots-clés
  Future<List<Quote>> searchQuotes(String query) async {
    final quotes = await getAllQuotes();
    final lowercaseQuery = query.toLowerCase();

    return quotes.where((quote) =>
        quote.text.toLowerCase().contains(lowercaseQuery) ||
        quote.theme.toLowerCase().contains(lowercaseQuery) ||
        quote.reference.toLowerCase().contains(lowercaseQuery) ||
        quote.keywords.any((k) => k.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Récupère les citations par thème
  Future<List<Quote>> getQuotesByTheme(String theme) async {
    final quotes = await getAllQuotes();
    return quotes.where((q) => q.theme == theme).toList();
  }

  /// Récupère une citation aléatoire
  Future<Quote> getRandomQuote() async {
    final quotes = await getAllQuotes();
    if (quotes.isEmpty) {
      throw Exception('Aucune citation disponible');
    }
    quotes.shuffle();
    return quotes.first;
  }

  /// Met à jour le statut favori d'une citation
  Future<void> toggleFavorite(String quoteId) async {
    final quotes = await getAllQuotes();
    final index = quotes.indexWhere((q) => q.id == quoteId);
    
    if (index != -1) {
      _cachedQuotes![index] = quotes[index].copyWith(
        isFavorite: !quotes[index].isFavorite);
    }
  }

  /// Récupère les citations favorites
  Future<List<Quote>> getFavoriteQuotes() async {
    final quotes = await getAllQuotes();
    return quotes.where((q) => q.isFavorite).toList();
  }

  /// Génère des données de démonstration
  List<Quote> _generateDemoQuotes() {
    return [
      Quote(
        id: '1',
        text: 'La foi n\'est pas ce que vous pensez que c\'est. La foi, c\'est quand vous savez que quelque chose va arriver et vous agissez en conséquence.',
        theme: 'Foi',
        reference: 'La Foi qui était une fois donnée aux Saints - 14 Juillet 1963',
        date: '14 Juillet 1963',
        sermonTitle: 'La Foi qui était une fois donnée aux Saints',
        location: 'Branham Tabernacle',
        keywords: ['foi', 'action', 'certitude'],
        createdAt: DateTime.now()),
      Quote(
        id: '2',
        text: 'Dieu ne peut pas changer Sa Parole. Il doit rester avec Sa Parole. C\'est pourquoi Il vous demande d\'avoir la foi.',
        theme: 'Parole de Dieu',
        reference: 'Avoir Foi en Dieu - 27 Novembre 1955',
        date: '27 Novembre 1955',
        sermonTitle: 'Avoir Foi en Dieu',
        location: 'Shreveport, Louisiana',
        keywords: ['parole', 'dieu', 'immuable', 'foi'],
        createdAt: DateTime.now()),
      Quote(
        id: '3',
        text: 'L\'amour couvre la multitude des péchés. Quand vous aimez quelqu\'un, vous ne voyez pas ses défauts.',
        theme: 'Amour',
        reference: 'L\'Amour - 12 Décembre 1965',
        date: '12 Décembre 1965',
        sermonTitle: 'L\'Amour',
        location: 'Shreveport, Louisiana',
        keywords: ['amour', 'péchés', 'pardon', 'défauts'],
        createdAt: DateTime.now()),
      Quote(
        id: '4',
        text: 'La prière change les choses. La prière change les hommes, et les hommes changent les choses.',
        theme: 'Prière',
        reference: 'Comment prier - 8 Mars 1959',
        date: '8 Mars 1959',
        sermonTitle: 'Comment prier',
        location: 'Branham Tabernacle',
        keywords: ['prière', 'changement', 'transformation'],
        createdAt: DateTime.now()),
      Quote(
        id: '5',
        text: 'Il n\'y a qu\'une seule chose qui puisse satisfaire le cœur humain, et c\'est l\'amour de Dieu versé dans le cœur par le Saint-Esprit.',
        theme: 'Saint-Esprit',
        reference: 'L\'Esprit de Vérité - 18 Janvier 1963',
        date: '18 Janvier 1963',
        sermonTitle: 'L\'Esprit de Vérité',
        location: 'Phoenix, Arizona',
        keywords: ['saint-esprit', 'amour', 'satisfaction', 'cœur'],
        createdAt: DateTime.now()),
      Quote(
        id: '6',
        text: 'Nous ne suivons pas les sensations, nous suivons la Parole. La Parole produit la sensation, et non la sensation qui produit la Parole.',
        theme: 'Parole de Dieu',
        reference: 'La Parole parlée - 26 Décembre 1965',
        date: '26 Décembre 1965',
        sermonTitle: 'La Parole parlée',
        location: 'Jeffersonville, Indiana',
        keywords: ['parole', 'sensations', 'émotions', 'vérité'],
        createdAt: DateTime.now()),
      Quote(
        id: '7',
        text: 'Le baptême du Saint-Esprit n\'est pas une émotion. C\'est une Personne, la troisième Personne de la Trinité qui vient habiter en vous.',
        theme: 'Saint-Esprit',
        reference: 'Questions et Réponses - 30 Août 1964',
        date: '30 Août 1964',
        sermonTitle: 'Questions et Réponses',
        location: 'Jeffersonville, Indiana',
        keywords: ['saint-esprit', 'personne', 'trinité', 'habiter'],
        createdAt: DateTime.now()),
      Quote(
        id: '8',
        text: 'Si vous pouvez prendre Dieu au mot et agir comme si c\'était vrai, alors c\'est vrai pour vous.',
        theme: 'Foi',
        reference: 'Agir par la Foi - 17 Novembre 1957',
        date: '17 Novembre 1957',
        sermonTitle: 'Agir par la Foi',
        location: 'Jeffersonville, Indiana',
        keywords: ['foi', 'action', 'parole', 'vérité'],
        createdAt: DateTime.now()),
      Quote(
        id: '9',
        text: 'La guérison divine n\'est pas quelque chose que vous obtenez, c\'est quelque chose que vous avez déjà. C\'est votre héritage.',
        theme: 'Guérison Divine',
        reference: 'La Guérison Divine - 22 Mai 1954',
        date: '22 Mai 1954',
        sermonTitle: 'La Guérison Divine',
        location: 'Louisville, Kentucky',
        keywords: ['guérison', 'héritage', 'possession', 'divine'],
        createdAt: DateTime.now()),
      Quote(
        id: '10',
        text: 'L\'humilité et la foi vont toujours ensemble. Vous ne pouvez pas avoir la foi sans l\'humilité.',
        theme: 'Humilité',
        reference: 'L\'Humilité - 11 Octobre 1962',
        date: '11 Octobre 1962',
        sermonTitle: 'L\'Humilité',
        location: 'Jeffersonville, Indiana',
        keywords: ['humilité', 'foi', 'ensemble', 'caractère'],
        createdAt: DateTime.now()),
    ];
  }

  /// Vide le cache (utile pour les tests ou le refresh)
  void clearCache() {
    _cachedQuotes = null;
    _cachedThemes = null;
  }
}
