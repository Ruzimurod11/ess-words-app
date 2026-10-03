import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../widgets/common.dart';

/// Emerald "Closed" badge shown next to a finished unit.
class ClosedBadge extends ConsumerWidget {
  const ClosedBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6EE7B7)
        : const Color(0xFF047857);
    return Pill(
      ref.tr('book.unit_closed'),
      bg: const Color(0xFF10B981).withValues(alpha: 0.10),
      fg: fg,
    );
  }
}

/// Admin toggle that closes or reopens a unit (UnitCloseButton.tsx).
class UnitCloseButton extends ConsumerStatefulWidget {
  final int unitId;
  final bool closed;
  const UnitCloseButton({super.key, required this.unitId, required this.closed});

  @override
  ConsumerState<UnitCloseButton> createState() => _UnitCloseButtonState();
}

class _UnitCloseButtonState extends ConsumerState<UnitCloseButton> {
  bool _pending = false;

  Future<void> _toggle() async {
    setState(() => _pending = true);
    try {
      if (widget.closed) {
        await api.reopenUnit(widget.unitId);
      } else {
        await api.closeUnit(widget.unitId);
      }
      ref.invalidate(bookProvider);
      ref.invalidate(booksProvider);
      ref.invalidate(vocabularyProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ref.trs('common.error'))));
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _pending
        ? ref.tr('book.unit_status_pending')
        : ref.tr(widget.closed ? 'book.reopen_unit' : 'book.close_unit');
    return GhostButton(
      onPressed: _pending ? null : _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.closed ? Icons.lock_open : Icons.lock, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
