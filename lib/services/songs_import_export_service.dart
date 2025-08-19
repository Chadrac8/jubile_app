import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';

/// Service pour l'import/export des chants en CSV et TXT
class SongsImportExportService {
  static const String _csvSeparator = ',';
  static const String _txtSeparator = '---';

  /// Exporte les chants en format CSV
  static Future<void> exportToCSV(List<SongModel> songs) async {
    try {
      // Créer les données CSV
      List<List<dynamic>> csvData = [];
      
      // Headers
      csvData.add([
        'Titre',
        'Auteurs',
        'Paroles',
        'Tonalité originale',
        'Style',
        'Tags',
        'Références bibliques',
        'Tempo',
        'URL audio',
        'Statut',
        'Visibilité',
        'Notes privées',
        'Nombre d\'utilisations',
        'Dernière utilisation',
        'Date de création',
        'Créé par',
        'Métadonnées'
      ]);

      // Données des chants
      for (var song in songs) {
        csvData.add([
          song.title,
          song.authors,
          _sanitizeText(song.lyrics),
          song.originalKey,
          song.style,
          song.tags.join(';'),
          song.bibleReferences.join(';'),
          song.tempo?.toString() ?? '',
          song.audioUrl ?? '',
          song.status,
          song.visibility,
          song.privateNotes ?? '',
          song.usageCount.toString(),
          song.lastUsedAt?.toIso8601String() ?? '',
          song.createdAt.toIso8601String(),
          song.createdBy,
          jsonEncode(song.metadata)
        ]);
      }

      // Convertir en CSV
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Sauvegarder et partager le fichier
      await _saveAndShare(
        content: csv,
        filename: 'chants_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv'
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'export CSV: $e');
    }
  }

  /// Exporte les chants en format TXT
  static Future<void> exportToTXT(List<SongModel> songs) async {
    try {
      StringBuffer buffer = StringBuffer();
      
      for (int i = 0; i < songs.length; i++) {
        var song = songs[i];
        
        buffer.writeln('TITRE: ${song.title}');
        buffer.writeln('AUTEURS: ${song.authors}');
        buffer.writeln('TONALITÉ: ${song.originalKey}');
        buffer.writeln('STYLE: ${song.style}');
        
        if (song.tags.isNotEmpty) {
          buffer.writeln('TAGS: ${song.tags.join(', ')}');
        }
        
        if (song.bibleReferences.isNotEmpty) {
          buffer.writeln('RÉFÉRENCES: ${song.bibleReferences.join(', ')}');
        }
        
        if (song.tempo != null) {
          buffer.writeln('TEMPO: ${song.tempo} BPM');
        }
        
        buffer.writeln('STATUT: ${song.status}');
        buffer.writeln('VISIBILITÉ: ${song.visibility}');
        buffer.writeln('UTILISATIONS: ${song.usageCount}');
        buffer.writeln('CRÉÉ PAR: ${song.createdBy}');
        buffer.writeln('DATE: ${song.createdAt.toIso8601String()}');
        
        if (song.privateNotes?.isNotEmpty == true) {
          buffer.writeln('NOTES: ${song.privateNotes}');
        }
        
        buffer.writeln('\nPAROLES:');
        buffer.writeln(song.lyrics);
        
        // Séparateur entre les chants
        if (i < songs.length - 1) {
          buffer.writeln('\n$_txtSeparator\n');
        }
      }

      // Sauvegarder et partager le fichier
      await _saveAndShare(
        content: buffer.toString(),
        filename: 'chants_${DateTime.now().millisecondsSinceEpoch}.txt',
        mimeType: 'text/plain'
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'export TXT: $e');
    }
  }

