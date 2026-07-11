import '../models/quiz.dart';

const int kMinCount = 20;
const int kStreakCheerVariants = 16;
const int kStreakCheerMin = 3;

const Map<String, int> kCheerTierVariants = {
  'hot': 25,
  'good': 25,
  'mid': 25,
  'low': 25,
};

/// Case/whitespace-insensitive answer comparison (lib/quiz.ts isAnswerCorrect).
bool isAnswerCorrect(String selected, String correct) {
  String norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return norm(selected) == norm(correct);
}

bool isValidQuizCount(String raw, int? max) {
  final parsed = int.tryParse(raw.trim());
  return max != null &&
      parsed != null &&
      parsed >= kMinCount &&
      parsed <= max;
}

enum QuizFeedbackTier { perfect, excellent, great, good, average, low }

QuizFeedbackTier getQuizFeedbackTier(int percent) {
  if (percent >= 100) return QuizFeedbackTier.perfect;
  if (percent >= 95) return QuizFeedbackTier.excellent;
  if (percent >= 85) return QuizFeedbackTier.great;
  if (percent >= 70) return QuizFeedbackTier.good;
  if (percent >= 50) return QuizFeedbackTier.average;
  return QuizFeedbackTier.low;
}

String feedbackTierKey(QuizFeedbackTier t) => t.name;

String cheerTierKey(int percent) {
  if (percent >= 90) return 'hot';
  if (percent >= 70) return 'good';
  if (percent >= 50) return 'mid';
  return 'low';
}

class Answer {
  final QuizQuestion question;
  final String selected;
  const Answer(this.question, this.selected);
}

int getTrailingStreak(List<Answer> answers) {
  var streak = 0;
  for (var i = answers.length - 1; i >= 0; i--) {
    if (!isAnswerCorrect(answers[i].selected, answers[i].question.correct)) {
      break;
    }
    streak++;
  }
  return streak;
}

class QuizScore {
  final List<Answer> wrong;
  final int correctCount;
  final int percent;
  const QuizScore(this.wrong, this.correctCount, this.percent);
}

QuizScore scoreQuiz(List<Answer> answers) {
  final wrong = answers
      .where((a) => !isAnswerCorrect(a.selected, a.question.correct))
      .toList();
  final correctCount = answers.length - wrong.length;
  final percent = answers.isNotEmpty
      ? ((correctCount / answers.length) * 100).round()
      : 0;
  return QuizScore(wrong, correctCount, percent);
}

/// Cheer shown after each answer: a streak message when on a run, otherwise a
/// tier-appropriate phrase.
class Cheer {
  final bool isStreak;
  final int streak;
  final String tier;
  final int percent;
  const Cheer.streak(this.streak)
      : isStreak = true,
        tier = '',
        percent = 0;
  const Cheer.tier(this.tier, this.percent)
      : isStreak = false,
        streak = 0;
}

Cheer? getQuizCheer(List<Answer> answers) {
  if (answers.isEmpty) return null;
  final streak = getTrailingStreak(answers);
  if (streak >= kStreakCheerMin) return Cheer.streak(streak);
  final percent = scoreQuiz(answers).percent;
  return Cheer.tier(cheerTierKey(percent), percent);
}
