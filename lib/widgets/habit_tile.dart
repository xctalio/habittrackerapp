import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitTile({
    Key? key,
    required this.habit,
    required this.date,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  Color _getColor() {
    switch (habit.color) {
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

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedOnDate(date);
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
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.black : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                border: Border.all(
                  color: isCompleted ? Colors.black : Colors.grey[400]!,
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.cyan),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Hapus'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getColor(),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}