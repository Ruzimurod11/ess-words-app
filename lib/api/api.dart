import '../core/api_client.dart';
import '../models/book.dart';
import '../models/quiz.dart';
import '../models/word.dart';

final _c = ApiClient.instance;

// ----- auth -----
Future<String> login(String password) => _c.post<String>(
      '/auth/login',
      (d) => (d as Map)['token'] as String,
      body: {'password': password},
    );

// ----- books -----
Future<List<Book>> getBooks() => _c.get<List<Book>>(
      '/books',
      (d) => (d as List)
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Future<BookWithUnits> getBook(int id) => _c.get<BookWithUnits>(
      '/books/$id',
      (d) => BookWithUnits.fromJson(d as Map<String, dynamic>),
    );

// ----- vocabulary -----
Future<BookWithUnits> getVocabulary() => _c.get<BookWithUnits>(
      '/vocabulary',
      (d) => BookWithUnits.fromJson(d as Map<String, dynamic>),
    );

class AddVocabularyResult {
  final Word word;
  final int unitId;
  final int unitOrder;
  const AddVocabularyResult(this.word, this.unitId, this.unitOrder);
}

Future<AddVocabularyResult> addVocabularyWord(Map<String, dynamic> data) =>
    _c.post<AddVocabularyResult>(
      '/vocabulary/words',
      (d) {
        final m = d as Map<String, dynamic>;
        final unit = m['unit'] as Map<String, dynamic>;
        return AddVocabularyResult(
          Word.fromJson(m['word'] as Map<String, dynamic>),
          unit['id'] as int,
          unit['order'] as int,
        );
      },
      body: data,
    );

// ----- words -----
Future<PaginatedWords> getUnitWords(int unitId,
        {int page = 1, int pageSize = 20}) =>
    _c.get<PaginatedWords>(
      '/units/$unitId/words',
      (d) => PaginatedWords.fromJson(d as Map<String, dynamic>),
      query: {'page': page, 'pageSize': pageSize},
    );

Future<Word> createUnitWord(int unitId, Map<String, dynamic> data) =>
    _c.post<Word>(
      '/units/$unitId/words',
      (d) => Word.fromJson(d as Map<String, dynamic>),
      body: data,
    );

Future<Word> updateWord(int id, Map<String, dynamic> data) => _c.put<Word>(
      '/words/$id',
      (d) => Word.fromJson(d as Map<String, dynamic>),
      body: data,
    );

Future<List<Word>> reorderUnitWords(int unitId, List<int> orderedIds) =>
    _c.put<List<Word>>(
      '/units/$unitId/words/order',
      (d) => (d as List)
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      body: {'orderedIds': orderedIds},
    );

Future<void> deleteWord(int id) =>
    _c.delete<void>('/words/$id', (_) {});

Future<PaginatedSearchWords> searchWords(String q,
        {int page = 1, int pageSize = 50}) =>
    _c.get<PaginatedSearchWords>(
      '/words/search',
      (d) => PaginatedSearchWords.fromJson(d as Map<String, dynamic>),
      query: {'q': q, 'page': page, 'pageSize': pageSize},
    );

Future<QuizResponse> getQuiz({
  int? unitId,
  int? fromUnitId,
  int? toUnitId,
  int? count,
  QuizDirection? direction,
  QuizLevel? level,
}) =>
    _c.get<QuizResponse>(
      '/words/quiz',
      (d) => QuizResponse.fromJson(d as Map<String, dynamic>),
      query: {
        'unitId': unitId,
        'fromUnitId': fromUnitId,
        'toUnitId': toUnitId,
        'count': count,
        'direction': direction?.value,
        'level': level?.value,
      },
    );

class BackfillResult {
  final int updated;
  final int remaining;
  const BackfillResult(this.updated, this.remaining);
}

Future<BackfillResult> backfillTranscriptions() => _c.post<BackfillResult>(
      '/words/backfill-transcriptions',
      (d) {
        final m = d as Map<String, dynamic>;
        return BackfillResult(
          (m['updated'] ?? 0) as int,
          (m['remaining'] ?? 0) as int,
        );
      },
    );
