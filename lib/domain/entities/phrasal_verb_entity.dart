class PhrasalVerbEntity {
  final String verb;
  final String meaning;
  final List<String> examples;
  final String exerciseSentence;
  final String exerciseAnswer;

  const PhrasalVerbEntity({
    required this.verb,
    required this.meaning,
    required this.examples,
    required this.exerciseSentence,
    required this.exerciseAnswer,
  });

  factory PhrasalVerbEntity.fromJson(Map<String, dynamic> json) {
    return PhrasalVerbEntity(
      verb: json['verb'] ?? '',
      meaning: json['meaning'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      exerciseSentence: json['exerciseSentence'] ?? '',
      exerciseAnswer: json['exerciseAnswer'] ?? '',
    );
  }
}
