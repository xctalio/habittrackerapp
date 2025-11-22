import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/habit_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _habitService = HabitService();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final days = <DateTime>[];

    for (int i = 0; i < firstWeekday; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i)));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _deleteHabit(String habitId) {
    setState(() {
      _habitService.deleteHabit(habitId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = _habitService.getAllHabits();
    final days = _getDaysInMonth(_currentMonth);
    final completedCount = _habitService.getCompletedCountForDate(_selectedDate);
    final totalCount = _habitService.getTotalCount();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: Icon(
                          Icons.chevron_left,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                          .map((day) => SizedBox(
                                width: 40,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final date = days[index];
                        final isToday = _isSameDay(date, DateTime.now());
                        final isSelected = _isSameDay(date, _selectedDate);
                        final isCurrentMonth = date.month == _currentMonth.month;
                        final hasCompletion = _habitService.hasCompletionOnDate(date);
                        final completionCount = _habitService.getCompletedCountForDate(date);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.cyan[400]
                                  : isSelected
                                      ? Colors.cyan[700]
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected && !isToday
                                  ? Border.all(color: Colors.cyan[400]!, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isCurrentMonth
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    fontSize: 14,
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (hasCompletion && isCurrentMonth)
                                  Positioned(
                                    bottom: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        completionCount > 3 ? 3 : completionCount,
                                        (index) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habits for ${DateFormat('MMM dd').format(_selectedDate)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyan[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              habits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 60,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada habit',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final isCompleted = habit.isCompletedOnDate(_selectedDate);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(habit.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _deleteHabit(habit.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _habitService.toggleHabit(habit.id, _selectedDate);
                                      });
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? Colors.black
                                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                        border: Border.all(
                                          color: isCompleted
                                              ? Colors.black
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      habit.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: isCompleted
                                            ? (isDark ? Colors.grey[600] : Colors.grey)
                                            : (isDark ? Colors.white : Colors.black),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}