import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'habit_detail_screen.dart';

class HabitListScreen extends StatelessWidget {
  const HabitListScreen({super.key});

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _showNoteDialog(BuildContext context, HabitProvider provider, String habitId) {
    final isCompleted = provider.isCompletedToday(habitId);
    if (isCompleted) {
      provider.toggleCompletion(habitId);
      return;
    }
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar hábito'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            hintText: 'Nota opcional...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.toggleCompletion(habitId, note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  String _sortLabel(HabitSort sort) {
    switch (sort) {
      case HabitSort.alphabetical: return 'Alfabético';
      case HabitSort.streak: return 'Por racha';
      case HabitSort.creationDate: return 'Fecha de creación';
      case HabitSort.completionRate: return 'Tasa de completado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        centerTitle: true,
        actions: [
          Consumer<HabitProvider>(
            builder: (context, provider, _) => PopupMenuButton<HabitSort>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Ordenar',
              onSelected: (sort) => provider.setSort(sort),
              itemBuilder: (_) => HabitSort.values.map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == provider.currentSort)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(_sortLabel(s)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, _) {
          if (provider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Sin hábitos aún',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para crear tu primer hábito',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HabitDetailScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear hábito'),
                  ),
                ],
              ),
            );
          }

          final filtered = provider.filteredHabits;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Daily Summary Card
              _DailySummaryCard(
                completed: provider.completedTodayCount,
                total: provider.habits.length,
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Buscar hábito...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 12),

              // Category filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: CATEGORIES.map((cat) {
                    final selected = provider.categoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => provider.setCategoryFilter(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Habits list
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No se encontraron hábitos', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((habit) {
                  final completed = provider.isCompletedToday(habit.id);
                  final streak = provider.getCurrentStreak(habit.id);
                  final color = _hexToColor(habit.color);
                  final weekComps = provider.getWeekCompletions(habit.id);
                  final progress = habit.targetDays > 0
                      ? (weekComps / habit.targetDays).clamp(0.0, 1.0)
                      : 0.0;

                  return Dismissible(
                    key: Key(habit.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 28),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar hábito'),
                          content: Text('¿Eliminar "${habit.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => provider.deleteHabit(habit.id),
                    child: _HabitCard(
                      habit: habit,
                      completed: completed,
                      streak: streak,
                      color: color,
                      progress: progress,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitDetailScreen(habitId: habit.id),
                        ),
                      ),
                      onToggle: () => _showNoteDialog(context, provider, habit.id),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HabitDetailScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final int completed;
  final int total;

  const _DailySummaryCard({required this.completed, required this.total});

  String _motivationalMessage() {
    if (total == 0) return 'Crea tu primer hábito';
    final pct = completed / total;
    if (pct >= 1.0) return '¡Día perfecto! Todos completados';
    if (pct >= 0.75) return '¡Casi lo logras! Un poco más';
    if (pct >= 0.5) return '¡Buen progreso! Sigue así';
    if (pct > 0) return '¡Buen inicio! No te detengas';
    return '¡Empieza tu día con un hábito!';
  }

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Hoy: $completed de $total completados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _motivationalMessage(),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool completed;
  final int streak;
  final Color color;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _HabitCard({
    required this.habit,
    required this.completed,
    required this.streak,
    required this.color,
    required this.progress,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (habit.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              habit.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.flag_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${habit.targetDays} días/sem',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (streak > 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade700),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$streak',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (habit.category.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  habit.category,
                                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? color : Colors.transparent,
                        border: completed
                            ? null
                            : Border.all(color: color, width: 2),
                      ),
                      child: completed
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
