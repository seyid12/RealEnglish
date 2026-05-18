import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  // Gemma 2 2B (Gemma 4 E2B) Q4 GGUF Model Linki
  static const String _modelUrl = 'https://huggingface.co/lmstudio-community/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf';
  static const String _fileName = 'gemma-4-E2B-it-Q4_K_M.gguf';

  final Dio _dio = Dio();

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);
    return await file.exists();
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function() onCompleted,
    required Function(String) onError,
  }) async {
    try {
      final path = await getModelPath();
      
      if (await isModelDownloaded()) {
        onProgress(1.0);
        onCompleted();
        return;
      }

      await _dio.download(
        _modelUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      onCompleted();
    } catch (e) {
      onError('Model indirme hatası: $e');
    }
  }
}
