enum QuizDirection { uzEn, enUz }

extension QuizDirectionX on QuizDirection {
  String get value => this == QuizDirection.uzEn ? 'uz-en' : 'en-uz';
}

enum QuizLevel { easy, hard }

extension QuizLevelX on QuizLevel {
  String get value => this == QuizLevel.easy ? 'easy' : 'hard';
}

QuizLevel quizLevelFrom(String? v) =>
    v == 'hard' ? QuizLevel.hard : QuizLevel.easy;

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String correct;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as int,
        question: j['question'] as String,
        options: ((j['options'] ?? []) as List).map((e) => e as String).toList(),
        correct: j['correct'] as String,
      );
}

class QuizResponse {
  final List<QuizQuestion> questions;
  // lowercase english word -> IPA transcription
  final Map<String, String> transcriptions;

  const QuizResponse({required this.questions, required this.transcriptions});

  factory QuizResponse.fromJson(Map<String, dynamic> j) => QuizResponse(
        questions: ((j['questions'] ?? []) as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        transcriptions:
            ((j['transcriptions'] ?? <String, dynamic>{}) as Map).map(
          (k, v) => MapEntry(k as String, v as String),
        ),
      );
}
