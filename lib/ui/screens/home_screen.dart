import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../components/books_grid.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Hero(),
        const SizedBox(height: 24),
        Text(ref.tr('home.title'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const BooksGrid(),
        const SizedBox(height: 28),
        Divider(color: c.border),
        const SizedBox(height: 16),
        Text(ref.tr('vocab.title'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const _VocabularyCard(),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Hero extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('home.hero_title'),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(ref.tr('home.subtitle'),
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/test'),
            icon: const Icon(Icons.auto_awesome, size: 16),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF615FFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            label: Text(ref.tr('home.hero_cta'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _VocabularyCard extends ConsumerWidget {
  const _VocabularyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final books = ref.watch(booksProvider).valueOrNull ?? <Book>[];
    Book? vocab;
    for (final b in books) {
      if (b.kind == BookKind.vocabulary) {
        vocab = b;
        break;
      }
    }
    final wordCount = vocab?.wordCount ?? 0;
    return AppCard(
      onTap: () => context.go('/vocabulary'),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_library, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.tr('vocab.title'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(ref.tr('vocab.subtitle'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.mutedFg)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(ref.tr('book.word_count', {'count': wordCount}),
                  style: TextStyle(fontSize: 12, color: c.mutedFg)),
              const SizedBox(height: 4),
              Icon(Icons.arrow_forward, size: 16, color: c.primary),
            ],
          ),
        ],
      ),
    );
  }
}
