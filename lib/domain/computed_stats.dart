/// Derived combat/sheet numbers from rules + selections.
class ComputedStats {
  const ComputedStats({
    required this.maxHp,
    required this.hpBars,
    required this.totalBars,
  });

  final int maxHp;
  final int hpBars;
  final int totalBars;

  Map<String, dynamic> toJson() => {
    'maxHp': maxHp,
    'hpBars': hpBars,
    'totalBars': totalBars,
  };

  static ComputedStats fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ComputedStats(maxHp: 0, hpBars: 0, totalBars: 0);
    }
    return ComputedStats(
      maxHp: json['maxHp'] as int? ?? 0,
      hpBars: json['hpBars'] as int? ?? 0,
      totalBars: json['totalBars'] as int? ?? 0,
    );
  }
}
