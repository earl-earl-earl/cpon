import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => InsightsScreenState();
}

class InsightsScreenState extends State<InsightsScreen> {
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

  // Public method to reload goals
  void reloadGoals() {
    _loadGoals();
  }

  // Calculate statistics
  double get _totalGoalAmount {
    return _goals.fold(0, (sum, goal) => sum + goal.totalCost);
  }

  double get _totalSaved {
    return _goals.fold(0, (sum, goal) => sum + goal.currentSavings);
  }

  double get _totalRemaining {
    return _goals.fold(0, (sum, goal) => sum + goal.amountNeeded);
  }

  double get _totalWeeklySavings {
    return _goals.fold(0, (sum, goal) {
      if (goal.savingFrequency == 'week') {
        return sum + goal.savingAmount;
      } else {
        return sum + (goal.savingAmount / 4);
      }
    });
  }

  double get _overallProgress {
    if (_totalGoalAmount == 0) return 0;
    return _totalSaved / _totalGoalAmount;
  }

  Goal? get _closestGoal {
    if (_goals.isEmpty) return null;
    // Filter out completed goals
    final incompleteGoals = _goals
        .where((goal) => goal.currentSavings < goal.totalCost)
        .toList();
    if (incompleteGoals.isEmpty) return null;
    return incompleteGoals.reduce(
      (a, b) => a.periodsRequired < b.periodsRequired ? a : b,
    );
  }

  Goal? get _biggestGoal {
    if (_goals.isEmpty) return null;
    return _goals.reduce((a, b) => a.totalCost > b.totalCost ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 100.h,
        automaticallyImplyLeading: false,
        flexibleSpace: Stack(
          children: [
            // Decorative circles in AppBar background
            Positioned(
              top: -50.h,
              left: -60.w,
              child: Container(
                width: 150.w,
                height: 150.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              top: -30.h,
              left: -90.w,
              child: Container(
                width: 140.w,
                height: 140.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondaryContainer.withOpacity(0.15),
                ),
              ),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Insights',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Track your savings journey',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  // Decorative background circles - Bottom Right
                  Positioned(
                    bottom: -100.h,
                    right: -80.w,
                    child: Container(
                      width: 300.w,
                      height: 300.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50.h,
                    right: -150.w,
                    child: Container(
                      width: 280.w,
                      height: 280.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.secondaryContainer.withOpacity(0.12),
                      ),
                    ),
                  ),

                  // Main content
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.r),
                        topRight: Radius.circular(24.r),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_goals.isEmpty) ...[
                              // Empty state
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32.w,
                                    vertical: 80.h,
                                  ),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/shasha_sad.png',
                                        height: 220.h,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: 24.h),
                                      Text(
                                        'No insights yet',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'Add a goal to see your savings progress and insights!',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Overview Section
                              Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Overall Progress Card
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade200,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.target,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Overall Progress',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${(_overallProgress * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 48.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                          ),
                                          child: Text(
                                            'Complete',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: LinearProgressIndicator(
                                        value: _overallProgress.clamp(0.0, 1.0),
                                        minHeight: 8.h,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          numberFormat.format(_totalSaved),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          numberFormat.format(_totalGoalAmount),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Statistics Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Goals',
                                      '${_goals.length}',
                                      LucideIcons.listChecks,
                                      Colors.purple,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Weekly Saving',
                                      numberFormat.format(_totalWeeklySavings),
                                      LucideIcons.trendingUp,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Saved',
                                      numberFormat.format(_totalSaved),
                                      LucideIcons.piggyBank,
                                      Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Still Needed',
                                      numberFormat.format(_totalRemaining),
                                      LucideIcons.info,
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 32.h),

                              // Highlights
                              Text(
                                'Highlights',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12.h),

                              if (_closestGoal != null) ...[
                                _buildHighlightCard(
                                  'Closest Goal',
                                  _closestGoal!.name,
                                  'Just ${_closestGoal!.periodsRequired} ${_closestGoal!.periodsRequired == 1 ? (_closestGoal!.savingFrequency == 'week' ? 'week' : 'month') : (_closestGoal!.savingFrequency == 'week' ? 'weeks' : 'months')} away!',
                                  LucideIcons.zap,
                                  Colors.yellow.shade700,
                                  Colors.yellow.shade50,
                                ),
                                SizedBox(height: 12.h),
                              ],

                              if (_biggestGoal != null) ...[
                                _buildHighlightCard(
                                  'Biggest Goal',
                                  _biggestGoal!.name,
                                  numberFormat.format(_biggestGoal!.totalCost),
                                  LucideIcons.trophy,
                                  Colors.pink.shade700,
                                  Colors.pink.shade50,
                                ),
                              ],

                              SizedBox(height: 32.h),

                              // Motivational Tips
                              Text(
                                'Tips & Motivation',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12.h),

                              _buildTipCard(
                                'Save Consistently',
                                'Small, regular savings add up faster than occasional large deposits.',
                                LucideIcons.calendar,
                                Colors.blue,
                              ),
                              SizedBox(height: 12.h),
                              _buildTipCard(
                                'Track Your Progress',
                                'Celebrating small milestones keeps you motivated for the long run.',
                                LucideIcons.trendingUp,
                                Colors.green,
                              ),
                              SizedBox(height: 12.h),
                              _buildTipCard(
                                'Cut Unnecessary Costs',
                                'Identify "wants" vs "needs" and redirect that money to your goals.',
                                LucideIcons.scissors,
                                Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.shade100.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(-3, -3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color.shade600, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    String label,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String description,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade200.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color.shade600, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
