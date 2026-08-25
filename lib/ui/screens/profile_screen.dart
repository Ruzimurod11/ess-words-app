import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../core/avatar_image.dart';
import '../../models/profile.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/avatar_view.dart';
import '../widgets/common.dart';
import '../widgets/loader.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(ref.tr('profile.title'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(ref.tr('profile.subtitle'),
            style: TextStyle(fontSize: 13, color: c.mutedFg)),
        const SizedBox(height: 16),
        if (!ref.watch(isAdminProvider))
          StateCard(child: Text(ref.tr('profile.admin_required')))
        else
          ref.watch(profileProvider).when(
                loading: () => const Loader(),
                error: (e, _) =>
                    StateCard(error: true, child: Text('$e')),
                data: (p) => _ProfileForm(initial: p),
              ),
      ],
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final Profile initial;
  const _ProfileForm({required this.initial});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.displayName ?? '');
  late String? _avatar = widget.initial.avatar;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > kMaxSourceBytes) {
      setState(() => _error = ref.trs('profile.image_too_large'));
      return;
    }
    // Decoding and re-encoding a photo is slow enough to jank the UI thread.
    final dataUrl = await compute(avatarDataUrl, bytes);
    if (!mounted) return;
    setState(() {
      _error = dataUrl == null ? ref.trs('profile.invalid_image') : null;
      if (dataUrl != null) _avatar = dataUrl;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await api.updateProfile({
        'displayName': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'avatar': _avatar,
      });
      // `ref` is dead once this form is disposed — leaving the screen
      // mid-save must not swallow the refresh the header avatar depends on.
      if (!mounted) return;
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.trs('profile.saved'))),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarView(dataUrl: _avatar, size: 96, radius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GhostButton(
                      onPressed: _saving ? null : _pickImage,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 16),
                        const SizedBox(width: 6),
                        Flexible(child: Text(ref.tr('profile.upload'))),
                      ]),
                    ),
                    if (_avatar != null) ...[
                      const SizedBox(height: 6),
                      DangerButton(
                        onPressed:
                            _saving ? null : () => setState(() => _avatar = null),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.delete_outline, size: 16),
                          const SizedBox(width: 6),
                          Flexible(child: Text(ref.tr('profile.remove_photo'))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(ref.tr('profile.image_hint'),
                        style: TextStyle(fontSize: 12, color: c.mutedFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(ref.tr('profile.display_name'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          AppTextField(
            controller: _name,
            hint: ref.tr('profile.display_name_placeholder'),
            maxLength: 60,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(fontSize: 13, color: c.destructive)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            onPressed: _saving ? null : _save,
            child:
                Text(_saving ? ref.tr('profile.saving') : ref.tr('profile.save')),
          ),
        ],
      ),
    );
  }
}
