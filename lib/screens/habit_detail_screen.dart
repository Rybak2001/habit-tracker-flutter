import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

const _kColors = [
  '#6C63FF', '#FF6B6B', '#4ECDC4', '#FFD93D', '#FF8C42',
  '#A8E6CF', '#DDA0DD', '#87CEEB', '#F08080', '#98D8C8',
  '#FF69B4', '#20B2AA',
];

class HabitDetailScreen extends StatefulWidget {
  final String? habitId;

  const HabitDetailScreen({super.key, this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _color = _kColors[0];
  int _targetDays = 7;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      _isEditing = true;
      final provider = context.read<HabitProvider>();
      final habit = provider.getHabit(widget.habitId!);
      if (habit != null) {
        _nameController.text = habit.name;
        _descController.text = habit.description;
        _color = habit.color;
        _targetDays = habit.targetDays;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    final provider = context.read<HabitProvider>();

    if (_isEditing) {
      final existing = provider.getHabit(widget.habitId!);
      if (existing != null) {
        provider.updateHabit(existing.copyWith(
          name: name,
          description: _descController.text.trim(),
          color: _color,
          targetDays: _targetDays,
        ));
      }
    } else {
      provider.addHabit(Habit(
        name: name,
        description: _descController.text.trim(),
        color: _color,
        targetDays: _targetDays,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hexToColor(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Habit Name *'),
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'e.g., Exercise, Read, Meditate',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _sectionTitle('Description'),
            TextField(
              controller: _descController,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional description...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _sectionTitle('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _kColors.map((c) {
                final isSelected = c == _color;
                final clr = _hexToColor(c);
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: clr,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black87, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Target Days per Week'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final day = i + 1;
                final isSelected = day == _targetDays;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _targetDays = day),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _targetDays == 7
                    ? 'Every day'
                    : '$_targetDays day${_targetDays > 1 ? 's' : ''} per week',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Update Habit' : 'Create Habit',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
