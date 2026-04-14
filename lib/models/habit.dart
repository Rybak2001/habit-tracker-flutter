import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Habit {
  final String id;
  final String name;
  final String description;
  final String color;
  final int targetDays;
  final DateTime createdAt;

  Habit({
    String? id,
    required this.name,
    this.description = '',
    this.color = '#6C63FF',
    this.targetDays = 7,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Habit copyWith({
    String? name,
    String? description,
    String? color,
    int? targetDays,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      targetDays: targetDays ?? this.targetDays,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color': color,
        'targetDays': targetDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        color: json['color'] ?? '#6C63FF',
        targetDays: json['targetDays'] ?? 7,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Completion {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final DateTime completedAt;

  Completion({
    String? id,
    required this.habitId,
    required this.date,
    DateTime? completedAt,
  })  : id = id ?? _uuid.v4(),
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date,
        'completedAt': completedAt.toIso8601String(),
      };

  factory Completion.fromJson(Map<String, dynamic> json) => Completion(
        id: json['id'],
        habitId: json['habitId'],
        date: json['date'],
        completedAt: DateTime.parse(json['completedAt']),
      );
}
