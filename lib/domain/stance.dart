/// One of three stances: style + form + chosen display name.
class Stance {
  const Stance({
    required this.styleId,
    required this.formId,
    required this.formDisplayName,
  });

  final String styleId;
  final String formId;

  /// Main form name or an alternate from the form definition.
  final String formDisplayName;

  Map<String, dynamic> toJson() => {
    'styleId': styleId,
    'formId': formId,
    'formDisplayName': formDisplayName,
  };

  static Stance fromJson(Map<String, dynamic> json) => Stance(
    styleId: json['styleId'] as String,
    formId: json['formId'] as String,
    formDisplayName: json['formDisplayName'] as String,
  );

  Stance copyWith({String? styleId, String? formId, String? formDisplayName}) =>
      Stance(
        styleId: styleId ?? this.styleId,
        formId: formId ?? this.formId,
        formDisplayName: formDisplayName ?? this.formDisplayName,
      );
}
