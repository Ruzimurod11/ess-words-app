import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../theme.dart';

/// Grid of numbered unit buttons (UnitTabs.tsx).
class UnitTabs extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: units.map((u) {
          final active = u.id == activeUnitId;
          return Tooltip(
            message: '${u.title} — ${u.wordCount}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(u.id),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : c.mutedFg,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
