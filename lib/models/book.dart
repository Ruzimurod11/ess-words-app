enum BookKind { essential, vocabulary }

BookKind bookKindFrom(String? v) =>
    v == 'vocabulary' ? BookKind.vocabulary : BookKind.essential;

class Book {
  final int id;
  final int order;
  final String title;
  final String? description;
  final BookKind kind;
  final int unitCount;
  final int wordCount;

  const Book({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.kind,
    required this.unitCount,
    required this.wordCount,
  });

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as int,
        order: j['order'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        kind: bookKindFrom(j['kind'] as String?),
        unitCount: (j['unitCount'] ?? 0) as int,
        wordCount: (j['wordCount'] ?? 0) as int,
      );
}

class UnitSummary {
  final int id;
  final int order;
  final String title;
  final int wordCount;

  const UnitSummary({
    required this.id,
    required this.order,
    required this.title,
    required this.wordCount,
  });

  factory UnitSummary.fromJson(Map<String, dynamic> j) => UnitSummary(
        id: j['id'] as int,
        order: j['order'] as int,
        title: j['title'] as String,
        wordCount: (j['wordCount'] ?? 0) as int,
      );
}

class BookWithUnits extends Book {
  final List<UnitSummary> units;

  const BookWithUnits({
    required super.id,
    required super.order,
    required super.title,
    required super.description,
    required super.kind,
    required super.unitCount,
    required super.wordCount,
    required this.units,
  });

  factory BookWithUnits.fromJson(Map<String, dynamic> j) => BookWithUnits(
        id: j['id'] as int,
        order: j['order'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        kind: bookKindFrom(j['kind'] as String?),
        unitCount: (j['unitCount'] ?? 0) as int,
        wordCount: (j['wordCount'] ?? 0) as int,
        units: ((j['units'] ?? []) as List)
            .map((e) => UnitSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
