import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _exportData(BuildContext context) {
    final provider = context.read<HabitProvider>();
    final data = provider.getAllData();
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos copiados al portapapeles')),
    );
  }

  void _importData(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay datos en el portapapeles')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos'),
        content: const Text(
          'Esto reemplazará todos tus datos actuales. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final provider = context.read<HabitProvider>();
    final success = await provider.importAllData(data.text!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Datos importados correctamente'
              : 'Error: formato de datos inválido'),
        ),
      );
    }
  }

  void _clearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se eliminarán todos los hábitos y registros. Esta acción no se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final provider = context.read<HabitProvider>();
    await provider.clearAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los datos han sido eliminados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // General
              const _SectionHeader(title: 'General'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Inicio de semana'),
                      trailing: DropdownButton<String>(
                        value: provider.startOfWeek,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'Lunes', child: Text('Lunes')),
                          DropdownMenuItem(value: 'Domingo', child: Text('Domingo')),
                        ],
                        onChanged: (v) {
                          if (v != null) provider.setStartOfWeek(v);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificaciones'),
                      subtitle: const Text('Recordatorios diarios'),
                      value: false,
                      onChanged: (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Función disponible próximamente')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data
              const _SectionHeader(title: 'Datos'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_rounded),
                      title: const Text('Exportar datos'),
                      subtitle: const Text('Copiar JSON al portapapeles'),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: const Text('Importar datos'),
                      subtitle: const Text('Desde el portapapeles'),
                      onTap: () => _importData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
                      title: Text('Borrar todos los datos',
                          style: TextStyle(color: Colors.red.shade400)),
                      onTap: () => _clearData(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About
              const _SectionHeader(title: 'Acerca de'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Habit Tracker'),
                      subtitle: Text('Versión 1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Tecnología'),
                      subtitle: const Text('Flutter + Provider + Material 3'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Almacenamiento'),
                      subtitle: Text(
                        '${provider.habits.length} hábitos, ${provider.totalCompletionsAll} completados',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
