import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _initIfNeeded() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45); // Öğrenme için ideal, yorulmayan orta hız
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print("[TTS Service] Başlatma Hatası: $e");
    }
  }

  /// Verilen metni İngilizce olarak seslendirir.
  Future<void> speak(String text) async {
    await _initIfNeeded();
    try {
      await _flutterTts.stop(); // Önceki seslendirmeyi durdur
      await _flutterTts.speak(text);
    } catch (e) {
      // ignore: avoid_print
      print("[TTS Service] Seslendirme Hatası: $e");
    }
  }

  /// Seslendirmeyi durdurur.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // ignore: avoid_print
      print("[TTS Service] Durdurma Hatası: $e");
    }
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final ttsServiceProvider = Provider((ref) {
  return TtsService();
});
