import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class EditHabitDialog extends StatefulWidget {
  final Habit habit;
  final VoidCallback onUpdate;

  const EditHabitDialog({
    Key? key,
    required this.habit,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController _titleController;
  late HabitService _habitService;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit.title);
    _habitService = HabitService();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      title: Text(
        'Edit Habit',
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      content: TextField(
        controller: _titleController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Judul habit...',
          hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
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
        ),
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
          onPressed: () {
            final newTitle = _titleController.text.trim();
            if (newTitle.isNotEmpty && newTitle != widget.habit.title) {
              final updatedHabit = Habit(
                id: widget.habit.id,
                title: newTitle,
                createdAt: widget.habit.createdAt,
                color: widget.habit.color,
                completionDates: widget.habit.completionDates,
              );
              
              _habitService.updateHabit(widget.habit.id, updatedHabit);
              widget.onUpdate();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Habit berhasil diperbarui')),
              );
            } else if (newTitle == widget.habit.title) {
              Navigator.pop(context);
            }
          },
          child: Text(
            'Simpan',
            style: TextStyle(color: Colors.cyan[400]),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}