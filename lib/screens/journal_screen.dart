import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jurnal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Fitur dalam pengembangan',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}