import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'login_screen.dart';

// ---------- Modelos ----------

enum Status { pending, pass, fail, na }

class AuditItem {
  AuditItem(this.title);
  String title;
  Status status = Status.pending;
  String note = '';
}

class Audit {
  Audit(this.name, this.items) : date = DateTime.now();
  String name;
  DateTime date;
  List<AuditItem> items;

  int get answered => items.where((i) => i.status != Status.pending).length;
  double get progress => items.isEmpty ? 0 : answered / items.length;

  /// Cumplimiento = cumple / (cumple + no cumple). Ignora N/A y pendientes.
  double get score {
    final p = items.where((i) => i.status == Status.pass).length;
    final f = items.where((i) => i.status == Status.fail).length;
    return (p + f) == 0 ? 0 : p / (p + f);
  }
}

List<AuditItem> defaultTemplate() => [
      AuditItem('Documentación vigente y disponible'),
      AuditItem('Áreas limpias y ordenadas'),
      AuditItem('Equipos con mantenimiento al día'),
      AuditItem('Personal capacitado'),
      AuditItem('Registros completos y firmados'),
    ];

// ---------- Lista de auditorías ----------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Audit> audits = [];

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _newAudit() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva auditoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Crear')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => audits.insert(0, Audit(name, defaultTemplate())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Tool'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: audits.isEmpty
          ? const Center(child: Text('Sin auditorías. Crea la primera con +'))
          : ListView.builder(
              itemCount: audits.length,
              itemBuilder: (_, i) {
                final a = audits[i];
                return Dismissible(
                  key: ObjectKey(a),
                  background: Container(color: AppColors.fail),
                  onDismissed: (_) => setState(() => audits.removeAt(i)),
                  child: ListTile(
                    title: Text(a.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(value: a.progress),
                    ),
                    trailing: Text('${(a.score * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AuditPage(audit: a)),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newAudit,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------- Checklist de una auditoría ----------

class AuditPage extends StatefulWidget {
  const AuditPage({super.key, required this.audit});
  final Audit audit;

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  Audit get a => widget.audit;

  Future<void> _addItem() async {
    final ctrl = TextEditingController();
    final t = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo punto'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (t == null || t.isEmpty) return;
    setState(() => a.items.add(AuditItem(t)));
  }

  Future<void> _editNote(AuditItem item) async {
    final ctrl = TextEditingController(text: item.note);
    final n = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Observaciones'),
        content: TextField(controller: ctrl, maxLines: 4, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (n != null) setState(() => item.note = n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${(a.score * 100).round()}% cumple',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: a.progress,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: a.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = a.items[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(item.title,
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    IconButton(
                      tooltip: 'Observaciones',
                      icon: Icon(item.note.isEmpty
                          ? Icons.note_add_outlined
                          : Icons.sticky_note_2),
                      onPressed: () => _editNote(item),
                    ),
                  ]),
                  if (item.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(item.note,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  SegmentedButton<Status>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: Status.pass, label: Text('Cumple')),
                      ButtonSegment(value: Status.fail, label: Text('No')),
                      ButtonSegment(value: Status.na, label: Text('N/A')),
                    ],
                    selected: item.status == Status.pending
                        ? <Status>{}
                        : {item.status},
                    onSelectionChanged: (s) => setState(() =>
                        item.status = s.isEmpty ? Status.pending : s.first),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Punto'),
      ),
    );
  }
}
