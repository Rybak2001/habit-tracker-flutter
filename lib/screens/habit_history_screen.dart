import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitHistoryScreen extends StatelessWidget {
  final String habitId;

  const HabitHistoryScreen({super.key, required this.habitId});

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final habit = provider.getHabit(habitId);
        final completions = provider.getCompletionsForHabit(habitId);

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Historial')),
            body: const Center(child: Text('Hábito no encontrado')),
          );
        }

        final color = _hexToColor(habit.color);

        // Group by month
        final grouped = <String, List<Completion>>{};
        for (final c in completions) {
          final key = DateFormat('MMMM yyyy', 'es').format(c.completedAt);
          grouped.putIfAbsent(key, () => []).add(c);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Historial: ${habit.name}'),
            centerTitle: true,
          ),
          body: completions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Sin registros aún',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa este hábito para ver el historial',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: color, width: 5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _SummaryItem(
                              icon: Icons.check_circle_outline,
                              value: '${completions.length}',
                              label: 'Total',
                            ),
                            _SummaryItem(
                              icon: Icons.local_fire_department,
                              value: '${provider.getCurrentStreak(habitId)}',
                              label: 'Racha',
                            ),
                            _SummaryItem(
                              icon: Icons.flag_rounded,
                              value: '${habit.targetDays}',
                              label: 'Objetivo',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grouped by month
                    ...grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                            child: Text(
                              entry.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...entry.value.map((c) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.check, color: color, size: 20),
                                  ),
                                  title: Text(
                                    DateFormat('EEEE, d MMMM', 'es').format(c.completedAt),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(c.completedAt),
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                      if (c.note != null && c.note!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.note_rounded, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  c.note!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
