import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../../features/game_board/domain/prompt_manager.dart';

// ─── Isolate'de çalışacak top-level fonksiyon ───────────────────────────────
String _runInference(Map<String, dynamic> params) {
  final modelPath  = params['modelPath']  as String;
  final prompt     = params['prompt']     as String;
  final libPath    = params['libPath']    as String?;

  if (libPath != null) {
    Llama.libraryPath = libPath;
    print('[AI] DLL yolu: $libPath');
  }

  print('[AI] Model yukleniyor: $modelPath');
  final modelParams = ModelParams();
  modelParams.nGpuLayers = 0; // VRAM 4GB - model 3.2GB: tasiyor, CPU'da calistir
  final llama = Llama(modelPath, modelParams: modelParams, verbose: true);
  print('[AI] Model yuklendi. Prompt gonderiliyor...');
  llama.setPrompt(prompt);
  print('[AI] Inference basladi, tokenlar uretiliyor...');

  final buffer = StringBuffer();
  int tokenCount = 0;
  while (true) {
    final (text, isDone, contextLimit) = llama.getNextWithStatus();
    buffer.write(text);
    tokenCount++;
    if (tokenCount % 10 == 0) print('[AI] $tokenCount token uretildi...');
    final full = buffer.toString();
    // Gemma bitis tokeni veya baglam doldu
    if (isDone || contextLimit) break;
    if (full.contains('<end_of_turn>') || full.contains('<|im_end|>')) break;
  }

  llama.dispose();
  return buffer.toString();
}
// ────────────────────────────────────────────────────────────────────────────

class AiService {
  String? _modelPath;
  String? _libPath;

  Future<void> initialize(String modelPath) async {
    _modelPath = modelPath;
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      _libPath = '$exeDir\\llama.dll';
    } else if (Platform.isAndroid) {
      _libPath = 'libllama.so';
    }
  }

  // GÜNCELLENEN KISIM: Argümanları GameNotifier ile uyumlu hale getirdik
  Future<List<Map<String, dynamic>>> generateWords(
      String level, int count, {Set<String> excludeWords = const {}}) async {
    
    if (_modelPath == null) throw Exception('Model yolu ayarlanmadı.');

    // PromptManager'dan dinamik olarak promptları çekiyoruz
    final systemPrompt = PromptManager.getSystemPrompt();
    final userPrompt = PromptManager.getPromptForLevel(level, count, excludeWords: excludeWords);

    // Gemma 4 E2B için <start_of_turn> / <end_of_turn> formatı
    final prompt =
        '<start_of_turn>user\n$systemPrompt\n\n$userPrompt<end_of_turn>\n'
        '<start_of_turn>model\n';

    // compute() → ayrı Isolate'de çalışır, UI donmaz, timeout yok
    final response = await compute(_runInference, {
      'modelPath': _modelPath!,
      'prompt': prompt,
      'libPath': _libPath,
    });

    return _parseJsonFromResponse(response);
  }

  List<Map<String, dynamic>> _parseJsonFromResponse(String response) {
    try {
      final regex = RegExp(r'\{[\s\S]*\}');
      final match = regex.firstMatch(response);
      if (match != null) {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map<String, dynamic> && decoded.containsKey('words')) {
          return (decoded['words'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('JSON Parse Hatası: $e\nYanıt: $response');
      return [];
    }
  }

  void dispose() {}
}