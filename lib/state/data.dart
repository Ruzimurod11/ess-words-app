import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart' as api;
import '../models/book.dart';
import '../models/word.dart';

/// Data providers mirror the web app's TanStack Query keys. They are kept
/// alive (not autoDispose) so results cache across navigation; mutations call
/// `ref.invalidate(...)` to trigger a refetch, matching queryClient behavior.

final booksProvider = FutureProvider<List<Book>>((ref) => api.getBooks());

final bookProvider =
    FutureProvider.family<BookWithUnits, int>((ref, id) => api.getBook(id));

final vocabularyProvider =
    FutureProvider<BookWithUnits>((ref) => api.getVocabulary());

typedef UnitWordsArgs = ({int unitId, int page, int pageSize});

final unitWordsProvider =
    FutureProvider.family<PaginatedWords, UnitWordsArgs>(
  (ref, a) => api.getUnitWords(a.unitId, page: a.page, pageSize: a.pageSize),
);

typedef SearchArgs = ({String q, int page, int pageSize});

final searchProvider =
    FutureProvider.family<PaginatedSearchWords, SearchArgs>(
  (ref, a) => api.searchWords(a.q, page: a.page, pageSize: a.pageSize),
);

/// Invalidate everything touched by a word create/update/delete/reorder.
void invalidateWords(WidgetRef ref, int unitId) {
  ref.invalidate(booksProvider);
  ref.invalidate(bookProvider);
  ref.invalidate(vocabularyProvider);
  ref.invalidate(searchProvider);
  // unit-words for this unit (all page/size variants)
  ref.invalidate(unitWordsProvider);
}
