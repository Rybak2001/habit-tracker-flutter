import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool Function(HabitProvider p) check;

  const _Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.check,
  });
}

final _achievements = <_Achievement>[
  _Achievement(
    title: 'Primer Paso',
    description: 'Crea tu primer hábito',
    icon: Icons.add_circle_outline,
    check: (p) => p.habits.isNotEmpty,
  ),
  _Achievement(
    title: 'Racha de 7 días',
    description: 'Mantén una racha de 7 días',
    icon: Icons.local_fire_department,
    check: (p) => p.maxCurrentStreak >= 7 || p.longestStreakEver >= 7,
  ),
  _Achievement(
    title: 'Racha de 14 días',
    description: 'Mantén una racha de 14 días',
    icon: Icons.local_fire_department,
    check: (p) => p.maxCurrentStreak >= 14 || p.longestStreakEver >= 14,
  ),
  _Achievement(
    title: 'Racha de 30 días',
    description: 'Mantén una racha de 30 días',
    icon: Icons.local_fire_department,
    check: (p) => p.maxCurrentStreak >= 30 || p.longestStreakEver >= 30,
  ),
  _Achievement(
    title: 'Racha de 60 días',
    description: 'Mantén una racha de 60 días',
    icon: Icons.local_fire_department,
    check: (p) => p.maxCurrentStreak >= 60 || p.longestStreakEver >= 60,
  ),
  _Achievement(
    title: 'Racha de 100 días',
    description: 'Mantén una racha de 100 días',
    icon: Icons.whatshot,
    check: (p) => p.maxCurrentStreak >= 100 || p.longestStreakEver >= 100,
  ),
  _Achievement(
    title: 'Constancia',
    description: '10 completados en total',
    icon: Icons.check_circle_outline,
    check: (p) => p.totalCompletionsAll >= 10,
  ),
  _Achievement(
    title: 'Dedicación',
    description: '50 completados en total',
    icon: Icons.check_circle,
    check: (p) => p.totalCompletionsAll >= 50,
  ),
  _Achievement(
    title: 'Centenario',
    description: '100 completados en total',
    icon: Icons.military_tech,
    check: (p) => p.totalCompletionsAll >= 100,
  ),
  _Achievement(
    title: 'Experto',
    description: '500 completados en total',
    icon: Icons.star,
    check: (p) => p.totalCompletionsAll >= 500,
  ),
  _Achievement(
    title: 'Tres hábitos',
    description: 'Ten 3 hábitos activos',
    icon: Icons.format_list_numbered,
    check: (p) => p.habits.length >= 3,
  ),
  _Achievement(
    title: 'Cinco hábitos',
    description: 'Ten 5 hábitos activos',
    icon: Icons.format_list_numbered,
    check: (p) => p.habits.length >= 5,
  ),
  _Achievement(
    title: 'Diez hábitos',
    description: 'Ten 10 hábitos activos',
    icon: Icons.format_list_numbered,
    check: (p) => p.habits.length >= 10,
  ),
  _Achievement(
    title: 'Día Perfecto',
    description: 'Completa todos los hábitos en un día',
    icon: Icons.emoji_events,
    check: (p) => p.allCompletedToday,
  ),
];

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        centerTitle: true,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, _) {
          if (provider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Sin logros aún',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea hábitos y completa desafíos para desbloquear logros',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final unlocked = _achievements.where((a) => a.check(provider)).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 40,
                          color: Theme.of(context).colorScheme.onPrimaryContainer),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlocked / ${_achievements.length} desbloqueados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: unlocked / _achievements.length,
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  final isUnlocked = achievement.check(provider);

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: isUnlocked ? null : Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            achievement.icon,
                            size: 36,
                            color: isUnlocked
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isUnlocked ? null : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnlocked ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isUnlocked) ...[
                            const SizedBox(height: 4),
                            Icon(Icons.check_circle, size: 16,
                                color: Colors.green.shade400),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
