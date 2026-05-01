/// When the character unlocks a Super via XP (patch content).
class SuperUnlock {
  const SuperUnlock({required this.superId, this.customLabel});

  final String superId;
  final String? customLabel;

  Map<String, dynamic> toJson() => {
    'superId': superId,
    if (customLabel != null) 'customLabel': customLabel,
  };

  static SuperUnlock? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['superId'] as String?;
    if (id == null) return null;
    return SuperUnlock(
      superId: id,
      customLabel: json['customLabel'] as String?,
    );
  }
}
