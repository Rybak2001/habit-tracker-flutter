import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<Completion> _completions = [];

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Completion> get completions => List.unmodifiable(_completions);

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  String get _today => _dateFmt.format(DateTime.now());

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
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'habits', jsonEncode(_habits.map((h) => h.toJson()).toList()));
    await prefs.setString(
        'completions', jsonEncode(_completions.map((c) => c.toJson()).toList()));
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

  Future<bool> toggleCompletion(String habitId) async {
    final idx = _completions.indexWhere(
        (c) => c.habitId == habitId && c.date == _today);

    if (idx != -1) {
      _completions.removeAt(idx);
      notifyListeners();
      await _save();
      return false;
    } else {
      _completions.add(Completion(habitId: habitId, date: _today));
      notifyListeners();
      await _save();
      return true;
    }
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
}
