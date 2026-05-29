import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aienglish_cengel_bulmaca/features/crossword_arena/domain/lexicon_entity.dart';

final wordVaultManagerProvider = Provider<WordVaultManager>((ref) {
  throw UnimplementedError('Repository main.dart içinde başlatılmadı');
});

class WordVaultManager {
  static const String _boxName = 'vocabularyBox';
  static const String _customBoxName = 'customWordsBox';
  late Box<LexiconEntity> _box;
  late Box _customBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LexiconEntityAdapter()); // Az önce ürettiğimiz adaptör
    _box = await Hive.openBox<LexiconEntity>(_boxName);
    _customBox = await Hive.openBox(_customBoxName);

    // Eğer veritabanı tamamen boşsa (ilk kurulum), kullanıcıya hazır kelime paketi sunalım
    if (_customBox.isEmpty) {
      await _prepopulateDefaultWords();
    }
  }

  /// Uygulama ilk kez kurulduğunda çevrimdışı oynanabilirlik için 30 kelimelik hazır paket yükler
  Future<void> _prepopulateDefaultWords() async {
    final List<Map<String, String>> starterPack = [
      // A1 Seviyesi
      {'word': 'DOG', 'clue': 'Köpek', 'level': 'A1'},
      {'word': 'CAT', 'clue': 'Kedi', 'level': 'A1'},
      {'word': 'SUN', 'clue': 'Güneş', 'level': 'A1'},
      {'word': 'BOOK', 'clue': 'Kitap', 'level': 'A1'},
      {'word': 'RED', 'clue': 'Kırmızı', 'level': 'A1'},
      {'word': 'MILK', 'clue': 'Süt', 'level': 'A1'},
      {'word': 'TREE', 'clue': 'Ağaç', 'level': 'A1'},
      {'word': 'FISH', 'clue': 'Balık', 'level': 'A1'},
      {'word': 'HOME', 'clue': 'Ev', 'level': 'A1'},
      {'word': 'WATER', 'clue': 'Su', 'level': 'A1'},

      // A2 Seviyesi
      {'word': 'FAMILY', 'clue': 'Aile', 'level': 'A2'},
      {'word': 'SCHOOL', 'clue': 'Okul', 'level': 'A2'},
      {'word': 'YELLOW', 'clue': 'Sarı', 'level': 'A2'},
      {'word': 'FRIEND', 'clue': 'Arkadaş', 'level': 'A2'},
      {'word': 'DOCTOR', 'clue': 'Doktor', 'level': 'A2'},
      {'word': 'SUMMER', 'clue': 'Yaz mevsimi', 'level': 'A2'},
      {'word': 'WINTER', 'clue': 'Kış mevsimi', 'level': 'A2'},
      {'word': 'ANIMAL', 'clue': 'Hayvan', 'level': 'A2'},
      {'word': 'FLOWER', 'clue': 'Çiçek', 'level': 'A2'},
      {'word': 'STREET', 'clue': 'Sokak', 'level': 'A2'},

      // B1 Seviyesi
      {'word': 'JOURNEY', 'clue': 'Yolculuk', 'level': 'B1'},
      {'word': 'SCIENCE', 'clue': 'Bilim', 'level': 'B1'},
      {'word': 'WEATHER', 'clue': 'Hava durumu', 'level': 'B1'},
      {'word': 'LIBRARY', 'clue': 'Kütüphane', 'level': 'B1'},
      {'word': 'SOCIETY', 'clue': 'Toplum', 'level': 'B1'},
      {'word': 'HISTORY', 'clue': 'Tarih', 'level': 'B1'},
      {'word': 'COUNTRY', 'clue': 'Ülke', 'level': 'B1'},
      {'word': 'SUBJECT', 'clue': 'Konu / Ders', 'level': 'B1'},
      {'word': 'FREEDOM', 'clue': 'Özgürlük', 'level': 'B1'},
      {'word': 'SUCCESS', 'clue': 'Başarı', 'level': 'B1'},
    ];

    for (final item in starterPack) {
      await addCustomWord(item['word']!, item['clue']!, item['level']!);
    }
  }

  /// Yeni kelimeleri kaydet veya varsa başarı sayısını artır
  Future<void> saveWords(List<String> words, String level) async {
    for (final word in words) {
      final cleanWord = word.toUpperCase();
      final existingIndex = _box.values.toList().indexWhere((r) => r.word == cleanWord);

      if (existingIndex >= 0) {
        final existingRecord = _box.getAt(existingIndex)!;
        existingRecord.successCount += 1;
        existingRecord.save();
      } else {
        await _box.add(LexiconEntity(
          word: cleanWord,
          level: level,
          lastSeen: DateTime.now(),
          successCount: 1,
        ));
      }
    }
  }

  /// Belirli bir seviye için daha önce kullanılmış kelimelerin listesini getir
  Set<String> getLearnedWords(String level) {
    return _box.values
        .where((record) => record.level == level)
        .map((record) => record.word)
        .toSet();
  }

  /// Tüm kelimeleri veritabanından sıfırla
  Future<void> clearAllWords() async {
    await _box.clear();
  }

  /// Yeni bir özel kelime-ipucu çifti ekle
  Future<void> addCustomWord(String word, String clue, String level) async {
    final cleanWord = word.trim().toUpperCase();
    final cleanClue = clue.trim();
    
    // Aynı kelime zaten varsa güncelle
    final existingIndex = _customBox.values.toList().indexWhere(
        (item) => item is Map && item['word'] == cleanWord);
        
    final newMap = {
      'word': cleanWord,
      'clue': cleanClue,
      'level': level,
      'createdAt': DateTime.now().toIso8601String(),
      'repetitions': 0,
      'easeFactor': 2.5,
      'interval': 0,
      'nextReviewDate': DateTime.now().toIso8601String(),
    };
    
    if (existingIndex >= 0) {
      await _customBox.putAt(existingIndex, newMap);
    } else {
      await _customBox.add(newMap);
    }
  }

  /// Kelimeyi SuperMemo SM-2 algoritmasına göre günceller
  Future<void> updateWordSM2(String word, bool wasCorrect) async {
    final cleanWord = word.trim().toUpperCase();
    final index = _customBox.values.toList().indexWhere(
        (item) => item is Map && item['word'] == cleanWord);
        
    if (index >= 0) {
      final existing = Map<String, dynamic>.from(_customBox.getAt(index) as Map);
      
      int repetitions = existing['repetitions'] ?? 0;
      double easeFactor = (existing['easeFactor'] ?? 2.5) as double;
      int interval = existing['interval'] ?? 0;

      if (wasCorrect) {
        if (repetitions == 0) {
          interval = 1;
        } else if (repetitions == 1) {
          interval = 6;
        } else {
          interval = (interval * easeFactor).round();
        }
        repetitions += 1;
        easeFactor = easeFactor + 0.15; // Başarı durumunda kelime kolaylaşır
      } else {
        repetitions = 0;
        interval = 1; // Hata durumunda hemen bir sonraki gün tekrar gösterilir
        easeFactor = (easeFactor - 0.2).clamp(1.3, 3.0);
      }

      final nextReviewDate = DateTime.now().add(Duration(days: interval));
      
      existing['repetitions'] = repetitions;
      existing['easeFactor'] = easeFactor;
      existing['interval'] = interval;
      existing['nextReviewDate'] = nextReviewDate.toIso8601String();
      
      await _customBox.putAt(index, existing);
    }
  }

  /// Özel kelimeyi sil
  Future<void> deleteCustomWord(int index) async {
    await _customBox.deleteAt(index);
  }

  /// Kelime değerine göre özel kelime sil
  Future<void> deleteCustomWordByValue(String word) async {
    final cleanWord = word.trim().toUpperCase();
    final index = _customBox.values.toList().indexWhere(
        (item) => item is Map && item['word'] == cleanWord);
    if (index >= 0) {
      await _customBox.deleteAt(index);
    }
  }

  /// Belirli bir seviyedeki özel kelimeleri getir
  List<Map<String, dynamic>> getCustomWords(String level) {
    return _customBox.values
        .where((item) => item is Map && item['level'] == level)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Tüm özel kelimeleri indeksleriyle birlikte getir (Arayüz listelemesi için)
  List<({int index, Map<String, dynamic> data})> getAllCustomWords() {
    final list = <({int index, Map<String, dynamic> data})>[];
    final values = _customBox.values.toList();
    for (int i = 0; i < values.length; i++) {
      if (values[i] is Map) {
        list.add((
          index: i,
          data: Map<String, dynamic>.from(values[i] as Map),
        ));
      }
    }
    return list;
  }
}