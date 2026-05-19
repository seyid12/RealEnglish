import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/ollama_service.dart';

enum AiBackend { geminiApi, ollamaApi }

class AppSettings {
  final AiBackend backend;
  final String geminiApiKey;
  final String ollamaUrl;
  final String ollamaModel;
  final int xp;
  final int level;
  final int streakCount;
  final String lastActiveDate;

  const AppSettings({
    this.backend = AiBackend.geminiApi,
    this.geminiApiKey = '',
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama3',
    this.xp = 0,
    this.level = 1,
    this.streakCount = 0,
    this.lastActiveDate = '',
  });

  AppSettings copyWith({
    AiBackend? backend,
    String? geminiApiKey,
    String? ollamaUrl,
    String? ollamaModel,
    int? xp,
    int? level,
    int? streakCount,
    String? lastActiveDate,
  }) {
    return AppSettings(
      backend: backend ?? this.backend,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakCount: streakCount ?? this.streakCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _keyBackend = 'ai_backend';
  static const _keyApiKey = 'gemini_api_key';
  static const _keyOllamaUrl = 'ollama_url';
  static const _keyOllamaModel = 'ollama_model';
  static const _keyXp = 'user_xp';
  static const _keyLevel = 'user_level';
  static const _keyStreak = 'user_streak';
  static const _keyLastActive = 'user_last_active';

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final backendIndex = prefs.getInt(_keyBackend) ?? 0;
    
    // Eski indeksleri koruyarak eşleme yapıyoruz:
    // Eski localGemma (0) veya geminiApi (1) -> geminiApi (yeni 0)
    // Eski ollamaApi (2) -> ollamaApi (yeni 1)
    final backend = (backendIndex == 2) ? AiBackend.ollamaApi : AiBackend.geminiApi;

    final apiKey = prefs.getString(_keyApiKey) ?? '';
    final ollamaUrl = prefs.getString(_keyOllamaUrl) ?? 'http://localhost:11434';
    final ollamaModel = prefs.getString(_keyOllamaModel) ?? 'llama3';
    final xp = prefs.getInt(_keyXp) ?? 0;
    final level = prefs.getInt(_keyLevel) ?? 1;
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final lastActive = prefs.getString(_keyLastActive) ?? '';

    state = AppSettings(
      backend: backend,
      geminiApiKey: apiKey,
      ollamaUrl: ollamaUrl,
      ollamaModel: ollamaModel,
      xp: xp,
      level: level,
      streakCount: streak,
      lastActiveDate: lastActive,
    );

    // Uygulama her açıldığında Streak'i otomatik olarak güncelle
    updateStreak();

    // Servisleri başlat
    if (apiKey.isNotEmpty) ref.read(geminiServiceProvider).configure(apiKey);
    ref.read(ollamaServiceProvider).configure(baseUrl: ollamaUrl, model: ollamaModel);
  }

  Future<void> setBackend(AiBackend backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBackend, backend.index);
    state = state.copyWith(backend: backend);
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
    state = state.copyWith(geminiApiKey: key);
    ref.read(geminiServiceProvider).configure(key);
  }

  Future<void> setOllamaConfig({required String url, required String model}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOllamaUrl, url);
    await prefs.setString(_keyOllamaModel, model);
    state = state.copyWith(ollamaUrl: url, ollamaModel: model);
    ref.read(ollamaServiceProvider).configure(baseUrl: url, model: model);
  }

  /// XP ekler ve otomatik seviye (level) atlamasını yönetir
  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = state.xp + amount;
    
    // Her 100 XP'de 1 Seviye atlanır (Level 1: 0-99 XP, Level 2: 100-199 XP...)
    final newLevel = (newXp / 100).floor() + 1;
    
    await prefs.setInt(_keyXp, newXp);
    await prefs.setInt(_keyLevel, newLevel);
    
    state = state.copyWith(xp: newXp, level: newLevel);
  }

  /// Günlük giriş serisini (Streak) günceller
  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    final lastActive = state.lastActiveDate;
    int streak = state.streakCount;
    
    if (lastActive == todayStr) {
      // Bugün zaten giriş yapılmış
      return;
    }
    
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    if (lastActive == yesterdayStr) {
      // Dün girilmiş, ardışık giriş devam ediyor
      streak += 1;
    } else if (lastActive.isNotEmpty) {
      // Gün atlanmış, seri 1'e sıfırlanır
      streak = 1;
    } else {
      // İlk defa aktif oluyor
      streak = 1;
    }
    
    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastActive, todayStr);
    
    state = state.copyWith(streakCount: streak, lastActiveDate: todayStr);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(() => SettingsNotifier());

final geminiServiceProvider = Provider((ref) {
  return GeminiService();
});

final ollamaServiceProvider = Provider((ref) {
  return OllamaService();
});

