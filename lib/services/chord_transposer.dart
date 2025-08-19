/// Service de transposition d'accords musicaux
class ChordTransposer {
  // Cercle des quintes pour les transpositions
  static const List<String> _chromaticScale = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // Équivalences entre dièses et bémols
  static const Map<String, String> _enharmonicEquivalents = {
    'C#': 'Db',
    'D#': 'Eb',
    'F#': 'Gb',
    'G#': 'Ab',
    'A#': 'Bb',
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  /// Transpose les paroles d'un chant d'une tonalité à une autre
  static String transposeLyrics(String lyrics, String fromKey, String toKey) {
    if (fromKey == toKey) return lyrics;

    final semitones = _calculateSemitones(fromKey, toKey);
    if (semitones == 0) return lyrics;

    // Expression régulière pour trouver les accords
    final chordPattern = RegExp(r'\b([A-G][#b]?(?:m|maj|min|dim|aug|sus[24]?|add[0-9]|[0-9])*(?:\/[A-G][#b]?)?)\b');
    
    return lyrics.replaceAllMapped(chordPattern, (match) {
      final chord = match.group(1)!;
      return _transposeChord(chord, semitones);
    });
  }

  /// Calcule le nombre de demi-tons entre deux tonalités
  static int _calculateSemitones(String fromKey, String toKey) {
    final fromRoot = _extractRootNote(fromKey);
    final toRoot = _extractRootNote(toKey);
    
    final fromIndex = _getNoteIndex(fromRoot);
    final toIndex = _getNoteIndex(toRoot);
    
    int semitones = (toIndex - fromIndex) % 12;
    if (semitones < 0) semitones += 12;
    
    return semitones;
  }

  /// Extrait la note fondamentale d'une tonalité
  static String _extractRootNote(String key) {
    if (key.length >= 2 && (key[1] == '#' || key[1] == 'b')) {
      return key.substring(0, 2);
    }
    return key.substring(0, 1);
  }

  /// Obtient l'index d'une note in l'échelle chromatique
  static int _getNoteIndex(String note) {
    int index = _chromaticScale.indexOf(note);
    if (index == -1) {
      // Essayer l'équivalent enharmonique
      final equivalent = _enharmonicEquivalents[note];
      if (equivalent != null) {
        index = _chromaticScale.indexOf(equivalent);
      }
    }
    return index == -1 ? 0 : index;
  }

  /// Transpose un accord spécifique
  static String _transposeChord(String chord, int semitones) {
    if (semitones == 0) return chord;

    // Séparer la note fondamentale du reste de l'accord
    String rootNote = '';
    String chordSuffix = '';
    
    if (chord.length >= 2 && (chord[1] == '#' || chord[1] == 'b')) {
      rootNote = chord.substring(0, 2);
      chordSuffix = chord.substring(2);
    } else {
      rootNote = chord.substring(0, 1);
      chordSuffix = chord.substring(1);
    }

    // Transposer la note fondamentale
    final rootIndex = _getNoteIndex(rootNote);
    final newRootIndex = (rootIndex + semitones) % 12;
    final newRootNote = _chromaticScale[newRootIndex];

    // Gérer les accords avec basse (notation /bass)
    final slashIndex = chordSuffix.indexOf('/');
    if (slashIndex != -1) {
      final beforeSlash = chordSuffix.substring(0, slashIndex);
      final bassNote = chordSuffix.substring(slashIndex + 1);
      final transposedBass = _transposeNote(bassNote, semitones);
      return newRootNote + beforeSlash + '/' + transposedBass;
    }

    return newRootNote + chordSuffix;
  }

  /// Transpose une note seule
  static String _transposeNote(String note, int semitones) {
    final noteIndex = _getNoteIndex(note);
    final newNoteIndex = (noteIndex + semitones) % 12;
    return _chromaticScale[newNoteIndex];
  }

  /// Obtient la tonalité relative mineure d'une tonalité majeure
  static String getRelativeMinor(String majorKey) {
    final rootNote = _extractRootNote(majorKey);
    final rootIndex = _getNoteIndex(rootNote);
    final minorIndex = (rootIndex + 9) % 12; // -3 demi-tons = +9 dans le cycle
    return _chromaticScale[minorIndex] + 'm';
  }

  /// Obtient la tonalité relative majeure d'une tonalité mineure
  static String getRelativeMajor(String minorKey) {
    if (!minorKey.endsWith('m')) return minorKey;
    
    final rootNote = _extractRootNote(minorKey.substring(0, minorKey.length - 1));
    final rootIndex = _getNoteIndex(rootNote);
    final majorIndex = (rootIndex + 3) % 12; // +3 demi-tons
    return _chromaticScale[majorIndex];
  }

  /// Obtient toutes les tonalités disponibles pour la transposition
  static List<String> getAvailableKeys() {
    final keys = <String>[];
    
    // Ajouter les tonalités majeures
    for (final note in _chromaticScale) {
      keys.add(note);
    }
    
    // Ajouter les tonalités mineures
    for (final note in _chromaticScale) {
      keys.add(note + 'm');
    }
    
    return keys;
  }

  /// Détermine si une tonalité est majeure ou mineure
  static bool isMinorKey(String key) {
    return key.endsWith('m');
  }

  /// Obtient le nom complet d'une tonalité
  static String getKeyDisplayName(String key) {
    final isMinor = isMinorKey(key);
    final rootNote = isMinor ? key.substring(0, key.length - 1) : key;
    
    return rootNote + (isMinor ? ' mineur' : ' majeur');
  }

  /// Suggère des tonalités communes pour la transposition
  static List<String> getSuggestedKeys(String originalKey) {
    final suggested = <String>[];
    final isMinor = isMinorKey(originalKey);
    
    // Tonalités communes pour le chant
    final commonKeys = isMinor 
        ? ['Am', 'Dm', 'Em', 'Gm', 'Cm', 'Fm']
        : ['C', 'G', 'D', 'A', 'E', 'F', 'Bb', 'Eb'];
    
    // Ajouter les tonalités communes qui ne sont pas la tonalité originale
    for (final key in commonKeys) {
      if (key != originalKey) {
        suggested.add(key);
      }
    }
    
    // Ajouter la tonalité relative
    if (isMinor) {
      final relativeMajor = getRelativeMajor(originalKey);
      if (!suggested.contains(relativeMajor)) {
        suggested.add(relativeMajor);
      }
    } else {
      final relativeMinor = getRelativeMinor(originalKey);
      if (!suggested.contains(relativeMinor)) {
        suggested.add(relativeMinor);
      }
    }
    
    return suggested;
  }


}