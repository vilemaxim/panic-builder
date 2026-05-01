import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../app/providers.dart';
import 'character_pdf.dart';

class PrintCharacterScreen extends ConsumerWidget {
  const PrintCharacterScreen({super.key, required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChar = ref.watch(characterByIdProvider(characterId));
    final rulesAsync = ref.watch(mergedRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print character'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncChar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('Character not found.'));
          }
          return rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Rules: $e')),
            data: (rules) => PdfPreview(
              build: (format) => buildCharacterPdfBytes(c, rules),
              initialPageFormat: halfLetterLandscape,
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName:
                  '${c.characterName.isEmpty ? 'character' : c.characterName}.pdf',
            ),
          );
        },
      ),
    );
  }
}
