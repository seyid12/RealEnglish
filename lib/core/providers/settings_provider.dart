import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/ollama_service.dart';
import '../services/gemma_local_service.dart';

enum AiBackend { geminiApi, ollamaApi, gemmaLocal }

class AppSettings {
  final AiBackend backend;
  final String geminiApiKey;
  final String ollamaUrl;
  final String ollamaModel;
  final String gemmaModelPath;
  final String gemmaBackend; // 'cpu', 'gpu', 'npu'
  final String gemmaStatus; // 'idle', 'loading', 'ready', 'error'
  final String? gemmaError;
  final int xp;
  final int level;
  final int streakCount;
  final String lastActiveDate;

  const AppSettings({
    this.backend = AiBackend.geminiApi,
    this.geminiApiKey = '',
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama3',
    this.gemmaModelPath = '',
    this.gemmaBackend = 'gpu',
    this.gemmaStatus = 'idle',
    this.gemmaError,
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
    String? gemmaModelPath,
    String? gemmaBackend,
    String? gemmaStatus,
    String? Function()? gemmaError,
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
      gemmaModelPath: gemmaModelPath ?? this.gemmaModelPath,
      gemmaBackend: gemmaBackend ?? this.gemmaBackend,
      gemmaStatus: gemmaStatus ?? this.gemmaStatus,
      gemmaError: gemmaError != null ? gemmaError() : this.gemmaError,
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
  static const _keyGemmaModelPath = 'gemma_model_path';
  static const _keyGemmaBackend = 'gemma_backend';
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
    
    // Eşleme:
    // 0 -> geminiApi
    // 1 -> ollamaApi
    // 2 -> gemmaLocal
    AiBackend backend;
    if (backendIndex == 1) {
      backend = AiBackend.ollamaApi;
    } else if (backendIndex == 2) {
      backend = AiBackend.gemmaLocal;
    } else {
      backend = AiBackend.geminiApi;
    }

    final apiKey = prefs.getString(_keyApiKey) ?? '';
    final ollamaUrl = prefs.getString(_keyOllamaUrl) ?? 'http://localhost:11434';
    final ollamaModel = prefs.getString(_keyOllamaModel) ?? 'llama3';
    final gemmaModelPath = prefs.getString(_keyGemmaModelPath) ?? '';
    final gemmaBackend = prefs.getString(_keyGemmaBackend) ?? 'gpu';
    final xp = prefs.getInt(_keyXp) ?? 0;
    final level = prefs.getInt(_keyLevel) ?? 1;
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final lastActive = prefs.getString(_keyLastActive) ?? '';

    state = AppSettings(
      backend: backend,
      geminiApiKey: apiKey,
      ollamaUrl: ollamaUrl,
      ollamaModel: ollamaModel,
      gemmaModelPath: gemmaModelPath,
      gemmaBackend: gemmaBackend,
      gemmaStatus: 'idle',
      gemmaError: null,
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
    
    // Eğer Gemma Local seçili ise ve model yolu mevcut ise servisi yapılandırabiliriz
    if (gemmaModelPath.isNotEmpty) {
      _initGemma(gemmaModelPath, gemmaBackend);
    }
  }

  Future<void> _initGemma(String path, String backend) async {
    state = state.copyWith(gemmaStatus: 'loading', gemmaError: () => null);
    try {
      await ref.read(gemmaLocalServiceProvider).configure(
        modelPath: path,
        backendType: backend,
      );
      state = state.copyWith(gemmaStatus: 'ready');
    } catch (e) {
      state = state.copyWith(gemmaStatus: 'error', gemmaError: () => e.toString());
    }
  }

  Future<void> setBackend(AiBackend backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBackend, backend.index);
    state = state.copyWith(backend: backend);
    if (backend == AiBackend.gemmaLocal && state.gemmaModelPath.isNotEmpty && state.gemmaStatus != 'ready') {
      _initGemma(state.gemmaModelPath, state.gemmaBackend);
    }
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
    state = state.copyWith(geminiApiKey: key);
    ref.read(geminiServiceProvider).configure(key);
  }

  Future<void> setGemmaModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGemmaModelPath, path);
    state = state.copyWith(gemmaModelPath: path);
    if (path.isNotEmpty) {
      await _initGemma(path, state.gemmaBackend);
    } else {
      state = state.copyWith(gemmaStatus: 'idle', gemmaError: () => null);
    }
  }

  Future<void> setGemmaBackend(String backendType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGemmaBackend, backendType);
    state = state.copyWith(gemmaBackend: backendType);
    if (state.gemmaModelPath.isNotEmpty) {
      await _initGemma(state.gemmaModelPath, backendType);
    }
  }

  Future<void> setOllamaConfig({required String url, required String model}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // URL'yi kaydetmeden önce otomatik temizle
    var cleanedUrl = url.trim();
    if (cleanedUrl.isNotEmpty) {
      if (!cleanedUrl.startsWith('http://') && !cleanedUrl.startsWith('https://')) {
        cleanedUrl = 'http://$cleanedUrl';
      }
      if (cleanedUrl.endsWith('/')) {
        cleanedUrl = cleanedUrl.substring(0, cleanedUrl.length - 1);
      }
      try {
        final uri = Uri.parse(cleanedUrl);
        var result = '${uri.scheme}://${uri.host}';
        if (uri.hasPort) {
          result += ':${uri.port}';
        }
        cleanedUrl = result;
      } catch (_) {}
    }

    await prefs.setString(_keyOllamaUrl, cleanedUrl);
    await prefs.setString(_keyOllamaModel, model);
    state = state.copyWith(ollamaUrl: cleanedUrl, ollamaModel: model);
    ref.read(ollamaServiceProvider).configure(baseUrl: cleanedUrl, model: model);
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

  /// XP düşer ve otomatik seviye (level) değişimini yönetir
  Future<void> spendXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = (state.xp - amount).clamp(0, 1000000);
    
    // Seviyeyi yeni XP'ye göre dinamik hesapla
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

final gemmaLocalServiceProvider = Provider((ref) {
  return GemmaLocalService();
});

