import 'package:hive/hive.dart';

part 'lexicon_entity.g.dart'; // Build runner bu dosyayı üretecek

@HiveType(typeId: 0)
class LexiconEntity extends HiveObject {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String level; // 'A1', 'A2', 'B1'

  @HiveField(2)
  final DateTime lastSeen;

  @HiveField(3)
  int successCount; // Kelimeyi kaç kere doğru bildi

  LexiconEntity({
    required this.word,
    required this.level,
    required this.lastSeen,
    this.successCount = 0,
  });
}