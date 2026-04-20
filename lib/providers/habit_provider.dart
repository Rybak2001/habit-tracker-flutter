import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

enum HabitSort { alphabetical, streak, creationDate, completionRate }

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<Completion> _completions = [];
  String _categoryFilter = '';
  HabitSort _sort = HabitSort.creationDate;
  String _searchQuery = '';
  String _startOfWeek = 'Lunes'; // Lunes or Domingo

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Completion> get completions => List.unmodifiable(_completions);
  String get categoryFilter => _categoryFilter;
  HabitSort get currentSort => _sort;
  String get searchQuery => _searchQuery;
  String get startOfWeek => _startOfWeek;

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  String get _today => _dateFmt.format(DateTime.now());

  // ─── Filtered & Sorted habits ────────────────────────

  List<Habit> get filteredHabits {
    var list = List<Habit>.from(_habits);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((h) =>
          h.name.toLowerCase().contains(q) ||
          h.description.toLowerCase().contains(q)).toList();
    }

    // Category filter
    if (_categoryFilter.isNotEmpty) {
      list = list.where((h) => h.category == _categoryFilter).toList();
    }

    // Sort
    switch (_sort) {
      case HabitSort.alphabetical:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case HabitSort.streak:
        list.sort((a, b) => getCurrentStreak(b.id).compareTo(getCurrentStreak(a.id)));
        break;
      case HabitSort.creationDate:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HabitSort.completionRate:
        list.sort((a, b) => _completionRate(b.id).compareTo(_completionRate(a.id)));
        break;
    }

    return list;
  }

  double _completionRate(String habitId) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;
    final total = getTotalCompletions(habitId);
    final daysSinceCreation = DateTime.now().difference(habit.createdAt).inDays + 1;
    if (daysSinceCreation <= 0) return 0;
    return total / daysSinceCreation;
  }

  void setCategoryFilter(String category) {
    _categoryFilter = _categoryFilter == category ? '' : category;
    notifyListeners();
  }

  void setSort(HabitSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── Settings ────────────────────────────────────────

  void setStartOfWeek(String value) {
    _startOfWeek = value;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('startOfWeek', _startOfWeek);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _startOfWeek = prefs.getString('startOfWeek') ?? 'Lunes';
  }

  // ─── Persistence ──────────────────────────────────────

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString('habits');
    final compsJson = prefs.getString('completions');

    if (habitsJson != null) {
      _habits = (jsonDecode(habitsJson) as List)
          .map((e) => Habit.fromJson(e))
          .toList();
    }
    if (compsJson != null) {
      _completions = (jsonDecode(compsJson) as List)
          .map((e) => Completion.fromJson(e))
          .toList();
    }
    await _loadSettings();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'habits', jsonEncode(_habits.map((h) => h.toJson()).toList()));
    await prefs.setString(
        'completions', jsonEncode(_completions.map((c) => c.toJson()).toList()));
  }

  // ─── Data Export / Import / Clear ────────────────────

  String getAllData() {
    return jsonEncode({
      'habits': _habits.map((h) => h.toJson()).toList(),
      'completions': _completions.map((c) => c.toJson()).toList(),
    });
  }

  Future<bool> importAllData(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final habitsList = (data['habits'] as List?)
          ?.map((e) => Habit.fromJson(e))
          .toList() ?? [];
      final compsList = (data['completions'] as List?)
          ?.map((e) => Completion.fromJson(e))
          .toList() ?? [];
      _habits = habitsList;
      _completions = compsList;
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    _habits.clear();
    _completions.clear();
    notifyListeners();
    await _save();
  }

  // ─── Habits CRUD ─────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    notifyListeners();
    await _save();
  }

  Future<void> updateHabit(Habit habit) async {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      _habits[idx] = habit;
      notifyListeners();
      await _save();
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _completions.removeWhere((c) => c.habitId == id);
    notifyListeners();
    await _save();
  }

  Habit? getHabit(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Completions ─────────────────────────────────────

  bool isCompletedToday(String habitId) {
    return _completions.any((c) => c.habitId == habitId && c.date == _today);
  }

  Future<bool> toggleCompletion(String habitId, {String? note}) async {
    final idx = _completions.indexWhere(
        (c) => c.habitId == habitId && c.date == _today);

    if (idx != -1) {
      _completions.removeAt(idx);
      notifyListeners();
      await _save();
      return false;
    } else {
      _completions.add(Completion(habitId: habitId, date: _today, note: note));
      notifyListeners();
      await _save();
      return true;
    }
  }

  List<Completion> getCompletionsForDate(String date) {
    return _completions.where((c) => c.date == date).toList();
  }

  List<Completion> getCompletionsForHabit(String habitId) {
    return _completions.where((c) => c.habitId == habitId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // ─── Stats ───────────────────────────────────────────

  int getCurrentStreak(String habitId) {
    final dates = _completions
        .where((c) => c.habitId == habitId)
        .map((c) => c.date)
        .toSet();

    int streak = 0;
    var current = DateTime.now();

    while (true) {
      final dateStr = _dateFmt.format(current);
      if (dates.contains(dateStr)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int getTotalCompletions(String habitId) {
    return _completions.where((c) => c.habitId == habitId).length;
  }

  int get totalCompletionsAll => _completions.length;

  int get completedTodayCount {
    return _habits.where((h) => isCompletedToday(h.id)).length;
  }

  int getWeekCompletions(String habitId) {
    final now = DateTime.now();
    int startDay = _startOfWeek == 'Lunes' ? DateTime.monday : DateTime.sunday;
    int diff = (now.weekday - startDay + 7) % 7;
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
    return _completions.where((c) {
      if (c.habitId != habitId) return false;
      final d = DateTime.tryParse(c.date);
      if (d == null) return false;
      return !d.isBefore(weekStart) && !d.isAfter(now);
    }).length;
  }

  // Weekly completions count per day (last 7 days)
  List<int> getWeeklyCompletionCounts() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dateStr = _dateFmt.format(day);
      return _completions.where((c) => c.date == dateStr).length;
    });
  }

  // Monthly completions count per day (last 30 days)
  List<int> getMonthlyCompletionCounts() {
    final now = DateTime.now();
    return List.generate(30, (i) {
      final day = now.subtract(Duration(days: 29 - i));
      final dateStr = _dateFmt.format(day);
      return _completions.where((c) => c.date == dateStr).length;
    });
  }

  // Category breakdown: map of category -> total completions
  Map<String, int> getCategoryBreakdown() {
    final map = <String, int>{};
    for (final h in _habits) {
      final cat = h.category.isEmpty ? 'Sin categoría' : h.category;
      final count = getTotalCompletions(h.id);
      map[cat] = (map[cat] ?? 0) + count;
    }
    return map;
  }

  // Best day of week
  String getBestDayOfWeek() {
    final dayCounts = <int, int>{};
    for (final c in _completions) {
      final d = DateTime.tryParse(c.date);
      if (d != null) {
        dayCounts[d.weekday] = (dayCounts[d.weekday] ?? 0) + 1;
      }
    }
    if (dayCounts.isEmpty) return '-';
    final best = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    const dayNames = {
      1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves',
      5: 'Viernes', 6: 'Sábado', 7: 'Domingo',
    };
    return dayNames[best.key] ?? '-';
  }

  // ─── Achievements ────────────────────────────────────

  int get longestStreakEver {
    int maxStreak = 0;
    for (final h in _habits) {
      final dates = _completions
          .where((c) => c.habitId == h.id)
          .map((c) => c.date)
          .toSet()
          .toList()
        ..sort();
      int streak = 0;
      for (int i = 0; i < dates.length; i++) {
        if (i == 0) {
          streak = 1;
        } else {
          final prev = DateTime.parse(dates[i - 1]);
          final curr = DateTime.parse(dates[i]);
          if (curr.difference(prev).inDays == 1) {
            streak++;
          } else {
            streak = 1;
          }
        }
        if (streak > maxStreak) maxStreak = streak;
      }
    }
    return maxStreak;
  }

  int get maxCurrentStreak {
    int max = 0;
    for (final h in _habits) {
      final s = getCurrentStreak(h.id);
      if (s > max) max = s;
    }
    return max;
  }

  bool get allCompletedToday {
    if (_habits.isEmpty) return false;
    return _habits.every((h) => isCompletedToday(h.id));
  }
}
