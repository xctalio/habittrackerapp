import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'new_habit_screen.dart';
import '../widgets/habit_tile.dart';
import '../widgets/edit_habit_dialog.dart';
import '../services/habit_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _habitService = HabitService();
  final _authService = AuthService();

  void _showDeleteDialog(String habitId, String habitTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Hapus Habit',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Yakin ingin menghapus "$habitTitle"?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _habitService.deleteHabit(habitId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Habit berhasil dihapus')),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(
              'Hapus',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String habitId) {
    final habit =
        _habitService.getAllHabits().firstWhere((h) => h.id == habitId);

    showDialog(
      context: context,
      builder: (context) => EditHabitDialog(
        habit: habit,
        onUpdate: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = _habitService.getAllHabits();
    final today = DateTime.now();
    final completedCount = _habitService.getCompletedCountForDate(today);
    final totalCount = _habitService.getTotalCount();
    final progress = _habitService.getProgressForDate(today);

    // Get username dari AuthService
    final username = _authService.currentUsername ??
        _authService.currentUser?.username ??
        'User';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $username!!!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(today),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$completedCount / $totalCount habit done',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan[400]!),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: habits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 80,
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada habit',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan habit pertama Anda!',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onLongPress: () => _showEditDialog(habit.id),
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
                                onDismissed: (direction) async {
                                  try {
                                    await _habitService.deleteHabit(habit.id);
                                    if (mounted) {
                                      setState(() {});
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text('Habit dihapus'),
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2C)
                                              : null,
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            textColor: Colors.cyan[400],
                                            onPressed: () async {
                                              try {
                                                await _habitService
                                                    .addHabit(habit);
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Error: $e')),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                child: HabitTile(
                                  habit: habit,
                                  date: today,
                                  onToggle: () async {
                                    try {
                                      await _habitService
                                          .toggleHabit(habit.id, today);
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  onDelete: () =>
                                      _showDeleteDialog(habit.id, habit.title),
                                  onEdit: () => _showEditDialog(habit.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewHabitScreen()),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: Colors.cyan[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}