  /// Importe les chants depuis un fichier CSV
  static Future<List<SongModel>> importFromCSV() async {
    try {
      // Sélectionner le fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Aucun fichier sélectionné');
      }

      String content;
      if (kIsWeb) {
        // Web
        content = String.fromCharCodes(result.files.first.bytes!);
      } else {
        // Mobile/Desktop
        File file = File(result.files.single.path!);
        content = await file.readAsString();
      }

      // Parser le CSV
      List<List<dynamic>> csvData = const CsvToListConverter().convert(content);
      
      if (csvData.isEmpty) {
        throw Exception('Le fichier CSV est vide');
      }

      // Vérifier les headers (première ligne)
      List<dynamic> headers = csvData.first;
      if (headers.length < 3 || !headers.contains('Titre')) {
        throw Exception('Format CSV invalide. Vérifiez les en-têtes.');
      }

      List<SongModel> songs = [];
      
      // Parser chaque ligne (en ignorant les headers)
      for (int i = 1; i < csvData.length; i++) {
        List<dynamic> row = csvData[i];
        
        if (row.length < 3) continue; // Ignorer les lignes incomplètes
        
        try {
          var song = _parseSongFromCSVRow(row);
          songs.add(song);
        } catch (e) {
          debugPrint('Erreur parsing ligne $i: $e');
          // Continuer avec les autres lignes
        }
      }

      return songs;
    } catch (e) {
      throw Exception('Erreur lors de l\'import CSV: $e');
    }
  }

  /// Importe les chants depuis un fichier TXT
  static Future<List<SongModel>> importFromTXT() async {
    try {
      // Sélectionner le fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Aucun fichier sélectionné');
      }

      String content;
      if (kIsWeb) {
        // Web
        content = String.fromCharCodes(result.files.first.bytes!);
      } else {
        // Mobile/Desktop
        File file = File(result.files.single.path!);
        content = await file.readAsString();
      }

      // Diviser le contenu par chants
      List<String> songTexts = content.split(_txtSeparator);
      List<SongModel> songs = [];

      for (String songText in songTexts) {
        if (songText.trim().isEmpty) continue;
        
        try {
          var song = _parseSongFromTXT(songText.trim());
          songs.add(song);
        } catch (e) {
          debugPrint('Erreur parsing chant: $e');
          // Continuer avec les autres chants
        }
      }

      return songs;
    } catch (e) {
      throw Exception('Erreur lors de l\'import TXT: $e');
    }
  }

  /// Sauvegarde un chant importé dans Firebase
  static Future<void> saveSong(SongModel song) async {
    try {
      final result = await SongsFirebaseService.createSong(song);
      if (result == null) {
        throw Exception('Échec de la création du chant');
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Sauvegarde plusieurs chants importés
  static Future<void> saveSongs(List<SongModel> songs) async {
    for (var song in songs) {
      await saveSong(song);
    }
  }

  /// Parse une ligne CSV en SongModel
  static SongModel _parseSongFromCSVRow(List<dynamic> row) {
    return SongModel(
      id: '', // Sera généré par Firebase
      title: row[0]?.toString() ?? '',
      authors: row[1]?.toString() ?? '',
      lyrics: _unsanitizeText(row[2]?.toString() ?? ''),
      originalKey: row[3]?.toString() ?? 'C',
      style: row[4]?.toString() ?? 'Adoration',
      tags: row[5]?.toString().split(';').where((t) => t.isNotEmpty).toList() ?? [],
      bibleReferences: row[6]?.toString().split(';').where((r) => r.isNotEmpty).toList() ?? [],
      tempo: int.tryParse(row[7]?.toString() ?? ''),
      audioUrl: row[8]?.toString().isEmpty == true ? null : row[8]?.toString(),
      attachmentUrls: [],
      status: row[9]?.toString() ?? 'draft',
      visibility: row[10]?.toString() ?? 'private',
      privateNotes: row[11]?.toString().isEmpty == true ? null : row[11]?.toString(),
      usageCount: int.tryParse(row[12]?.toString() ?? '0') ?? 0,
      lastUsedAt: row[13]?.toString().isEmpty == true ? null : DateTime.tryParse(row[13]?.toString() ?? ''),
      createdAt: DateTime.tryParse(row[14]?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: row[15]?.toString() ?? 'Import',
      metadata: _parseMetadata(row.length > 16 ? row[16]?.toString() : null),
    );
  }

  /// Parse un texte TXT en SongModel
  static SongModel _parseSongFromTXT(String songText) {
    Map<String, String> fields = {};
    String lyrics = '';
    
    List<String> lines = songText.split('\n');
    bool inLyrics = false;
    StringBuffer lyricsBuffer = StringBuffer();
    
    for (String line in lines) {
      if (line.startsWith('PAROLES:')) {
        inLyrics = true;
        continue;
      }
      
      if (inLyrics) {
        lyricsBuffer.writeln(line);
      } else {
        // Parser les champs
        if (line.contains(':')) {
          List<String> parts = line.split(':');
          if (parts.length >= 2) {
            String key = parts[0].trim();
            String value = parts.sublist(1).join(':').trim();
            fields[key] = value;
          }
        }
      }
    }
    
    lyrics = lyricsBuffer.toString().trim();
    
    return SongModel(
      id: '', // Sera généré par Firebase
      title: fields['TITRE'] ?? '',
      authors: fields['AUTEURS'] ?? '',
      lyrics: lyrics,
      originalKey: fields['TONALITÉ'] ?? 'C',
      style: fields['STYLE'] ?? 'Adoration',
      tags: fields['TAGS']?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [],
      bibleReferences: fields['RÉFÉRENCES']?.split(',').map((r) => r.trim()).where((r) => r.isNotEmpty).toList() ?? [],
      tempo: fields['TEMPO']?.contains('BPM') == true ? int.tryParse(fields['TEMPO']!.replaceAll('BPM', '').trim()) : null,
      audioUrl: null,
      attachmentUrls: [],
      status: fields['STATUT'] ?? 'draft',
      visibility: fields['VISIBILITÉ'] ?? 'private',
      privateNotes: fields['NOTES'],
      usageCount: int.tryParse(fields['UTILISATIONS'] ?? '0') ?? 0,
      lastUsedAt: null,
      createdAt: DateTime.tryParse(fields['DATE'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: fields['CRÉÉ PAR'] ?? 'Import',
      metadata: {},
    );
  }

  /// Nettoie le texte pour CSV (échapper les guillemets et retours de ligne)
  static String _sanitizeText(String text) {
    return text.replaceAll('"', '""').replaceAll('\n', '\\n');
  }

  /// Restaure le texte depuis CSV
  static String _unsanitizeText(String text) {
    return text.replaceAll('""', '"').replaceAll('\\n', '\n');
  }

  /// Parse les métadonnées JSON
  static Map<String, dynamic> _parseMetadata(String? metadataString) {
    if (metadataString == null || metadataString.isEmpty) {
      return {};
    }
    
    try {
      return jsonDecode(metadataString);
    } catch (e) {
      return {};
    }
  }

  /// Sauvegarde et partage un fichier
  static Future<void> _saveAndShare({
    required String content,
    required String filename,
    required String mimeType,
  }) async {
    try {
      if (kIsWeb) {
        // Sur le web, on utilise la fonctionnalité de téléchargement du navigateur
        // Ceci nécessiterait une implémentation spécifique au web
        throw UnimplementedError('Export web non encore implémenté');
      } else {
        // Sur mobile/desktop
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);
        
        // Partager le fichier
        await Share.shareXFiles([XFile(file.path)], text: 'Export des chants');
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }
}