import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/level_selection/view/level_selection_screen.dart';
import 'core/services/vocabulary_repository.dart';


void main() async {
  // Flutter motoru başlamadan asenkron (await) işlemleri yapabilmek için gerekli:
  WidgetsFlutterBinding.ensureInitialized();

  // Hive veritabanını başlat
  final vocabRepo = VocabularyRepository();
  await vocabRepo.init();

  runApp(
    ProviderScope(
      // Başlatılmış repository'i tüm uygulamaya enjekte ediyoruz
      overrides: [
        vocabularyRepositoryProvider.overrideWithValue(vocabRepo),
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
      home: const LevelSelectionScreen(),
    );
  }
}