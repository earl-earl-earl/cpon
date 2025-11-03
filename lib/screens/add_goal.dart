import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/goal.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _currentSavingsController = TextEditingController();

  double _savingAmount = 1000;
  String _savingFrequency = 'week';
  DateTime? _targetDatePicker;

  // Toggle between modes
  bool _isTimeMode = true; // true = Calculate Time, false = Calculate Savings

  // Sacrifice Calculator
  final _sacrificeItemController = TextEditingController();
  final _sacrificeCostController = TextEditingController();
  int _sacrificeFrequency = 3; // times per week
  bool _showSacrificeCalculator = false;

  // Calculated values for TIME MODE
  double get _amountNeeded {
    final cost = double.tryParse(_costController.text) ?? 0;
    final current = double.tryParse(_currentSavingsController.text) ?? 0;
    return cost - current;
  }

  int get _periodsRequired {
    if (_amountNeeded <= 0 || _savingAmount <= 0) return 0;
    return (_amountNeeded / _savingAmount).ceil();
  }

  DateTime get _targetDate {
    final now = DateTime.now();
    if (_savingFrequency == 'week') {
      return now.add(Duration(days: _periodsRequired * 7));
    } else {
      return now.add(Duration(days: _periodsRequired * 30));
    }
  }

  // Calculated values for SAVINGS MODE
  double get _requiredSavingsPerWeek {
    if (_targetDatePicker == null || _amountNeeded <= 0) return 0;
    final daysUntil = _targetDatePicker!.difference(DateTime.now()).inDays;
    if (daysUntil <= 0) return 0;
    final weeksUntil = daysUntil / 7;
    return _amountNeeded / weeksUntil;
  }

  double get _requiredSavingsPerMonth {
    if (_targetDatePicker == null || _amountNeeded <= 0) return 0;
    final daysUntil = _targetDatePicker!.difference(DateTime.now()).inDays;
    if (daysUntil <= 0) return 0;
    final monthsUntil = daysUntil / 30;
    return _amountNeeded / monthsUntil;
  }

  // Calculated values for SACRIFICE MODE
  double get _sacrificeSavingsPerWeek {
    final cost = double.tryParse(_sacrificeCostController.text) ?? 0;
    return cost * _sacrificeFrequency;
  }

  double get _newSavingAmount {
    return _savingAmount + _sacrificeSavingsPerWeek;
  }

  int get _newPeriodsRequired {
    if (_amountNeeded <= 0 || _newSavingAmount <= 0) return 0;
    return (_amountNeeded / _newSavingAmount).ceil();
  }

  int get _periodsSaved {
    return _periodsRequired - _newPeriodsRequired;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _currentSavingsController.dispose();
    _sacrificeItemController.dispose();
    _sacrificeCostController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      // Validate target date in savings mode
      if (!_isTimeMode && _targetDatePicker == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a target date')),
        );
        return;
      }

      // In savings mode, use the calculated savings amount
      final savingAmount = _isTimeMode
          ? _savingAmount
          : (_savingFrequency == 'week'
                ? _requiredSavingsPerWeek
                : _requiredSavingsPerMonth);

      final goal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        totalCost: double.parse(_costController.text),
        currentSavings: double.tryParse(_currentSavingsController.text) ?? 0,
        savingAmount: savingAmount,
        savingFrequency: _savingFrequency,
        createdAt: DateTime.now(),
      );

      Navigator.pop(context, goal);
    }
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDatePicker ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _targetDatePicker = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add a Goal',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                Text(
                  'What\'s your goal?',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),

                // Mode Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTimeMode = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _isTimeMode
                                  ? Colors.blue.shade600
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 18.sp,
                                  color: _isTimeMode
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Calculate Time',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _isTimeMode
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTimeMode = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: !_isTimeMode
                                  ? Colors.blue.shade600
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.calculator,
                                  size: 18.sp,
                                  color: !_isTimeMode
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Calculate Savings',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: !_isTimeMode
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Goal Name
                _buildLabel('What are you saving for?'),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    _isTimeMode
                        ? 'New Phone, Concert Ticket, etc.'
                        : 'Christmas Gifts, Trip, etc.',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 20.h),

                // Total Cost
                _buildLabel(
                  _isTimeMode
                      ? 'How much does it cost?'
                      : 'How much do you need?',
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _costController,
                  decoration: _buildInputDecoration('35000'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the cost';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 20.h),

                // Current Savings
                _buildLabel('How much do you have saved already?'),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _currentSavingsController,
                  decoration: _buildInputDecoration('0 (optional)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null ||
                          double.parse(value) < 0) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 20.h),

                // TIME MODE: Saving Frequency + Slider
                if (_isTimeMode) ...[
                  // Saving Frequency
                  _buildLabel('How often?'),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _savingFrequency,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'week',
                            child: Text('per week'),
                          ),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('per month'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _savingFrequency = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Saving Amount Slider
                  _buildLabel('How much can you save?'),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          numberFormat.format(_savingAmount),
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Slider(
                          value: _savingAmount,
                          min: 100,
                          max: 10000,
                          divisions: 99,
                          label: numberFormat.format(_savingAmount),
                          onChanged: (value) {
                            setState(() {
                              _savingAmount = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱100',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '₱10,000',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // SAVINGS MODE: Target Date Picker
                if (!_isTimeMode) ...[
                  // Target Date
                  _buildLabel('When do you need it by?'),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: _selectTargetDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _targetDatePicker == null
                                ? 'Select target date'
                                : DateFormat(
                                    'MMMM dd, yyyy',
                                  ).format(_targetDatePicker!),
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: _targetDatePicker == null
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                          Icon(
                            LucideIcons.calendar,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Frequency selector for savings mode
                  _buildLabel('Show savings per:'),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _savingFrequency,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'week', child: Text('week')),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('month'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _savingFrequency = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],

                // Result Section - TIME MODE
                if (_isTimeMode &&
                    _nameController.text.isNotEmpty &&
                    _costController.text.isNotEmpty) ...[
                  SizedBox(height: 40.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
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
                      children: [
                        Text(
                          'You can get your',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _nameController.text,
                          style: TextStyle(
                            fontSize: 24.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'in...',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$_periodsRequired ${_savingFrequency == 'week' ? 'Weeks' : 'Months'}!',
                          style: TextStyle(
                            fontSize: 48.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Divider(color: Colors.white30, thickness: 1),
                        SizedBox(height: 16.h),
                        _buildBreakdownRow(
                          'You need',
                          '${numberFormat.format(_amountNeeded)} more',
                        ),
                        SizedBox(height: 12.h),
                        _buildBreakdownRow(
                          'Saving',
                          '${numberFormat.format(_savingAmount)} per $_savingFrequency',
                        ),
                        SizedBox(height: 12.h),
                        _buildBreakdownRow(
                          'Target Date',
                          DateFormat('MMMM dd, yyyy').format(_targetDate),
                        ),
                      ],
                    ),
                  ),
                ],

                // Result Section - SAVINGS MODE
                if (!_isTimeMode &&
                    _nameController.text.isNotEmpty &&
                    _costController.text.isNotEmpty &&
                    _targetDatePicker != null) ...[
                  SizedBox(height: 40.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'To get your ${numberFormat.format(_amountNeeded + (double.tryParse(_currentSavingsController.text) ?? 0))} by',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          DateFormat(
                            'MMMM dd, yyyy',
                          ).format(_targetDatePicker!),
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'you need to save:',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          numberFormat.format(
                            _savingFrequency == 'week'
                                ? _requiredSavingsPerWeek
                                : _requiredSavingsPerMonth,
                          ),
                          style: TextStyle(
                            fontSize: 48.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'per $_savingFrequency',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Divider(color: Colors.white30, thickness: 1),
                        SizedBox(height: 16.h),
                        _buildBreakdownRow(
                          'You need',
                          '${numberFormat.format(_amountNeeded)} more',
                        ),
                        SizedBox(height: 12.h),
                        _buildBreakdownRow(
                          'Days until target',
                          '${_targetDatePicker!.difference(DateTime.now()).inDays} days',
                        ),
                        SizedBox(height: 12.h),
                        _buildBreakdownRow(
                          _savingFrequency == 'week'
                              ? 'Or per month'
                              : 'Or per week',
                          numberFormat.format(
                            _savingFrequency == 'week'
                                ? _requiredSavingsPerMonth
                                : _requiredSavingsPerWeek,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Sacrifice Calculator - Only for TIME MODE
                if (_isTimeMode &&
                    _nameController.text.isNotEmpty &&
                    _costController.text.isNotEmpty) ...[
                  SizedBox(height: 24.h),

                  // Toggle button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showSacrificeCalculator = !_showSacrificeCalculator;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.zap,
                            color: Colors.orange.shade600,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Want to get there faster?',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                Text(
                                  'See how small sacrifices add up',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showSacrificeCalculator
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            color: Colors.orange.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sacrifice Calculator Form
                  if (_showSacrificeCalculator) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('What\'s a regular "want"?'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _sacrificeItemController,
                            decoration: _buildInputDecoration(
                              'Milk Tea, GrabFood, Coffee Shop',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: 16.h),

                          _buildLabel('How much does it cost?'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _sacrificeCostController,
                            decoration: _buildInputDecoration('150'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: 16.h),

                          _buildLabel('How often do you buy it per week?'),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_sacrificeFrequency times per week',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Slider(
                                  value: _sacrificeFrequency.toDouble(),
                                  min: 1,
                                  max: 14,
                                  divisions: 13,
                                  activeColor: Colors.orange.shade600,
                                  label: '$_sacrificeFrequency times',
                                  onChanged: (value) {
                                    setState(() {
                                      _sacrificeFrequency = value.toInt();
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '1x',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '14x',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Sacrifice Result
                          if (_sacrificeItemController.text.isNotEmpty &&
                              _sacrificeCostController.text.isNotEmpty) ...[
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    LucideIcons.trendingDown,
                                    color: Colors.white,
                                    size: 32.sp,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'By cutting back on ${_sacrificeItemController.text}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'You can save an extra',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${numberFormat.format(_sacrificeSavingsPerWeek)} per week!',
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'This one change will get you to your goal',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '$_periodsSaved',
                                              style: TextStyle(
                                                fontSize: 48.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              '${_savingFrequency == 'week' ? 'WEEKS' : 'MONTHS'}',
                                              style: TextStyle(
                                                fontSize: 20.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'FASTER!',
                                          style: TextStyle(
                                            fontSize: 24.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Divider(color: Colors.white30, thickness: 1),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'New savings per week',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        numberFormat.format(_newSavingAmount),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'New target date',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(
                                          DateTime.now().add(
                                            Duration(
                                              days:
                                                  _newPeriodsRequired *
                                                  (_savingFrequency == 'week'
                                                      ? 7
                                                      : 30),
                                            ),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],

                SizedBox(height: 32.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Goal',
                      style: TextStyle(
                        fontSize: 18.sp,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
