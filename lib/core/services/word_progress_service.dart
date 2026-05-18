import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının kelime ilerlemesini kaydeden servis.
/// Her seviye için öğrenilmiş kelimeleri SharedPreferences'ta tutar.
class WordProgressService {
  static const _prefix = 'learned_';

  /// Bir seviyedeki tüm öğrenilmiş kelimeleri getir
  Future<Set<String>> getLearnedWords(String level) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_prefix$level') ?? [];
    return list.toSet();
  }

  /// Doğru tamamlanan kelimeleri "öğrenildi" olarak işaretle
  Future<void> markAsLearned(String level, List<String> words) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('$_prefix$level') ?? [];
    final updated = {...existing, ...words.map((w) => w.toUpperCase())}.toList();
    await prefs.setStringList('$_prefix$level', updated);
  }

  /// Bir seviyedeki tüm ilerlemeyi sıfırla
  Future<void> resetLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$level');
  }

  /// Tüm ilerlemeyi sıfırla
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Kaç kelime öğrenildi (istatistik için)
  Future<int> getLearnedCount(String level) async {
    final learned = await getLearnedWords(level);
    return learned.length;
  }
}
