import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import 'add_goal.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, this.userName = 'User'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('goals') ?? [];

    setState(() {
      _goals = goalsJson
          .map((json) => Goal.fromJson(jsonDecode(json)))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = _goals.map((goal) => jsonEncode(goal.toJson())).toList();
    await prefs.setStringList('goals', goalsJson);
  }

  Future<void> _addGoal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );

    if (result != null && result is Goal) {
      setState(() {
        _goals.add(result);
      });
      await _saveGoals();
    }
  }

  Future<void> _deleteGoal(int index) async {
    setState(() {
      _goals.removeAt(index);
    });
    await _saveGoals();
  }

  Future<void> _updateGoalProgress(int index) async {
    final goal = _goals[index];
    final controller = TextEditingController(
      text: goal.currentSavings.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Update Progress',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'How much have you saved so far?',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value >= 0) {
                  Navigator.pop(context, value);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final oldSavings = goal.currentSavings;
      final newSavings = result;

      setState(() {
        _goals[index] = Goal(
          id: goal.id,
          name: goal.name,
          totalCost: goal.totalCost,
          currentSavings: newSavings,
          savingAmount: goal.savingAmount,
          savingFrequency: goal.savingFrequency,
          createdAt: goal.createdAt,
        );
      });
      await _saveGoals();

      // Show success message with recalculation
      if (mounted) {
        final updatedGoal = _goals[index];
        final numberFormat = NumberFormat.currency(
          locale: 'en_PH',
          symbol: '₱',
          decimalDigits: 0,
        );

        String message;
        if (newSavings >= goal.totalCost) {
          message = '🎉 Congratulations! You\'ve reached your goal!';
        } else if (newSavings > oldSavings) {
          message =
              'Great! You now have only ${updatedGoal.periodsRequired} ${updatedGoal.savingFrequency == 'week' ? 'weeks' : 'months'} left!';
        } else {
          message = 'Progress updated to ${numberFormat.format(newSavings)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.userName}!',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Let\'s save for your dreams!',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Add Goal Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _addGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.circlePlus, size: 24),
                      SizedBox(width: 8.w),
                      Text(
                        'Add a Goal',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Goals List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _goals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        return _buildGoalCard(_goals[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.piggyBank, size: 80.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            'No goals yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your first savings goal to get started!',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, int index) {
    final numberFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );
    final progress = goal.currentSavings / goal.totalCost;

    // Calculate milestones
    final milestone25 = goal.totalCost * 0.25;
    final milestone50 = goal.totalCost * 0.50;
    final milestone75 = goal.totalCost * 0.75;

    final reached25 = goal.currentSavings >= milestone25;
    final reached50 = goal.currentSavings >= milestone50;
    final reached75 = goal.currentSavings >= milestone75;

    // Determine next milestone
    String? nextMilestoneText;
    double? nextMilestoneAmount;

    if (!reached25) {
      nextMilestoneText = '25% Milestone';
      nextMilestoneAmount = milestone25 - goal.currentSavings;
    } else if (!reached50) {
      nextMilestoneText = '50% Milestone';
      nextMilestoneAmount = milestone50 - goal.currentSavings;
    } else if (!reached75) {
      nextMilestoneText = '75% Milestone';
      nextMilestoneAmount = milestone75 - goal.currentSavings;
    } else if (goal.currentSavings < goal.totalCost) {
      nextMilestoneText = 'Goal Complete';
      nextMilestoneAmount = goal.totalCost - goal.currentSavings;
    }

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Are you sure you want to delete "${goal.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteGoal(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${goal.periodsRequired} ${goal.savingFrequency == 'week' ? 'weeks' : 'months'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8.h,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              ),
            ),

            SizedBox(height: 12.h),

            // Progress Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${numberFormat.format(goal.currentSavings)} / ${numberFormat.format(goal.totalCost)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Details
            Divider(color: Colors.grey.shade200),
            SizedBox(height: 8.h),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Saving',
                    '${numberFormat.format(goal.savingAmount)}/\n${goal.savingFrequency}',
                  ),
                ),
                Container(width: 1, height: 40.h, color: Colors.grey.shade200),
                Expanded(
                  child: _buildDetailItem(
                    'Target',
                    DateFormat('MMM dd,\nyyyy').format(goal.targetDate),
                  ),
                ),
                Container(width: 1, height: 40.h, color: Colors.grey.shade200),
                Expanded(
                  child: _buildDetailItem(
                    'Still need',
                    '${numberFormat.format(goal.amountNeeded)}',
                  ),
                ),
              ],
            ),

            // Milestones Section
            if (progress < 1.0) ...[
              SizedBox(height: 16.h),
              Divider(color: Colors.grey.shade200),
              SizedBox(height: 12.h),

              // Milestones Header
              Row(
                children: [
                  Icon(
                    LucideIcons.target,
                    size: 16.sp,
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Milestones',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Milestone Progress Indicators
              Row(
                children: [
                  _buildMilestoneIndicator('25%', reached25),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      height: 2.h,
                      color: reached25
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildMilestoneIndicator('50%', reached50),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      height: 2.h,
                      color: reached50
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildMilestoneIndicator('75%', reached75),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      height: 2.h,
                      color: reached75
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildMilestoneIndicator('100%', progress >= 1.0),
                ],
              ),

              if (nextMilestoneText != null && nextMilestoneAmount != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trophy,
                        size: 20.sp,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next: $nextMilestoneText',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${numberFormat.format(nextMilestoneAmount)} away!',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getMilestoneMessage(progress),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Update Progress Button
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: () => _updateGoalProgress(index),
                icon: const Icon(LucideIcons.refreshCw, size: 20),
                label: Text(
                  'Update Progress',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneIndicator(String label, bool reached) {
    return Column(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: reached ? Colors.blue.shade600 : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: reached ? Colors.blue.shade700 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: reached
                ? Icon(LucideIcons.check, size: 16.sp, color: Colors.white)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _getMilestoneMessage(double progress) {
    if (progress < 0.25) {
      return 'Getting started! 💪';
    } else if (progress < 0.50) {
      return 'Keep going! 🔥';
    } else if (progress < 0.75) {
      return 'Halfway there! 🎉';
    } else if (progress < 1.0) {
      return 'Almost there! 🚀';
    } else {
      return 'Goal reached! 🎯';
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
