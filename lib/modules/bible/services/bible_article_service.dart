import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_article.dart';

class BibleArticleService {
  static const String _articlesKey = 'bible_articles';
  static const String _readingStatsKey = 'article_reading_stats';

  static BibleArticleService? _instance;
  static BibleArticleService get instance => _instance ??= BibleArticleService._();
  
  BibleArticleService._();

  /// Obtenir tous les articles
  Future<List<BibleArticle>> getArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = prefs.getString(_articlesKey);
    
    if (articlesJson == null) {
      // Créer des articles de démonstration si aucun n'existe
      final demoArticles = _createDemoArticles();
      await saveArticles(demoArticles);
      return demoArticles;
    }
    
    final List<dynamic> articlesList = json.decode(articlesJson);
    return articlesList.map((json) => BibleArticle.fromJson(json)).toList();
  }

  /// Sauvegarder tous les articles
  Future<void> saveArticles(List<BibleArticle> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = json.encode(articles.map((article) => article.toJson()).toList());
    await prefs.setString(_articlesKey, articlesJson);
  }

  /// Obtenir un article par ID
  Future<BibleArticle?> getArticleById(String id) async {
    final articles = await getArticles();
    try {
      return articles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ajouter un nouvel article
  Future<void> addArticle(BibleArticle article) async {
    final articles = await getArticles();
    articles.add(article);
    await saveArticles(articles);
  }

  /// Mettre à jour un article existant
  Future<void> updateArticle(BibleArticle updatedArticle) async {
    final articles = await getArticles();
    final index = articles.indexWhere((article) => article.id == updatedArticle.id);
    
    if (index != -1) {
      articles[index] = updatedArticle;
      await saveArticles(articles);
    }
  }

  /// Supprimer un article
  Future<void> deleteArticle(String articleId) async {
    final articles = await getArticles();
    articles.removeWhere((article) => article.id == articleId);
    await saveArticles(articles);
    
    // Supprimer aussi les statistiques de lecture associées
    await _deleteReadingStatsForArticle(articleId);
  }

  /// Obtenir les articles par catégorie
  Future<List<BibleArticle>> getArticlesByCategory(String category) async {
    final articles = await getArticles();
    return articles.where((article) => 
      article.category == category && article.isPublished
    ).toList();
  }

  /// Rechercher des articles
  Future<List<BibleArticle>> searchArticles(String query) async {
    final articles = await getArticles();
    final lowerQuery = query.toLowerCase();
    
    return articles.where((article) {
      return article.isPublished && (
        article.title.toLowerCase().contains(lowerQuery) ||
        article.summary.toLowerCase().contains(lowerQuery) ||
        article.content.toLowerCase().contains(lowerQuery) ||
        article.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        article.author.toLowerCase().contains(lowerQuery)
      );
    }).toList();
  }

  /// Obtenir les articles récents
  Future<List<BibleArticle>> getRecentArticles({int limit = 5}) async {
    final articles = await getArticles();
    final publishedArticles = articles.where((article) => article.isPublished).toList();
    
    publishedArticles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return publishedArticles.take(limit).toList();
  }

  /// Obtenir les articles populaires
  Future<List<BibleArticle>> getPopularArticles({int limit = 5}) async {
    final articles = await getArticles();
    final publishedArticles = articles.where((article) => article.isPublished).toList();
    
    publishedArticles.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return publishedArticles.take(limit).toList();
  }

  /// Marquer un article comme lu
  Future<void> markArticleAsRead(String articleId, {String userId = 'default'}) async {
    // Incrémenter le compteur de vues de l'article
    final article = await getArticleById(articleId);
    if (article != null) {
      final updatedArticle = article.copyWith(viewCount: article.viewCount + 1);
      await updateArticle(updatedArticle);
    }

    // Mettre à jour les statistiques de lecture utilisateur
    final stats = await getReadingStats(userId, articleId);
    if (stats != null) {
      final updatedStats = stats.copyWith(
        readCount: stats.readCount + 1,
        lastReadAt: DateTime.now());
      await saveReadingStats(updatedStats);
    } else {
      final newStats = ArticleReadingStats(
        userId: userId,
        articleId: articleId,
        readCount: 1);
      await saveReadingStats(newStats);
    }
  }

  /// Obtenir les statistiques de lecture d'un utilisateur pour un article
  Future<ArticleReadingStats?> getReadingStats(String userId, String articleId) async {
    final allStats = await getAllReadingStats();
    try {
      return allStats.firstWhere(
        (stats) => stats.userId == userId && stats.articleId == articleId);
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarder les statistiques de lecture
  Future<void> saveReadingStats(ArticleReadingStats stats) async {
    final allStats = await getAllReadingStats();
    final existingIndex = allStats.indexWhere(
      (s) => s.userId == stats.userId && s.articleId == stats.articleId);

    if (existingIndex != -1) {
      allStats[existingIndex] = stats;
    } else {
      allStats.add(stats);
    }

    final prefs = await SharedPreferences.getInstance();
    final statsJson = json.encode(allStats.map((s) => s.toJson()).toList());
    await prefs.setString(_readingStatsKey, statsJson);
  }

  /// Obtenir toutes les statistiques de lecture
  Future<List<ArticleReadingStats>> getAllReadingStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_readingStatsKey);
    
    if (statsJson == null) return [];
    
    final List<dynamic> statsList = json.decode(statsJson);
    return statsList.map((json) => ArticleReadingStats.fromJson(json)).toList();
  }

  /// Ajouter/retirer un article des favoris
  Future<void> toggleBookmark(String articleId, {String userId = 'default'}) async {
    final stats = await getReadingStats(userId, articleId);
    if (stats != null) {
      final updatedStats = stats.copyWith(isBookmarked: !stats.isBookmarked);
      await saveReadingStats(updatedStats);
    } else {
      final newStats = ArticleReadingStats(
        userId: userId,
        articleId: articleId,
        isBookmarked: true);
      await saveReadingStats(newStats);
    }
  }

  /// Obtenir les articles favoris d'un utilisateur
  Future<List<BibleArticle>> getBookmarkedArticles({String userId = 'default'}) async {
    final allStats = await getAllReadingStats();
    final bookmarkedStats = allStats.where(
      (stats) => stats.userId == userId && stats.isBookmarked).toList();

    final articles = await getArticles();
    return articles.where((article) => 
      bookmarkedStats.any((stats) => stats.articleId == article.id)
    ).toList();
  }

  /// Supprimer les statistiques de lecture pour un article
  Future<void> _deleteReadingStatsForArticle(String articleId) async {
    final allStats = await getAllReadingStats();
    allStats.removeWhere((stats) => stats.articleId == articleId);
    
    final prefs = await SharedPreferences.getInstance();
    final statsJson = json.encode(allStats.map((s) => s.toJson()).toList());
    await prefs.setString(_readingStatsKey, statsJson);
  }

  /// Obtenir les catégories disponibles
  List<String> getAvailableCategories() {
    return BibleArticleCategory.values.map((category) => category.displayName).toList();
  }

  /// Obtenir les statistiques générales
  Future<Map<String, dynamic>> getGeneralStats() async {
    final articles = await getArticles();
    final allStats = await getAllReadingStats();

    final publishedArticles = articles.where((a) => a.isPublished).length;
    final totalViews = articles.fold<int>(0, (sum, article) => sum + article.viewCount);
    final totalReads = allStats.fold<int>(0, (sum, stats) => sum + stats.readCount);

    return {
      'totalArticles': articles.length,
      'publishedArticles': publishedArticles,
      'totalViews': totalViews,
      'totalReads': totalReads,
      'categoriesCount': Set.from(articles.map((a) => a.category)).length,
    };
  }

  /// Créer des articles de démonstration
  List<BibleArticle> _createDemoArticles() {
    return [
      BibleArticle(
        title: "La Grâce de Dieu : Comprendre l'Amour Inconditionnel",
        summary: "Découvrez la profondeur de la grâce divine et comment elle transforme nos vies quotidiennes.",
        content: """
La grâce de Dieu est l'un des concepts les plus fondamentaux et les plus réconfortants de la foi chrétienne. Elle représente l'amour inconditionnel de Dieu envers l'humanité, un amour qui ne dépend pas de nos mérites ou de nos actions.

## Qu'est-ce que la Grâce ?

La grâce, dans son essence, est un don immérité. C'est la faveur divine accordée à ceux qui ne la méritent pas. Éphésiens 2:8-9 nous rappelle : "C'est par la grâce que vous êtes sauvés, par le moyen de la foi. Et cela ne vient pas de vous, c'est le don de Dieu. Ce n'est point par les œuvres, afin que personne ne se glorifie."

## La Grâce dans l'Ancien Testament

Bien que souvent associée au Nouveau Testament, la grâce de Dieu est présente throughout l'Ancien Testament. L'histoire de Noé, la patience de Dieu envers Israël, et les nombreuses occasions où Dieu pardonne à son peuple témoignent de sa grâce constante.

## Vivre par la Grâce

Comprendre la grâce nous libère de l'anxiété spirituelle et nous permet de vivre dans la paix. Elle nous encourage à faire preuve de la même grâce envers les autres, créant un cycle d'amour et de pardon dans nos communautés.

## Application Pratique

1. **Accepter le pardon** : Cessons de porter le poids de nos erreurs passées
2. **Partager la grâce** : Soyons patients et compatissants envers les autres
3. **Vivre dans la liberté** : Laissons la grâce nous guider dans nos décisions quotidiennes

La grâce de Dieu n'est pas seulement un concept théologique, c'est une réalité vivante qui peut transformer chaque aspect de notre existence.
        """,
        category: BibleArticleCategory.theology.displayName,
        author: "Pasteur Martin Dubois",
        tags: ["grâce", "salut", "amour de Dieu", "théologie"],
        bibleReferences: [
          BibleReference(book: "Éphésiens", chapter: 2, startVerse: 8, endVerse: 9),
          BibleReference(book: "Romains", chapter: 3, startVerse: 23, endVerse: 24),
          BibleReference(book: "Tite", chapter: 2, startVerse: 11),
        ],
        readingTimeMinutes: 8,
        viewCount: 145),

      BibleArticle(
        title: "L'Histoire de David : Leçons de Courage et de Foi",
        summary: "Explorez la vie extraordinaire du roi David et les leçons intemporelles qu'elle nous enseigne.",
        content: """
David, le berger devenu roi, reste l'une des figures les plus fascinantes de l'Ancien Testament. Son parcours, marqué par des victoires éclatantes et des échecs humiliants, nous offre un aperçu profond de la nature humaine et de la fidélité de Dieu.

## Le Jeune Berger

L'histoire de David commence dans les champs de Bethléem, où il garde les moutons de son père. C'est là qu'il apprend la fidélité, la responsabilité et développe une relation intime avec Dieu à travers la prière et la méditation.

## Face au Géant

Le combat contre Goliath n'est pas seulement une histoire de courage physique, mais une démonstration de foi absolue en Dieu. David ne comptait pas sur sa force, mais sur celle du Tout-Puissant.

## Le Roi Selon le Cœur de Dieu

Malgré ses imperfections, David est appelé "un homme selon le cœur de Dieu". Qu'est-ce qui le distinguait ?

1. **La repentance sincère** : Quand il péchait, David se repentait véritablement
2. **La passion pour Dieu** : Il désirait ardemment la présence divine
3. **L'humilité** : Il reconnaissait sa dépendance à Dieu

## Les Épreuves et les Triomphes

La vie de David nous enseigne que même les serviteurs de Dieu les plus fidèles traversent des épreuves. Ses Psaumes révèlent ses luttes intérieures et sa confiance indéfectible en Dieu.

## Leçons pour Aujourd'hui

- **Commencer petit** : Dieu utilise souvent des commencements humbles
- **Faire confiance à Dieu** : Face aux défis impossibles, la foi fait la différence
- **Accepter la discipline** : Les erreurs sont des opportunités d'apprentissage
- **Maintenir l'adoration** : Même dans les difficultés, continuons à louer Dieu

L'héritage de David nous rappelle que Dieu peut utiliser des personnes imparfaites pour accomplir des œuvres parfaites.
        """,
        category: BibleArticleCategory.biography.displayName,
        author: "Dr. Sarah Leclerc",
        tags: ["David", "courage", "foi", "leadership", "repentance"],
        bibleReferences: [
          BibleReference(book: "1 Samuel", chapter: 17),
          BibleReference(book: "2 Samuel", chapter: 7),
          BibleReference(book: "Psaume", chapter: 23),
          BibleReference(book: "Actes", chapter: 13, startVerse: 22),
        ],
        readingTimeMinutes: 12,
        viewCount: 203),

      BibleArticle(
        title: "Les Paraboles de Jésus : Sagesse pour la Vie Quotidienne",
        summary: "Découvrez comment les enseignements de Jésus en paraboles s'appliquent à notre vie moderne.",
        content: """
Les paraboles de Jésus sont des joyaux de sagesse spirituelle, des histoires simples qui révèlent des vérités profondes sur le Royaume de Dieu et la vie chrétienne. Chaque parabole est une invitation à réfléchir et à grandir dans notre foi.

## Pourquoi des Paraboles ?

Jésus utilisait les paraboles pour plusieurs raisons :
- **Accessibilité** : Des histoires que tout le monde pouvait comprendre
- **Mémorabilité** : Plus faciles à retenir que des concepts abstraits
- **Révélation progressive** : Elles révèlent la vérité à ceux qui cherchent sincèrement

## La Parabole du Semeur

Cette parabole nous enseigne sur la réception de la Parole de Dieu :
- **Le chemin** : Cœurs fermés à la vérité
- **Les endroits pierreux** : Foi superficielle sans racines
- **Les épines** : Préoccupations mondaines qui étouffent la foi
- **La bonne terre** : Cœurs réceptifs qui portent du fruit

## La Parabole du Bon Samaritain

Cette histoire révolutionne notre compréhension de l'amour du prochain :
- **L'amour au-delà des barrières** : Ethniques, religieuses, sociales
- **L'action concrète** : La compassion doit se traduire en actes
- **La responsabilité individuelle** : Chacun peut être un "prochain"

## La Parabole des Talents

Cette parabole nous enseigne sur la responsabilité et la fidélité :
- **Utiliser nos dons** : Dieu nous confie des capacités à développer
- **La fidélité dans le peu** : Commencer là où nous sommes
- **La croissance progressive** : Dieu nous confie plus quand nous sommes fidèles

## Application Moderne

1. **Écouter activement** : Comment recevons-nous la Parole de Dieu ?
2. **Aimer sans condition** : Qui sont nos "prochains" aujourd'hui ?
3. **Servir fidèlement** : Comment utilisons-nous nos talents et ressources ?
4. **Persévérer dans la prière** : Comme la veuve importune, soyons persistants

## Conclusion

Les paraboles de Jésus ne sont pas de simples histoires du passé, mais des guides pratiques pour naviguer dans la complexité de la vie moderne. Elles nous appellent à une transformation authentique et à une foi vivante.
        """,
        category: BibleArticleCategory.teachings.displayName,
        author: "Révérend Pierre Moreau",
        tags: ["paraboles", "enseignements", "Jésus", "sagesse", "application pratique"],
        bibleReferences: [
          BibleReference(book: "Matthieu", chapter: 13, startVerse: 3, endVerse: 23),
          BibleReference(book: "Luc", chapter: 10, startVerse: 25, endVerse: 37),
          BibleReference(book: "Matthieu", chapter: 25, startVerse: 14, endVerse: 30),
        ],
        readingTimeMinutes: 10,
        viewCount: 178),

      BibleArticle(
        title: "La Prière : Communication avec le Divin",
        summary: "Approfondissez votre vie de prière et découvrez comment développer une relation plus intime avec Dieu.",
        content: """
La prière est bien plus qu'une simple récitation de mots ; c'est le souffle de la vie spirituelle, le moyen privilégié de communication entre l'âme humaine et son Créateur. Dans un monde en constante agitation, la prière nous offre un refuge de paix et de connexion divine.

## L'Essence de la Prière

La prière authentique combine plusieurs éléments :
- **L'adoration** : Reconnaître la grandeur de Dieu
- **La confession** : Admettre nos faiblesses et nos erreurs
- **La gratitude** : Remercier pour les bénédictions reçues
- **La supplication** : Présenter nos besoins et ceux des autres

## Le Modèle du Notre Père

Jésus nous a enseigné un modèle parfait de prière :

### "Notre Père qui es aux cieux"
- Reconnaissance de la paternité divine
- Intimité et respect combinés

### "Que ton nom soit sanctifié"
- Priorité à la gloire de Dieu
- Désir de voir Dieu honoré

### "Que ton règne vienne"
- Soumission à la volonté divine
- Espérance du royaume éternel

### "Donne-nous aujourd'hui notre pain quotidien"
- Dépendance quotidienne de Dieu
- Confiance en sa provision

### "Pardonne-nous nos offenses"
- Humilité et repentance
- Besoin constant de grâce

### "Ne nous induis pas en tentation"
- Reconnaissance de notre faiblesse
- Désir de protection divine

## Types de Prière

**Prière personnelle** : Moments intimes avec Dieu
**Prière liturgique** : Prières structurées de l'Église
**Prière contemplative** : Méditation silencieuse
**Prière d'intercession** : Prier pour les autres

## Obstacles à la Prière

- **Le doute** : Questionner l'efficacité de la prière
- **La distraction** : Difficultés de concentration
- **L'impatience** : Attendre les réponses de Dieu
- **L'égoïsme** : Se centrer uniquement sur ses besoins

## Cultiver une Vie de Prière

1. **Établir un rythme** : Temps réguliers de prière
2. **Créer un espace sacré** : Lieu dédié à la prière
3. **Utiliser les Écritures** : Laisser la Parole nourrir nos prières
4. **Tenir un journal** : Noter les prières et les réponses
5. **Jeûner occasionnellement** : Intensifier la recherche de Dieu

## La Prière Exaucée

Dieu répond toujours à nos prières, mais pas toujours comme nous l'attendons :
- **Oui** : Quand c'est selon sa volonté
- **Non** : Quand ce n'est pas bon pour nous
- **Attends** : Quand le timing n'est pas le bon

## Conclusion

La prière transforme non seulement nos circonstances, mais surtout nos cœurs. Elle nous aligne sur les desseins de Dieu et nous remplit de sa paix. Cultivons cette discipline spirituelle précieuse pour une vie chrétienne épanouie.
        """,
        category: BibleArticleCategory.devotional.displayName,
        author: "Sœur Marie-Claire",
        tags: ["prière", "spiritualité", "communion", "Notre Père", "méditation"],
        bibleReferences: [
          BibleReference(book: "Matthieu", chapter: 6, startVerse: 9, endVerse: 13),
          BibleReference(book: "1 Thessaloniciens", chapter: 5, startVerse: 17),
          BibleReference(book: "Philippe", chapter: 4, startVerse: 6, endVerse: 7),
        ],
        readingTimeMinutes: 7,
        viewCount: 267),

      BibleArticle(
        title: "L'Archéologie Biblique : Quand l'Histoire Confirme les Écritures",
        summary: "Explorez les découvertes archéologiques fascinantes qui éclairent et confirment les récits bibliques.",
        content: """
L'archéologie biblique nous offre une fenêtre extraordinaire sur le monde ancien des Écritures. Chaque découverte nous rapproche un peu plus de la compréhension du contexte historique dans lequel se déroulent les événements bibliques.

## L'Importance de l'Archéologie Biblique

L'archéologie ne "prouve" pas la Bible, mais elle :
- **Éclaire le contexte** : Comprendre les cultures de l'époque
- **Confirme l'historicité** : Valider l'existence de lieux et personnages
- **Enrichit la compréhension** : Donner vie aux récits anciens

## Découvertes Majeures

### Les Manuscrits de Qumran
Découverts en 1947, ces manuscrits ont révolutionné notre compréhension :
- Textes bibliques antérieurs de 1000 ans aux copies connues
- Confirmation de la fidélité de la transmission textuelle
- Insight sur le judaïsme du premier siècle

### La Stèle de Tel Dan
Cette inscription du 9ème siècle av. J.-C. mentionne la "Maison de David", confirmant l'existence historique du roi David.

### Les Archives de Nuzi
Ces tablettes du 15ème siècle av. J.-C. éclairent les coutumes patriarcales mentionnées dans la Genèse.

### L'Inscription de Ponce Pilate
Découverte à Césarée Maritime, elle confirme l'existence historique du gouverneur romain mentionné dans les Évangiles.

## L'Exode : Preuves et Débats

Les preuves archéologiques de l'Exode restent débattues :
- **Absence de traces directes** : Difficile de tracer 40 ans dans le désert
- **Évidences indirectes** : Destructions de villes cananéennes
- **Considérations méthodologiques** : Limites de l'archéologie

## Jérusalem à travers les Âges

Les fouilles de Jérusalem révèlent :
- **La Cité de David** : Noyau original de Jérusalem
- **Le Mur des Lamentations** : Vestige du Second Temple
- **Quartiers du premier siècle** : Contexte de la vie de Jésus

## Défis et Controverses

L'archéologie biblique fait face à plusieurs défis :
- **Interprétation des données** : Risque de biais confirmatoire
- **Contexte politique** : Tensions au Moyen-Orient
- **Évolution des méthodes** : Nouvelles technologies, nouvelles découvertes

## Découvertes Récentes

### La Maison de Pierre à Bethsaïde
Possible maison de l'apôtre Pierre, éclairant la vie des premiers disciples.

### L'Inscription de la Piscine de Siloé
Confirmation de l'existence de cette piscine mentionnée dans Jean 9.

### Les Sceaux de Jérémie
Bulles d'argile portant les noms de personnages mentionnés dans le livre de Jérémie.

## Impact sur la Foi

L'archéologie biblique :
- **Renforce la confiance** : Dans l'historicité des récits
- **Enrichit la lecture** : Compréhension du contexte
- **Stimule l'étude** : Curiosité pour approfondir les Écritures

## Conclusion

L'archéologie biblique continue de nous surprendre et d'enrichir notre compréhension des Écritures. Chaque découverte nous rappelle que la Bible n'est pas un livre de mythes, mais un témoignage ancré dans l'histoire réelle de l'humanité.

Restons curieux et ouverts aux nouvelles découvertes qui continuent d'éclairer notre compréhension de la Parole de Dieu.
        """,
        category: BibleArticleCategory.archaeology.displayName,
        author: "Dr. Emmanuel Rosier",
        tags: ["archéologie", "histoire", "découvertes", "manuscrits", "confirmations"],
        bibleReferences: [
          BibleReference(book: "2 Timothée", chapter: 3, startVerse: 16),
          BibleReference(book: "Luc", chapter: 1, startVerse: 1, endVerse: 4),
        ],
        readingTimeMinutes: 15,
        viewCount: 89),
    ];
  }
}
