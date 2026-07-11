import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/loader.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchScreen({super.key, required this.query});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  String _query = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchScreen old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query && widget.query != _query) {
      _query = widget.query;
      _controller.text = widget.query;
      _page = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String v) {
    final t = v.trim();
    setState(() {
      _query = t;
      _page = 1;
    });
    context.go('/search?q=${Uri.encodeQueryComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(ref.tr('search.page_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(ref.tr('search.page_subtitle'),
            style: TextStyle(fontSize: 13, color: c.mutedFg)),
        const SizedBox(height: 16),
        AppTextField(
          controller: _controller,
          hint: ref.tr('search.placeholder'),
          keyboardType: TextInputType.text,
          onSubmitted: _submit,
          suffix: IconButton(
            icon: Icon(Icons.search, color: c.primary),
            onPressed: () => _submit(_controller.text),
          ),
        ),
        const SizedBox(height: 16),
        _results(c),
      ],
    );
  }

  Widget _results(AppColors c) {
    if (_query.isEmpty) {
      return StateCard(child: Text(ref.tr('search.empty_query')));
    }
    final async = ref.watch(
        searchProvider((q: _query, page: _page, pageSize: 50)));
    return async.when(
      loading: () => Loader(label: ref.tr('search.searching')),
      error: (e, _) =>
          StateCard(error: true, child: Text('${ref.tr('common.error')}: $e')),
      data: (data) {
        if (data.items.isEmpty) {
          return StateCard(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: ref.tr('search.no_results_prefix')),
              TextSpan(
                  text: ' "$_query"',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: c.foreground)),
              TextSpan(text: ref.tr('search.no_results_suffix')),
            ])),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '${ref.tr('search.results_found', {'count': data.total})} ',
                  style: TextStyle(fontSize: 13, color: c.mutedFg)),
              TextSpan(
                  text: '"$_query"',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.foreground)),
            ])),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < data.items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.border),
                    _SearchRow(item: data.items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${ref.tr('common.page')} $_page ${ref.tr('common.of')} ${data.totalPages}',
                    style: TextStyle(fontSize: 13, color: c.mutedFg)),
                Row(children: [
                  GhostButton(
                    onPressed: _page <= 1
                        ? null
                        : () => setState(() => _page -= 1),
                    child: Text(ref.tr('common.previous')),
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() => _page += 1),
                    child: Text(ref.tr('common.next')),
                  ),
                ]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SearchRow extends ConsumerWidget {
  final dynamic item;
  const _SearchRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(ref.tr('search.location_badge',
                    {'book': item.bookOrder, 'unit': item.unitOrder})),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(item.english,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500)),
                    ),
                    if (item.transcription != null &&
                        (item.transcription as String).isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('[${item.transcription}]',
                          style: TextStyle(fontSize: 15, color: c.mutedFg)),
                    ],
                  ],
                ),
                Text(item.translation, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                context.go('/books/${item.bookId}?unit=${item.unitId}'),
            child: Text(ref.tr('common.open'),
                style: TextStyle(
                    color: c.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
