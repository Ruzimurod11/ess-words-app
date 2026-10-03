import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../state/app_state.dart';
import '../theme.dart';

/// Grid of numbered unit buttons (UnitTabs.tsx).
class UnitTabs extends ConsumerWidget {
  final List<UnitSummary> units;
  final int? activeUnitId;
  final ValueChanged<int> onSelect;
  const UnitTabs({
    super.key,
    required this.units,
    required this.activeUnitId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final closedFg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6EE7B7)
        : const Color(0xFF047857);
    final closedBg = const Color(0xFF10B981).withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 4.0;
          const columns = 6;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: units.map((u) {
              final active = u.id == activeUnitId;
              return Tooltip(
                message: ref.tr(
                  u.closed ? 'book.unit_tab_closed' : 'book.unit_tab_title',
                  {'title': u.title, 'count': u.wordCount},
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelect(u.id),
                    child: Container(
                      width: itemWidth,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: !active && u.closed ? closedBg : null,
                        gradient: active
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: Text(
                        '${u.order}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : u.closed
                                  ? closedFg
                                  : c.mutedFg,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
