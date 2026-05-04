import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/character.dart';
import '../../widgets/app_async_feedback.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(charactersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final narrow = MediaQuery.sizeOf(context).width < 420;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Panic at the Dojo',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: narrow ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2F2418),
                  ),
                ),
                Text(
                  'Character Builder · 1st Edition',
                  style: TextStyle(
                    fontSize: narrow ? 11.5 : 13,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF2F2418),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: listAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: AppAsyncLoading(message: 'Loading characters…'),
            ),
            error: (e, _) => AppAsyncError(
              error: e,
              title: 'Could not load saved characters',
            ),
            data: (characters) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEC),
                      border: Border.all(
                        color: const Color(0xFF3B2B1E),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Choose your path: forge a new hero, or call back one from your records.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a new hero, import JSON you saved before, or open a character stored on this device.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(creationSessionProvider.notifier).reset();
                      context.go('/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create new character'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _importJson(context, ref),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload character JSON'),
                  ),
                  if (characters.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'On this device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...characters.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            c.characterName.isEmpty
                                ? 'Unnamed character'
                                : c.characterName,
                          ),
                          subtitle: Text(
                            '${c.heroType?.name ?? 'in progress'} · updated ${_fmt(c.updatedAt)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/character/${c.id}'),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file bytes.')),
      );
      return;
    }
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final c = Character.fromJson(map);
      await ref.read(characterStorageProvider).upsert(c);
      ref.invalidate(charactersListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Character imported.')));
      context.go('/character/${c.id}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid JSON: $e')));
    }
  }
}
