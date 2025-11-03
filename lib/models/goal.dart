class Goal {
  final String id;
  final String name;
  final double totalCost;
  final double currentSavings;
  final double savingAmount;
  final String savingFrequency; // 'week' or 'month'
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.name,
    required this.totalCost,
    required this.currentSavings,
    required this.savingAmount,
    required this.savingFrequency,
    required this.createdAt,
  });

  double get amountNeeded => totalCost - currentSavings;

  int get periodsRequired => (amountNeeded / savingAmount).ceil();

  DateTime get targetDate {
    final now = DateTime.now();
    if (savingFrequency == 'week') {
      return now.add(Duration(days: periodsRequired * 7));
    } else {
      // Approximate month as 30 days
      return now.add(Duration(days: periodsRequired * 30));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalCost': totalCost,
      'currentSavings': currentSavings,
      'savingAmount': savingAmount,
      'savingFrequency': savingFrequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      totalCost: json['totalCost'],
      currentSavings: json['currentSavings'],
      savingAmount: json['savingAmount'],
      savingFrequency: json['savingFrequency'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
