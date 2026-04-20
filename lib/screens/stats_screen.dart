import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        centerTitle: true,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, _) {
          if (provider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Sin estadísticas aún',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea hábitos y empieza a registrar para ver tu progreso',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final weekly = provider.getWeeklyCompletionCounts();
          final monthly = provider.getMonthlyCompletionCounts();
          final catBreakdown = provider.getCategoryBreakdown();
          final bestDay = provider.getBestDayOfWeek();
          final maxWeekly = weekly.reduce((a, b) => a > b ? a : b);
          final maxMonthly = monthly.isEmpty ? 1 : monthly.reduce((a, b) => a > b ? a : b);
          final totalComps = provider.totalCompletionsAll;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overview card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen General',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _OverviewStat(
                            icon: Icons.check_circle_outline,
                            value: '$totalComps',
                            label: 'Total completados',
                          ),
                          _OverviewStat(
                            icon: Icons.local_fire_department,
                            value: '${provider.maxCurrentStreak}',
                            label: 'Mejor racha actual',
                          ),
                          _OverviewStat(
                            icon: Icons.star_rounded,
                            value: bestDay,
                            label: 'Mejor día',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weekly visualization
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Últimos 7 días',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(7, (i) {
                          final day = DateTime.now().subtract(Duration(days: 6 - i));
                          final dayLabel = DateFormat('E', 'es').format(day).substring(0, 2).toUpperCase();
                          final value = weekly[i];
                          final height = maxWeekly > 0 ? (value / maxWeekly * 80).clamp(4.0, 80.0) : 4.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: [
                                  Text('$value',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary
                                          .withOpacity(value > 0 ? 0.7 : 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(dayLabel,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monthly trend
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Últimos 30 días',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: List.generate(30, (i) {
                          final value = monthly[i];
                          final intensity = maxMonthly > 0 ? value / maxMonthly : 0.0;
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withOpacity(intensity > 0 ? 0.2 + intensity * 0.8 : 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category breakdown
              if (catBreakdown.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Por Categoría',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ..._buildCategoryBars(context, catBreakdown),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Per-habit stats
              const Padding(
                padding: EdgeInsets.only(bottom: 8, top: 4),
                child: Text('Por Hábito',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ...provider.habits.map((habit) {
                final streak = provider.getCurrentStreak(habit.id);
                final total = provider.getTotalCompletions(habit.id);
                final color = _hexToColor(habit.color);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: color, width: 5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _StatBox(
                              icon: Icons.local_fire_department,
                              value: '$streak',
                              label: 'Racha actual',
                            ),
                            Container(
                                width: 1, height: 40, color: Colors.grey.shade200),
                            _StatBox(
                              icon: Icons.check_circle_outline,
                              value: '$total',
                              label: 'Total',
                            ),
                            Container(
                                width: 1, height: 40, color: Colors.grey.shade200),
                            _StatBox(
                              icon: Icons.flag_rounded,
                              value: '${habit.targetDays}',
                              label: 'Días / Sem',
                            ),
                          ],
                        ),
                        if (streak >= 7) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events, size: 16, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  _badgeText(streak),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  String _badgeText(int streak) {
    if (streak >= 100) return '100 días! Leyenda!';
    if (streak >= 60) return '60 días! Imparable!';
    if (streak >= 30) return 'Campeón mensual!';
    if (streak >= 14) return 'Guerrero de dos semanas!';
    if (streak >= 7) return 'Una semana fuerte!';
    return '';
  }

  List<Widget> _buildCategoryBars(BuildContext context, Map<String, int> breakdown) {
    final maxVal = breakdown.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      Colors.purple, Colors.blue, Colors.teal, Colors.orange,
      Colors.pink, Colors.green, Colors.indigo,
    ];
    int colorIdx = 0;
    return breakdown.entries.map((e) {
      final pct = maxVal > 0 ? e.value / maxVal : 0.0;
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${e.value}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _OverviewStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600, letterSpacing: 0.3),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
