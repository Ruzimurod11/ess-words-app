import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';
import 'components/header_actions.dart';
import 'theme.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});

  int get _index {
    if (location.startsWith('/test')) return 1;
    if (location.startsWith('/search')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: kBrandGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ref.tr('app.name'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [
          TranscriptionBackfillButton(),
          SizedBox(width: 6),
          LanguageButton(),
          SizedBox(width: 6),
          ThemeToggleButton(),
          SizedBox(width: 6),
          AdminButton(),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: c.card,
        indicatorColor: c.primary.withValues(alpha: 0.15),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/test');
            case 2:
              context.go('/search');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: c.primary),
            label: ref.tr('home.title'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz, color: c.primary),
            label: ref.tr('test.button'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: c.primary),
            label: ref.tr('search.button'),
          ),
        ],
      ),
    );
  }
}
