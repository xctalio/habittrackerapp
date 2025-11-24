import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/habit_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _habitService = HabitService();
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  int _getStreak() {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    while (true) {
      final dateKey = HabitService.formatDate(currentDate);
      final habits = _habitService.getAllHabits();
      
      bool hasCompletion = false;
      for (var habit in habits) {
        if (habit.completionDates[dateKey] == true) {
          hasCompletion = true;
          break;
        }
      }
      
      if (!hasCompletion) break;
      
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  int _getTotalCompletions() {
    int total = 0;
    final habits = _habitService.getAllHabits();
    
    for (var habit in habits) {
      total += habit.completionDates.values.where((v) => v).length;
    }
    
    return total;
  }

  double _getMonthlyCompletionRate() {
    final habits = _habitService.getAllHabits();
    if (habits.isEmpty) return 0.0;
    
    int daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    int totalPossible = habits.length * daysInMonth;
    int totalCompleted = 0;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dateKey = HabitService.formatDate(date);
      
      for (var habit in habits) {
        if (habit.completionDates[dateKey] == true) {
          totalCompleted++;
        }
      }
    }
    
    return totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
  }

  List<Map<String, dynamic>> _getHabitStats() {
    final habits = _habitService.getAllHabits();
    final List<Map<String, dynamic>> stats = [];
    
    int daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    
    for (var habit in habits) {
      int completedDays = 0;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        if (habit.isCompletedOnDate(date)) {
          completedDays++;
        }
      }
      
      double percentage = daysInMonth > 0 ? (completedDays / daysInMonth) * 100 : 0;
      
      stats.add({
        'title': habit.title,
        'color': habit.color,
        'completed': completedDays,
        'total': daysInMonth,
        'percentage': percentage,
        'streak': habit.getCurrentStreak(),
        'longestStreak': habit.getLongestStreak(),
      });
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habits = _habitService.getAllHabits();
    final streak = _getStreak();
    final totalCompletions = _getTotalCompletions();
    final monthlyRate = _getMonthlyCompletionRate();
    final habitStats = _getHabitStats();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistik',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Month Navigation
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.cyan[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 24),

              // Key Metrics
              Text(
                'Ringkasan Bulan Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyan[400] : Colors.cyan[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.local_fire_department,
                      title: 'Streak Saat Ini',
                      value: '$streak hari',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.check_circle,
                      title: 'Total Selesai',
                      value: '$totalCompletions',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                icon: Icons.trending_up,
                title: 'Tingkat Penyelesaian',
                value: '${(monthlyRate * 100).toStringAsFixed(1)}%',
                color: Colors.cyan,
                isFull: true,
              ),
              const SizedBox(height: 24),

              // Habit Details
              Text(
                'Detail Per Habit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyan[400] : Colors.cyan[700],
                ),
              ),
              const SizedBox(height: 12),
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
                              'Belum ada habit',
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
                      itemCount: habitStats.length,
                      itemBuilder: (context, index) {
                        final stat = habitStats[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getColorFromName(stat['color']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        stat['title'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Completed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${stat['completed']}/${stat['total']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Streak',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${stat['streak']} hari',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Best Streak',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${stat['longestStreak']} hari',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stat['percentage'] / 100,
                                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getColorFromName(stat['color']),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${stat['percentage'].toStringAsFixed(1)}% Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getColorFromName(stat['color']),
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
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFull = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String? colorName) {
    switch (colorName) {
      case 'cyan':
        return Colors.cyan;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.cyan;
    }
  }
}