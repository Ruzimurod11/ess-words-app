import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/loader.dart';

class BooksGrid extends ConsumerWidget {
  const BooksGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    return booksAsync.when(
      loading: () => const Loader(),
      error: (e, _) =>
          StateCard(error: true, child: Text('${ref.tr('common.error')}: $e')),
      data: (books) {
        final essential =
            books.where((b) => b.kind == BookKind.essential).toList();
        if (essential.isEmpty) {
          return StateCard(child: Text(ref.tr('home.empty')));
        }
        return LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : constraints.maxWidth > 380
                      ? 2
                      : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 168,
            ),
            itemCount: essential.length,
            itemBuilder: (context, i) => _BookCard(book: essential[i]),
          );
        });
      },
    );
  }
}

class _BookCard extends ConsumerWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final grad = bookGradient(book.order);
    return AppCard(
      onTap: () => context.go('/books/${book.id}'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${book.order}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Pill(ref.tr('book.unit_count', {'count': book.unitCount})),
            ],
          ),
          const SizedBox(height: 12),
          Text(book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(book.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.mutedFg)),
          ],
          const Spacer(),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(ref.tr('book.word_count', {'count': book.wordCount}),
                  style: TextStyle(fontSize: 12, color: c.mutedFg)),
              const Spacer(),
              Text(ref.tr('common.open'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.primary)),
              Icon(Icons.arrow_forward, size: 14, color: c.primary),
            ],
          ),
        ],
      ),
    );
  }
}
