import 'dart:convert';
import 'package:flutter/services.dart';
import 'bible_model.dart';

/// Service pour charger et rechercher dans la Bible (texte local JSON)
class BibleService {
  List<BibleBook>? _books;

  Future<void> loadBible() async {
    final String data = await rootBundle.loadString('assets/bible/lsg1910.json');
    final List<dynamic> jsonData = json.decode(data);
    _books = jsonData.map((b) => BibleBook(
      name: b['name'],
      chapters: List<List<String>>.from(
        b['chapters'].map<List<String>>((c) => List<String>.from(c))))).toList();
  }

  List<BibleBook> get books => _books ?? [];

  BibleVerse? getVerse(String book, int chapter, int verse) {
    final b = _books?.firstWhere((bk) => bk.name == book, orElse: () => BibleBook(name: '', chapters: []));
    if (b == null || b.chapters.isEmpty) return null;
    if (chapter < 1 || chapter > b.chapters.length) return null;
    final ch = b.chapters[chapter - 1];
    if (verse < 1 || verse > ch.length) return null;
    return BibleVerse(book: book, chapter: chapter, verse: verse, text: ch[verse - 1]);
  }

  // Recherche simple (texte)
  List<BibleVerse> search(String query) {
    final List<BibleVerse> results = [];
    for (final book in books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          if (book.chapters[c][v].toLowerCase().contains(query.toLowerCase())) {
            results.add(BibleVerse(
              book: book.name,
              chapter: c + 1,
              verse: v + 1,
              text: book.chapters[c][v]));
          }
        }
      }
    }
    return results;
  }
}
