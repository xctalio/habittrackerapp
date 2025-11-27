import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class NewHabitScreen extends StatefulWidget {
  const NewHabitScreen({Key? key}) : super(key: key);

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  final _titleController = TextEditingController();
  final _habitService = HabitService();
  String _selectedColor = 'cyan';
  String _recurrenceType = 'daily'; // daily, weekly, monthly
  List<int> _selectedWeekDays = []; // 0=Sunday to 6=Saturday
  int _selectedMonthDay = 1;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'cyan', 'color': Colors.cyan},
    {'name': 'purple', 'color': Colors.purple},
    {'name': 'green', 'color': Colors.green},
    {'name': 'pink', 'color': Colors.pink},
  ];

  final List<String> _weekDayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  void _toggleWeekDay(int day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
      }
      _selectedWeekDays.sort();
    });
  }

  void _saveHabit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul habit tidak boleh kosong!')),
      );
      return;
    }

    if (_recurrenceType == 'weekly' && _selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 hari untuk weekly habit!'),
        ),
      );
      return;
    }

    try {
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        createdAt: DateTime.now(),
        color: _selectedColor,
        recurrenceType: _recurrenceType,
        recurrenceDays: _recurrenceType == 'weekly' ? _selectedWeekDays : [],
        recurrenceDate: _recurrenceType == 'monthly' ? _selectedMonthDay : null,
      );

      print('📝 Creating SINGLE habit:');
      print('  Title: ${habit.title}');
      print('  Recurrence: ${habit.recurrenceType}');
      if (_recurrenceType == 'weekly') {
        print('  Days: ${habit.recurrenceDays}');
      }
      if (_recurrenceType == 'monthly') {
        print('  Date: ${habit.recurrenceDate}');
      }

      await _habitService.addHabit(habit);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Judul Habit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Masukkan judul habit...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.cyan[400]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Select Label Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _colors.map((colorData) {
                final isSelected = _selectedColor == colorData['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorData['name'];
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorData['color'],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text(
              'Jadwal Pengulangan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  _buildRecurrenceOption('daily', 'Setiap Hari', isDark),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  _buildRecurrenceOption('weekly', 'Mingguan', isDark),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  _buildRecurrenceOption('monthly', 'Bulanan', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_recurrenceType == 'weekly') ...[
              Text(
                'Pilih Hari',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final isSelected = _selectedWeekDays.contains(index);
                  return GestureDetector(
                    onTap: () => _toggleWeekDay(index),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.cyan[400]
                            : (isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.cyan[400]!
                              : (isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _weekDayNames[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],

            if (_recurrenceType == 'monthly') ...[
              Text(
                'Pilih Tanggal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tanggal: $_selectedMonthDay',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonthDay > 1) _selectedMonthDay--;
                            });
                          },
                          icon: const Icon(Icons.remove),
                          iconSize: 20,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonthDay < 31) _selectedMonthDay++;
                            });
                          },
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create new habit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceOption(String value, String label, bool isDark) {
    final isSelected = _recurrenceType == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: _recurrenceType,
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _recurrenceType = val;
            });
          }
        },
        activeColor: Colors.cyan[400],
      ),
      onTap: () {
        setState(() {
          _recurrenceType = value;
        });
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
