import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/stage_picker/view/stage_picker_view.dart';
import 'core/services/word_vault_manager.dart';


void main() async {
  // Flutter motoru başlamadan asenkron (await) işlemleri yapabilmek için gerekli:
  WidgetsFlutterBinding.ensureInitialized();

  // Hive veritabanını başlat
  final vocabRepo = WordVaultManager();
  await vocabRepo.init();

  runApp(
    ProviderScope(
      // Başlatılmış repository'i tüm uygulamaya enjekte ediyoruz
      overrides: [
        wordVaultManagerProvider.overrideWithValue(vocabRepo),
      ],
      child: const AiEnglishCrosswordApp(),
    ),
  );
}

class AiEnglishCrosswordApp extends StatelessWidget {
  const AiEnglishCrosswordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI English Crossword',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StagePickerView(),
    );
  }
}