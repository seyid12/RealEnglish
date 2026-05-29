class PromptManager {
  static String getSystemPrompt() {
    return '''You are an expert English teacher. Your ONLY task is to generate English words and clues for a crossword puzzle.
You MUST respond with ONLY a valid JSON object. Do not include any markdown, explanations, or additional text.
The JSON must strictly follow this structure:
{
  "words": [
    {"word": "WORD", "clue": "Clue in Turkish"}
  ]
}''';
  }

  static String getPromptForLevel(String level, int wordCount,
      {Set<String> excludeWords = const {}, String? topic}) {
    String difficulty = '';
    switch (level) {
      case 'A1':
        difficulty =
            'Beginner (A1) level. Use very simple and common daily words (e.g., colors, animals, basic objects).';
        break;
      case 'A2':
        difficulty =
            'Elementary (A2) level. Use basic vocabulary (e.g., routines, common adjectives, simple verbs).';
        break;
      case 'B1':
        difficulty =
            'Intermediate (B1) level. Use moderately complex words (e.g., abstract nouns, phrasal verbs).';
        break;
      default:
        difficulty = 'Beginner (A1) level.';
    }

    // Konu/kategori kısıtı
    final topicClause = (topic != null && topic.trim().isNotEmpty)
        ? '\n\nIMPORTANT: All generated words MUST be related to the topic: "${topic.trim()}". Stay strictly within this topic.'
        : '';

    // Öğrenilmiş kelimeler varsa prompt'a ekle
    final exclusionClause = excludeWords.isNotEmpty
        ? '\n\nIMPORTANT: Do NOT include any of these already-learned words: ${excludeWords.join(", ")}. Generate completely different words.'
        : '';

    return '''Generate $wordCount English words suitable for $difficulty
Provide the clues in Turkish.$topicClause$exclusionClause

Example Output:
{
  "words": [
    {"word": "APPLE", "clue": "Kırmızı, yuvarlak bir meyve"},
    {"word": "DOG", "clue": "Havlayan evcil bir hayvan"}
  ]
}''';
  }
}
