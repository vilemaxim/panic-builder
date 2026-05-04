/// One of three stances: style + form + chosen display name.
class Stance {
  const Stance({
    required this.styleId,
    required this.formId,
    required this.formDisplayName,
    this.formChoiceId,
  });

  final String styleId;
  final String formId;

  /// Main form name or an alternate from the form definition.
  final String formDisplayName;

  /// Selected [RuleFormChoice.id] when the form defines [RuleForm.choices].
  final String? formChoiceId;

  Map<String, dynamic> toJson() => {
    'styleId': styleId,
    'formId': formId,
    'formDisplayName': formDisplayName,
    if (formChoiceId != null && formChoiceId!.trim().isNotEmpty)
      'formChoiceId': formChoiceId!.trim(),
  };

  static Stance fromJson(Map<String, dynamic> json) => Stance(
    styleId: json['styleId'] as String,
    formId: json['formId'] as String,
    formDisplayName: json['formDisplayName'] as String,
    formChoiceId: json['formChoiceId'] as String?,
  );

  Stance copyWith({
    String? styleId,
    String? formId,
    String? formDisplayName,
    String? formChoiceId,
    bool clearFormChoice = false,
  }) => Stance(
    styleId: styleId ?? this.styleId,
    formId: formId ?? this.formId,
    formDisplayName: formDisplayName ?? this.formDisplayName,
    formChoiceId: clearFormChoice ? null : (formChoiceId ?? this.formChoiceId),
  );
}
