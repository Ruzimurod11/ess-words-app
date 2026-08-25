import 'package:flutter/material.dart';

import '../../core/avatar_image.dart';
import '../theme.dart';

/// Shows the admin avatar, falling back to a person icon when there is none.
class AvatarView extends StatelessWidget {
  final String? dataUrl;
  final double size;
  final double radius;
  const AvatarView({
    super.key,
    required this.dataUrl,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bytes = decodeAvatar(dataUrl);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border),
      ),
      child: bytes == null
          ? Icon(Icons.person_outline, size: size * 0.5, color: c.mutedFg)
          : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}
