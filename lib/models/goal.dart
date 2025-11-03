class Goal {
  final String id;
  final String name;
  final double totalCost;
  final double currentSavings;
  final double savingAmount;
  final String savingFrequency; // 'week' or 'month'
  final DateTime createdAt;
  final DateTime? fixedTargetDate; // For "Calculate Savings" mode

  Goal({
    required this.id,
    required this.name,
    required this.totalCost,
    required this.currentSavings,
    required this.savingAmount,
    required this.savingFrequency,
    required this.createdAt,
    this.fixedTargetDate,
  });

  double get amountNeeded => totalCost - currentSavings;

  int get periodsRequired {
    // If there's a fixed target date, calculate periods based on days remaining
    if (fixedTargetDate != null) {
      final daysRemaining = fixedTargetDate!.difference(DateTime.now()).inDays;
      if (daysRemaining <= 0) return 0;

      // Calculate how many periods of savings are needed based on amount
      final periodsNeeded = (amountNeeded / savingAmount).ceil();

      // Also calculate periods based on time available
      final periodsAvailable = savingFrequency == 'week'
          ? (daysRemaining / 7)
                .floor() // Use floor to show realistic weeks
          : (daysRemaining / 30).floor();

      // Return the smaller of the two (either you reach the amount first, or time runs out)
      return periodsNeeded < periodsAvailable
          ? periodsNeeded
          : periodsAvailable;
    }

    // Otherwise, calculate based on saving amount
    return (amountNeeded / savingAmount).ceil();
  }

  // Get a human-readable display text for periods remaining
  String get periodsDisplayText {
    // If there's a fixed target date, show weeks/months and days
    if (fixedTargetDate != null) {
      final daysRemaining = fixedTargetDate!.difference(DateTime.now()).inDays;
      if (daysRemaining <= 0) return 'Due now';

      if (savingFrequency == 'week') {
        final weeks = daysRemaining ~/ 7;
        final days = daysRemaining % 7;

        if (weeks == 0) {
          return '$days ${days == 1 ? 'day' : 'days'}';
        } else if (days == 0) {
          return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
        } else {
          return '$weeks ${weeks == 1 ? 'week' : 'weeks'} and $days ${days == 1 ? 'day' : 'days'}';
        }
      } else {
        final months = daysRemaining ~/ 30;
        final days = daysRemaining % 30;

        if (months == 0) {
          return '$days ${days == 1 ? 'day' : 'days'}';
        } else if (days == 0) {
          return '$months ${months == 1 ? 'month' : 'months'}';
        } else {
          return '$months ${months == 1 ? 'month' : 'months'} and $days ${days == 1 ? 'day' : 'days'}';
        }
      }
    }

    // For Calculate Time mode, show simple periods
    return '$periodsRequired ${periodsRequired == 1 ? (savingFrequency == 'week' ? 'week' : 'month') : (savingFrequency == 'week' ? 'weeks' : 'months')}';
  }

  DateTime get targetDate {
    // If a fixed target date was set (from "Calculate Savings" mode), use it
    if (fixedTargetDate != null) {
      return fixedTargetDate!;
    }

    // Otherwise, calculate dynamically (for "Calculate Time" mode)
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
      'fixedTargetDate': fixedTargetDate?.toIso8601String(),
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
      fixedTargetDate: json['fixedTargetDate'] != null
          ? DateTime.parse(json['fixedTargetDate'])
          : null,
    );
  }
}
