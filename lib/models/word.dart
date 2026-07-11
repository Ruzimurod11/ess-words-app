class Word {
  final int id;
  final int unitId;
  final int order;
  final String english;
  final String translation;
  final String? transcription;
  final String createdAt;
  final String updatedAt;

  const Word({
    required this.id,
    required this.unitId,
    required this.order,
    required this.english,
    required this.translation,
    required this.transcription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] as int,
        unitId: j['unitId'] as int,
        order: j['order'] as int,
        english: j['english'] as String,
        translation: j['translation'] as String,
        transcription: j['transcription'] as String?,
        createdAt: (j['createdAt'] ?? '') as String,
        updatedAt: (j['updatedAt'] ?? '') as String,
      );

  Word copyWith({int? order}) => Word(
        id: id,
        unitId: unitId,
        order: order ?? this.order,
        english: english,
        translation: translation,
        transcription: transcription,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class PaginatedWords {
  final List<Word> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedWords({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedWords.fromJson(Map<String, dynamic> j) => PaginatedWords(
        items: ((j['items'] ?? []) as List)
            .map((e) => Word.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] ?? 0) as int,
        page: (j['page'] ?? 1) as int,
        pageSize: (j['pageSize'] ?? 0) as int,
        totalPages: (j['totalPages'] ?? 1) as int,
      );
}

class SearchWord extends Word {
  final int bookId;
  final int bookOrder;
  final String bookTitle;
  final int unitOrder;
  final String unitTitle;

  const SearchWord({
    required super.id,
    required super.unitId,
    required super.order,
    required super.english,
    required super.translation,
    required super.transcription,
    required super.createdAt,
    required super.updatedAt,
    required this.bookId,
    required this.bookOrder,
    required this.bookTitle,
    required this.unitOrder,
    required this.unitTitle,
  });

  factory SearchWord.fromJson(Map<String, dynamic> j) => SearchWord(
        id: j['id'] as int,
        unitId: j['unitId'] as int,
        order: j['order'] as int,
        english: j['english'] as String,
        translation: j['translation'] as String,
        transcription: j['transcription'] as String?,
        createdAt: (j['createdAt'] ?? '') as String,
        updatedAt: (j['updatedAt'] ?? '') as String,
        bookId: j['bookId'] as int,
        bookOrder: j['bookOrder'] as int,
        bookTitle: (j['bookTitle'] ?? '') as String,
        unitOrder: j['unitOrder'] as int,
        unitTitle: (j['unitTitle'] ?? '') as String,
      );
}

class PaginatedSearchWords {
  final List<SearchWord> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedSearchWords({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedSearchWords.fromJson(Map<String, dynamic> j) =>
      PaginatedSearchWords(
        items: ((j['items'] ?? []) as List)
            .map((e) => SearchWord.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] ?? 0) as int,
        page: (j['page'] ?? 1) as int,
        pageSize: (j['pageSize'] ?? 0) as int,
        totalPages: (j['totalPages'] ?? 1) as int,
      );
}
