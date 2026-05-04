import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/skills_state.dart';
import '../character_skills_ui.dart';

/// Extra inputs for skills that declare [RuleSkill.playerNoteMaxChars] in rules data.
class SkillPlayerNotesSection extends StatelessWidget {
  const SkillPlayerNotesSection({
    super.key,
    required this.character,
    required this.rules,
    required this.policies,
    required this.skillsState,
    this.onSkillPlayerNote,
  });

  final Character character;
  final MergedRules rules;
  final CharacterPolicies policies;
  final SkillsState skillsState;

  /// Called with trimmed text (empty clears the stored note).
  final void Function(String skillId, String value)? onSkillPlayerNote;

  @override
  Widget build(BuildContext context) {
    final need = skillsRequiringPlayerNotes(rules, skillsState);
    if (need.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Skill details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 8),
          for (final sk in need)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkillPlayerNoteField(
                skill: sk,
                value: skillsState.skillPlayerNotes[sk.id] ?? '',
                errorText: policies.validateSkillPlayerNote(character, sk.id),
                readOnly: onSkillPlayerNote == null,
                onChanged: onSkillPlayerNote == null
                    ? null
                    : (v) => onSkillPlayerNote!(sk.id, v),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillPlayerNoteField extends StatefulWidget {
  const _SkillPlayerNoteField({
    required this.skill,
    required this.value,
    required this.readOnly,
    this.errorText,
    this.onChanged,
  });

  final RuleSkill skill;
  final String value;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<_SkillPlayerNoteField> createState() => _SkillPlayerNoteFieldState();
}

class _SkillPlayerNoteFieldState extends State<_SkillPlayerNoteField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SkillPlayerNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.skill.playerNoteMaxChars ?? 0;
    final label = widget.skill.name.trim().isEmpty
        ? widget.skill.id
        : widget.skill.name.trim();

    if (widget.readOnly) {
      final show = widget.value.trim().isNotEmpty ? widget.value.trim() : '—';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2418),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            show,
            style: TextStyle(
              fontSize: 15,
              height: 1.25,
              fontStyle: widget.value.trim().isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: const Color(0xFF2F2418),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F2418),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          maxLength: max > 0 ? max : null,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16, height: 1.2),
          decoration: InputDecoration(
            isDense: true,
            hintText: max > 0 ? 'Up to $max characters' : null,
            errorText: widget.errorText,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.85),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
