import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ollama_service.dart';

class ControlPanelSettings {
  final String ollamaUrl;
  final String ollamaModel;
  final int xp;
  final int level;
  final int streakCount;
  final String lastActiveDate;

  const ControlPanelSettings({
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama3',
    this.xp = 0,
    this.level = 1,
    this.streakCount = 0,
    this.lastActiveDate = '',
  });

  ControlPanelSettings copyWith({
    String? ollamaUrl,
    String? ollamaModel,
    int? xp,
    int? level,
    int? streakCount,
    String? lastActiveDate,
  }) {
    return ControlPanelSettings(
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakCount: streakCount ?? this.streakCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

class ControlPanelNotifier extends Notifier<ControlPanelSettings> {
  static const _keyOllamaUrl = 'ollama_url';
  static const _keyOllamaModel = 'ollama_model';
  static const _keyXp = 'user_xp';
  static const _keyLevel = 'user_level';
  static const _keyStreak = 'user_streak';
  static const _keyLastActive = 'user_last_active';

  @override
  ControlPanelSettings build() {
    _loadSettings();
    return const ControlPanelSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ollamaUrl = prefs.getString(_keyOllamaUrl) ?? 'http://localhost:11434';
    final ollamaModel = prefs.getString(_keyOllamaModel) ?? 'llama3';
    final xp = prefs.getInt(_keyXp) ?? 0;
    final level = prefs.getInt(_keyLevel) ?? 1;
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final lastActive = prefs.getString(_keyLastActive) ?? '';

    state = ControlPanelSettings(
      ollamaUrl: ollamaUrl,
      ollamaModel: ollamaModel,
      xp: xp,
      level: level,
      streakCount: streak,
      lastActiveDate: lastActive,
    );

    updateStreak();

    ref.read(ollamaServiceProvider).configure(baseUrl: ollamaUrl, model: ollamaModel);
  }

  Future<void> setOllamaConfig({required String url, required String model}) async {
    final prefs = await SharedPreferences.getInstance();
    
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

  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = state.xp + amount;
    
    final newLevel = (newXp / 100).floor() + 1;
    
    await prefs.setInt(_keyXp, newXp);
    await prefs.setInt(_keyLevel, newLevel);
    
    state = state.copyWith(xp: newXp, level: newLevel);
  }

  Future<void> spendXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = (state.xp - amount).clamp(0, 1000000);
    
    final newLevel = (newXp / 100).floor() + 1;
    
    await prefs.setInt(_keyXp, newXp);
    await prefs.setInt(_keyLevel, newLevel);
    
    state = state.copyWith(xp: newXp, level: newLevel);
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    final lastActive = state.lastActiveDate;
    int streak = state.streakCount;
    
    if (lastActive == todayStr) {
      return;
    }
    
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    if (lastActive == yesterdayStr) {
      streak += 1;
    } else if (lastActive.isNotEmpty) {
      streak = 1;
    } else {
      streak = 1;
    }
    
    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastActive, todayStr);
    
    state = state.copyWith(streakCount: streak, lastActiveDate: todayStr);
  }
}

final controlPanelProvider =
    NotifierProvider<ControlPanelNotifier, ControlPanelSettings>(() => ControlPanelNotifier());


final ollamaServiceProvider = Provider((ref) {
  return OllamaService();
});
