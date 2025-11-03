import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Goal> _goals = [];
  bool _isLoading = true;
  String _sortBy =
      'progress'; // 'progress', 'date', 'amount', 'completion', 'name'
  bool _isAscending = false; // false = descending, true = ascending

  late AnimationController _listAnimationController;
  late AnimationController _addButtonController;
  late AnimationController _sortAnimationController;
  final List<AnimationController> _cardControllers = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _addButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _sortAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadGoals();

    // Animate add button on load
    _addButtonController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _addButtonController.dispose();
    _sortAnimationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('goals') ?? [];

    setState(() {
      _goals = goalsJson
          .map((json) => Goal.fromJson(jsonDecode(json)))
          .toList();
      _sortGoals();
      _isLoading = false;
    });

    // Dispose old card controllers
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();

    // Create new controllers for each card
    for (int i = 0; i < _goals.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _cardControllers.add(controller);
    }

    // Trigger list animation
    _listAnimationController.forward(from: 0);

    // Staggered animation for cards
    _animateCardsStaggered();
  }

  void _animateCardsStaggered() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 50 * i));
      if (mounted) {
        _cardControllers[i].forward();
      }
    }
  }

  void _sortGoals() {
    // Animate sort change
    _sortAnimationController.forward(from: 0);

    switch (_sortBy) {
      case 'progress':
        _goals.sort((a, b) {
          final progressA = a.currentSavings / a.totalCost;
          final progressB = b.currentSavings / b.totalCost;
          return _isAscending
              ? progressA.compareTo(progressB)
              : progressB.compareTo(progressA);
        });
        break;
      case 'date':
        _goals.sort((a, b) {
          return _isAscending
              ? a.targetDate.compareTo(b.targetDate)
              : b.targetDate.compareTo(a.targetDate);
        });
        break;
      case 'amount':
        _goals.sort((a, b) {
          return _isAscending
              ? a.totalCost.compareTo(b.totalCost)
              : b.totalCost.compareTo(a.totalCost);
        });
        break;
      case 'completion':
        _goals.sort((a, b) {
          final aCompleted = a.currentSavings >= a.totalCost ? 1 : 0;
          final bCompleted = b.currentSavings >= b.totalCost ? 1 : 0;
          return _isAscending
              ? aCompleted.compareTo(bCompleted)
              : bCompleted.compareTo(aCompleted);
        });
        break;
      case 'name':
        _goals.sort((a, b) {
          return _isAscending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase());
        });
        break;
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = _goals.map((goal) => jsonEncode(goal.toJson())).toList();
    await prefs.setStringList('goals', goalsJson);
  }

  Future<void> _addGoal() async {
    // Scale down animation
    await _addButtonController.reverse();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );

    // Scale up animation
    _addButtonController.forward();

    if (result != null && result is Goal) {
      // Light haptic feedback for adding a goal
      HapticFeedback.lightImpact();

      setState(() {
        _goals.add(result);
        _sortGoals();
      });
      await _saveGoals();

      // Animate the new goal card
      await _loadGoals();
    }
  }

  Future<void> _deleteGoal(int index) async {
    // Animate card out before deletion
    if (index < _cardControllers.length) {
      await _cardControllers[index].reverse();
    }

    setState(() {
      _goals.removeAt(index);
    });
    await _saveGoals();

    // Reload to re-animate remaining cards
    await _loadGoals();
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
          fixedTargetDate: goal.fixedTargetDate,
        );
        _sortGoals();
      });
      await _saveGoals();

      // Show success modal with Shasha
      if (mounted) {
        final updatedGoal = _goals[index];
        final numberFormat = NumberFormat.currency(
          locale: 'en_PH',
          symbol: '₱',
          decimalDigits: 0,
        );

        // Check if goal is completed
        if (newSavings >= goal.totalCost) {
          // Heavy haptic feedback for goal completion
          HapticFeedback.heavyImpact();
          // Show celebration modal for completed goal
          await _showGoalCompletedModal(goal.name);
        } else if (newSavings > oldSavings) {
          // Medium haptic feedback for progress increase
          HapticFeedback.mediumImpact();
          // Show progress modal
          await _showProgressModal(
            'Great progress!',
            'You now have only ${updatedGoal.periodsDisplayText} left!',
          );
        } else {
          // Light haptic feedback for any update
          HapticFeedback.lightImpact();
          // Show update modal
          await _showProgressModal(
            'Progress updated!',
            'Current savings: ${numberFormat.format(newSavings)}',
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _showGoalCompletedModal(String goalName) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AnimatedDialog(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shasha Money Image
                  Image.asset(
                    'assets/images/shasha_money.png',
                    height: 180.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 24.h),

                  // Congratulations Message
                  Text(
                    'CONGRATULATIONS!',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'You\'ve reached your goal!',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    '"$goalName"',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    'You did it! Your hard work and dedication paid off. Time to celebrate! 🎈',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),

                  // Celebrate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.trophy, size: 24.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Celebrate!',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // Dialog
        ), // _AnimatedDialog
      ),
    );
  }

  Future<void> _showProgressModal(String message, String subtitle) async {
    await showDialog(
      context: context,
      builder: (context) => _AnimatedDialog(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shasha Image
                Image.asset(
                  'assets/images/shasha_tiptoe.png',
                  height: 150.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20.h),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              right: -60.w,
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
              right: -90.w,
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
              'Welcome, ${widget.userName}!',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Let\'s save for your dreams!',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // Add Goal Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _addButtonController,
                    curve: Curves.elasticOut,
                  ),
                ),
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
                      elevation: 2,
                      shadowColor: Colors.blue.shade200,
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
            ),

            SizedBox(height: 24.h),

            // Sort Dropdown (only show if there are goals)
            if (!_isLoading && _goals.isNotEmpty)
              FadeTransition(
                opacity: _listAnimationController,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _listAnimationController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Goals',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            // Sort Direction Toggle
                            AnimatedRotation(
                              turns: _isAscending ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isAscending = !_isAscending;
                                        _sortGoals();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      child: Icon(
                                        LucideIcons.arrowDown,
                                        size: 20.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Sort By Dropdown
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                value: _sortBy,
                                underline: const SizedBox(),
                                icon: Icon(
                                  LucideIcons.chevronDown,
                                  size: 18.sp,
                                  color: Colors.grey.shade600,
                                ),
                                isDense: true,
                                borderRadius: BorderRadius.circular(12.r),
                                items: [
                                  DropdownMenuItem(
                                    value: 'progress',
                                    child: Text(
                                      'By Progress',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'date',
                                    child: Text(
                                      'By Date',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'amount',
                                    child: Text(
                                      'By Amount',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completion',
                                    child: Text(
                                      'By Completion',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text(
                                      'By Name',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _sortBy = value;
                                      _sortGoals();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (!_isLoading && _goals.isNotEmpty) SizedBox(height: 16.h),

            // Goals List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _goals.isEmpty
                    ? _buildEmptyState()
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ListView.builder(
                          key: ValueKey(_sortBy + _isAscending.toString()),
                          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                          itemCount: _goals.length,
                          itemBuilder: (context, index) {
                            if (index >= _cardControllers.length) {
                              return const SizedBox();
                            }
                            return SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.3, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _cardControllers[index],
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: _cardControllers[index],
                                child: _buildGoalCard(_goals[index], index),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/shasha_sad.png',
              height: 220.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start your savings journey by adding your first goal!',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 20.sp,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'Tap "Add a Goal" above to begin!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.blue.shade100.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(-5, -5),
            spreadRadius: 0,
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
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: goal.currentSavings >= goal.totalCost
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (goal.currentSavings >= goal.totalCost
                                      ? Colors.green
                                      : Colors.blue)
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      goal.currentSavings >= goal.totalCost
                          ? 'Completed'
                          : goal.periodsDisplayText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Delete Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            title: Text(
                              'Delete Goal',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete "${goal.name}"?',
                              style: TextStyle(fontSize: 15.sp),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // Medium haptic feedback for deletion
                          HapticFeedback.mediumImpact();
                          await _deleteGoal(index);
                        }
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 20.sp,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(
              children: [
                Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade300.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  goal.currentSavings >= goal.totalCost
                      ? 'Completed by'
                      : 'Target',
                  DateFormat('MMM dd,\nyyyy').format(goal.targetDate),
                ),
              ),
              if (goal.currentSavings < goal.totalCost) ...[
                Container(width: 1, height: 40.h, color: Colors.grey.shade200),
                Expanded(
                  child: _buildDetailItem(
                    'Still need',
                    '${numberFormat.format(goal.amountNeeded)}',
                  ),
                ),
              ],
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

          // Update Progress Button (only show if goal is not completed)
          if (goal.currentSavings < goal.totalCost) ...[
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
                  elevation: 2,
                  shadowColor: Colors.green.shade300,
                ),
              ),
            ),
          ],
        ],
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

// Animated Dialog Widget for bounce/spring effect
class _AnimatedDialog extends StatefulWidget {
  final Widget child;

  const _AnimatedDialog({required this.child});

  @override
  State<_AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<_AnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
