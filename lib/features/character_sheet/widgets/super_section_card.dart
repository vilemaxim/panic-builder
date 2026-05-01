import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character.dart';

/// Locked placeholder until XP advancement unlocks a Super (patch).
class SuperSectionCard extends StatelessWidget {
  const SuperSectionCard({
    super.key,
    required this.character,
    required this.rules,
  });

  final Character character;
  final MergedRules rules;

  @override
  Widget build(BuildContext context) {
    final unlock = character.superUnlock;
    if (unlock != null) {
      final s = rules.superById(unlock.superId);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Super', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                s?.name ?? unlock.superId,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (unlock.customLabel != null && unlock.customLabel!.isNotEmpty)
                Text(
                  'Label: ${unlock.customLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Text(
                s?.description ?? 'No description in seed data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if ((s?.sourcePage ?? '').isNotEmpty)
                Text(
                  'Source: ${s?.sourceBook} p.${s?.sourcePage}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Super', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Reserved for advancement. Unlock with XP using the patch rules for Supers.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available supers in data: ${rules.supers.map((e) => e.name).join(', ')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
