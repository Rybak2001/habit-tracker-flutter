import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'habit_history_screen.dart';

const _kColors = [
  '#6C63FF', '#FF6B6B', '#4ECDC4', '#FFD93D', '#FF8C42',
  '#A8E6CF', '#DDA0DD', '#87CEEB', '#F08080', '#98D8C8',
  '#FF69B4', '#20B2AA',
];

class _HabitTemplate {
  final String name;
  final String color;
  final int targetDays;
  final String category;
  final IconData icon;

  const _HabitTemplate({
    required this.name,
    required this.color,
    required this.targetDays,
    required this.category,
    required this.icon,
  });
}

const _templates = [
  _HabitTemplate(name: 'Ejercicio', color: '#FF6B6B', targetDays: 7, category: 'Ejercicio', icon: Icons.fitness_center),
  _HabitTemplate(name: 'Leer', color: '#87CEEB', targetDays: 5, category: 'Educación', icon: Icons.menu_book),
  _HabitTemplate(name: 'Meditar', color: '#DDA0DD', targetDays: 7, category: 'Bienestar', icon: Icons.self_improvement),
  _HabitTemplate(name: 'Beber agua', color: '#4ECDC4', targetDays: 7, category: 'Salud', icon: Icons.water_drop),
  _HabitTemplate(name: 'Estudiar', color: '#A8E6CF', targetDays: 5, category: 'Educación', icon: Icons.school),
  _HabitTemplate(name: 'Dormir bien', color: '#6C63FF', targetDays: 7, category: 'Salud', icon: Icons.bedtime),
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
  String _category = '';
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
        _category = habit.category;
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

  void _applyTemplate(_HabitTemplate t) {
    setState(() {
      _nameController.text = t.name;
      _color = t.color;
      _targetDays = t.targetDays;
      _category = t.category;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
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
          category: _category,
        ));
      }
    } else {
      provider.addHabit(Habit(
        name: name,
        description: _descController.text.trim(),
        color: _color,
        targetDays: _targetDays,
        category: _category,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hexToColor(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Hábito' : 'Nuevo Hábito'),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Historial',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitHistoryScreen(habitId: widget.habitId!),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Templates (only when creating new)
            if (!_isEditing) ...[
              _sectionTitle('Plantillas Rápidas'),
              const SizedBox(height: 4),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _templates.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(t.icon, size: 18),
                      label: Text(t.name),
                      onPressed: () => _applyTemplate(t),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],

            _sectionTitle('Nombre del Hábito *'),
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'Ej: Ejercicio, Leer, Meditar',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _sectionTitle('Descripción'),
            TextField(
              controller: _descController,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Descripción opcional...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Category selector
            _sectionTitle('Categoría'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CATEGORIES.map((cat) {
                final selected = _category == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _category = selected ? '' : cat;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

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
            _sectionTitle('Días Objetivo por Semana'),
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
                    ? 'Todos los días'
                    : '$_targetDays día${_targetDays > 1 ? 's' : ''} por semana',
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
                  _isEditing ? 'Actualizar Hábito' : 'Crear Hábito',
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
