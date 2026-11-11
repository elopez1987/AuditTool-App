// Pantalla para pruebas modulo de verificación
import 'dart:io';

import 'package:audit_tool/auth/login_screen.dart';
import 'package:audit_tool/auth/profile_screen.dart';
import 'package:audit_tool/auth/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data_1.dart';
import '../services/scanner_service.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const kBlue = Color(0xFF0D3275),
    kBlueDark = Color(0xFF082150),
    kRed = Color(0xFFDC2626);
const s50 = Color(0xFFF8FAFC),
    s100 = Color(0xFFF1F5F9),
    s200 = Color(0xFFE2E8F0),
    s300 = Color(0xFFCBD5E1);
const s400 = Color(0xFF94A3B8),
    s500 = Color(0xFF64748B),
    s600 = Color(0xFF475569),
    s700 = Color(0xFF334155);
const s800 = Color(0xFF1E293B),
    s900 = Color(0xFF0F172A),
    blue50 = Color(0xFFEFF6FF),
    blue200 = Color(0xFFBFDBFE);
const kAmber = Color(0xFFD97706), kGreen = Color(0xFF059669);

const motivosDef = [
  'Advertencia / Desviación de Temperatura',
  'Faltante de Origen',
  'Producto Dañado / Mermado',
  'Error de Despacho en Rampa',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadData(); // carga vales, capturas y aprobaciones guardados en el dispositivo
  runApp(const MockupApp1());
}

class MockupApp1 extends StatelessWidget {
  const MockupApp1({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Audit Tools',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: s50,
      colorScheme: ColorScheme.fromSeed(seedColor: kBlue, primary: kBlue),
    ),
    home: const ValeScreen(),
  );
}

// ───────── Utilidades UI ─────────
void toast(
  BuildContext c,
  String title,
  String msg,
  IconData icon,
  Color color,
) {
  ScaffoldMessenger.of(c)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s800,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(msg, style: const TextStyle(fontSize: 11, color: s300)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);
    Path p(List<List<double>> pts) {
      final path = Path()..moveTo(pts[0][0], pts[0][1]);
      for (final q in pts.skip(1)) {
        path.lineTo(q[0], q[1]);
      }
      return path..close();
    }

    canvas.drawPath(
      p([
        [100, 20],
        [150, 180],
        [115, 180],
        [100, 125],
        [75, 125],
        [85, 90],
        [100, 90],
        [100, 60],
        [50, 180],
        [15, 180],
      ]),
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      p([
        [68, 128],
        [92, 165],
        [148, 82],
        [128, 70],
        [89, 128],
        [78, 112],
      ]),
      Paint()..color = kRed,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/* class AppHeader extends StatelessWidget {
  const AppHeader({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: kBlue,
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + 10,
      16,
      12,
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: CustomPaint(painter: LogoPainter()),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUDIT TOOLS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: .5,
                ),
              ),
              Text(
                'Módulo de Verificación',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _circle(
          const Icon(Icons.notifications_none, color: Colors.white, size: 16),
          Colors.white.withOpacity(.1),
        ),
        const SizedBox(width: 8),
        _circle(
          const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          kRed,
        ),
      ],
    ),
  );
  Widget _circle(Widget child, Color bg) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: child,
  );
} */
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  Future<void> _logout(BuildContext context) async {
    await SessionStore.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMaster = SessionStore.isMaster;

    return Container(
      color: kBlue,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: CustomPaint(painter: LogoPainter()),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUDIT TOOLS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: .5,
                  ),
                ),
                Text(
                  'Módulo de Verificación',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Perfil: solo si NO es auditor.master
          if (!isMaster)
            IconButton(
              tooltip: 'Mi perfil',
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),

          // Cerrar sesión: para todos
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

InputDecoration deco({
  String? hint,
  String? error,
  Widget? prefix,
  Widget? suffix,
  String? suffixText,
  bool dense = false,
}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(dense ? 8 : 12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: s400, fontSize: 13),
    errorText: error,
    errorMaxLines: 2,
    prefixIcon: prefix,
    suffixIcon: suffix,
    suffixText: suffixText,
    filled: true,
    fillColor: s50,
    isDense: dense,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: dense ? 10 : 14,
    ),
    border: b(s300),
    enabledBorder: b(s300),
    focusedBorder: b(kBlue, 2),
    errorBorder: b(kRed, 1.5),
    focusedErrorBorder: b(kRed, 2),
  );
}

Widget card({
  required Widget child,
  EdgeInsets pad = const EdgeInsets.all(12),
  bool accent = false,
}) {
  final box = Container(
    width: double.infinity,
    padding: accent
        ? EdgeInsets.fromLTRB(pad.left + 6, pad.top, pad.right, pad.bottom)
        : pad,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: s200,
      ), // borde uniforme (requisito de Flutter si hay borderRadius)
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
  if (!accent) return box;
  return Stack(
    children: [
      box,
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(14),
          ),
          child: Container(width: 5, color: kBlue),
        ),
      ),
    ],
  );
}

Widget label(String t, {bool req = false, double size = 12}) => Text.rich(
  TextSpan(
    text: t,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: s700),
    children: [
      if (req)
        const TextSpan(
          text: ' *',
          style: TextStyle(color: kRed),
        ),
    ],
  ),
);

// ───────── PANTALLA 1: Búsqueda de vale ─────────
class ValeScreen extends StatefulWidget {
  const ValeScreen({super.key});
  @override
  State<ValeScreen> createState() => _ValeScreenState();
}

class _ValeScreenState extends State<ValeScreen> {
  final _c = TextEditingController();
  String? _err;

  void _search() {
    final v = _c.text.trim().toUpperCase();
    String? e;
    if (v.isEmpty) {
      e = 'Ingresa el número de vale o viaje.';
    } else if (findTrip(v) == null) {
      e = 'El vale $v no existe. Primero planea y guarda el vale.';
    }
    setState(() => _err = e);
    if (e != null) {
      toast(
        context,
        'Atención',
        'Revisa el código de vale.',
        Icons.warning_amber_rounded,
        kAmber,
      );
      return;
    }
    toast(
      context,
      'Viaje Encontrado',
      'Accediendo a la pantalla de captura...',
      Icons.check,
      kBlue,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaptureScreen(trip: findTrip(v)!)),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kBlue, Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingreso de Operación',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ingresa el número de vale para iniciar la auditoría de forma inmediata.',
                          style: TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  card(
                    pad: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('INGRESAR VALE / VIAJE', req: true),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _c,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          onChanged: (_) =>
                              _err == null ? null : setState(() => _err = null),
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (o, n) => n.copyWith(text: n.text.toUpperCase()),
                            ),
                            LengthLimitingTextInputFormatter(40),
                          ],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: deco(
                            hint: 'Ej. VALE-8891',
                            error: _err,
                            prefix: const Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: s400,
                            ),
                            suffix: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                size: 18,
                                color: s400,
                              ),
                              onPressed: () => setState(() {
                                _c.clear();
                                _err = null;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kBlue,
                              side: const BorderSide(color: blue200),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PlanValeScreen(),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.playlist_add),
                            label: const Text(
                              'PLANEAR / CREAR VALE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kBlue,
                              side: const BorderSide(color: blue200),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ValesDisponiblesScreen(),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.view_list_outlined),
                            label: const Text(
                              'VER VALES DISPONIBLES',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _search,
                            icon: const Icon(Icons.bolt, color: Colors.amber),
                            label: const Text(
                              'BUSCAR VIAJE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Audit Tools Mobile - TRAXIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        color: s400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ───────── LISTADO: Vales disponibles y pendientes ─────────
class ValesDisponiblesScreen extends StatefulWidget {
  const ValesDisponiblesScreen({super.key});
  @override
  State<ValesDisponiblesScreen> createState() => _ValesDisponiblesScreenState();
}

class _ValesDisponiblesScreenState extends State<ValesDisponiblesScreen> {
  final _search = TextEditingController();
  String _filter = 'TODOS';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _capturedCount(Trip trip) => records
      .where((r) => r.vale.toUpperCase() == trip.vale.toUpperCase() && !r.isNc)
      .length;

  int _capturedProductCount(Trip trip) => records
      .where((r) => r.vale.toUpperCase() == trip.vale.toUpperCase() && !r.isNc)
      .map((r) => r.sku)
      .toSet()
      .length;

  String _statusOf(Trip t) {
    if (isApproved(t.vale)) return 'APROBADO';
    return _capturedCount(t) == 0 && !hasRecords(t.vale)
        ? 'DISPONIBLE'
        : 'EN PROCESO';
  }

  Future<void> _edit(Trip trip) async {
    if (hasRecords(trip.vale)) {
      toast(
        context,
        'No se puede editar',
        'Este vale ya tiene capturas. Elimínalo y vuelve a planearlo si necesitas cambiar cantidades.',
        Icons.lock_outline,
        kAmber,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanValeScreen(editing: trip)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(Trip trip) async {
    final n = records
        .where((r) => r.vale.toUpperCase() == trip.vale.toUpperCase())
        .length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar planeación'),
        content: Text(
          n == 0
              ? '¿Seguro que deseas eliminar el vale ${trip.vale}? Esta acción no se puede deshacer.'
              : '¿Seguro que deseas eliminar el vale ${trip.vale}? Se borrarán también sus $n registro(s) de captura y NC. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await deleteTrip(trip.vale);
    if (!mounted) return;
    toast(
      context,
      'Vale eliminado',
      '${trip.vale} fue eliminado.',
      Icons.delete_outline,
      kRed,
    );
    setState(() {});
  }

  Widget _status(String value) {
    final inProgress = value == 'EN PROCESO';
    final approved = value == 'APROBADO';
    final color = approved ? kBlue : (inProgress ? kAmber : kGreen);
    final bg = approved
        ? blue50
        : (inProgress ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            approved
                ? Icons.verified_outlined
                : (inProgress
                      ? Icons.pending_outlined
                      : Icons.check_circle_outline),
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toUpperCase();
    final all = plannedTrips.toList()..sort((a, b) => a.vale.compareTo(b.vale));
    final available = all.where((t) => _statusOf(t) == 'DISPONIBLE').length;
    final inProgress = all.where((t) => _statusOf(t) == 'EN PROCESO').length;
    final approvedCount = all.where((t) => _statusOf(t) == 'APROBADO').length;
    final filtered = all.where((trip) {
      final status = _statusOf(trip);
      final matchesFilter = _filter == 'TODOS' || status == _filter;
      final matchesSearch =
          query.isEmpty ||
          trip.vale.toUpperCase().contains(query) ||
          trip.ruta.toUpperCase().contains(query) ||
          trip.operador.toUpperCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Vales disponibles',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONSULTA DE VALES',
                    style: TextStyle(
                      color: kBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecciona un vale para continuar con su auditoría.',
                    style: TextStyle(color: s500, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'TOTAL',
                          all.length.toString(),
                          Icons.receipt_long,
                          kBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          'DISPONIBLES',
                          available.toString(),
                          Icons.play_circle_outline,
                          kGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          'EN PROCESO',
                          inProgress.toString(),
                          Icons.pending_actions,
                          kAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: deco(
                      hint: 'Buscar vale, ruta u operador',
                      prefix: const Icon(Icons.search, color: s400, size: 19),
                      suffix: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('TODOS', 'Todos (${all.length})'),
                        const SizedBox(width: 7),
                        _filterChip('DISPONIBLE', 'Disponibles ($available)'),
                        const SizedBox(width: 7),
                        _filterChip('EN PROCESO', 'En proceso ($inProgress)'),
                        const SizedBox(width: 7),
                        _filterChip('APROBADO', 'Aprobados ($approvedCount)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              all.isEmpty
                                  ? Icons.inbox_outlined
                                  : Icons.search_off,
                              size: 48,
                              color: s300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              all.isEmpty
                                  ? 'Aún no hay vales planeados'
                                  : 'No se encontraron vales',
                              style: const TextStyle(
                                color: s700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              all.isEmpty
                                  ? 'Crea una planeación para que aparezca en este listado.'
                                  : 'Prueba con otro texto o cambia el filtro.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: s500, fontSize: 12),
                            ),
                            if (all.isEmpty) ...[
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PlanValeScreen(),
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('PLANEAR VALE'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final trip = filtered[index];
                        final count = _capturedCount(trip);
                        final status = _statusOf(trip);
                        final auditedProducts = _capturedProductCount(trip);
                        final progress = trip.plannedProducts.isEmpty
                            ? 0.0
                            : (auditedProducts / trip.plannedProducts.length)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CaptureScreen(trip: trip),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: s200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: blue50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long,
                                          color: kBlue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.vale,
                                              style: const TextStyle(
                                                color: s900,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              trip.ruta,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: s500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _status(status),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: s500,
                                        ),
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            _edit(trip);
                                          } else if (v == 'reconcile') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ReconciliationScreen(
                                                      trip: trip,
                                                    ),
                                              ),
                                            ).then((_) => setState(() {}));
                                          } else {
                                            _delete(trip);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Editar planeación'),
                                          ),

                                          PopupMenuItem(
                                            value: 'reconcile',
                                            child: Text('Conciliar / Aprobar'), // <--- Opción segura para administradores
                                          ),

                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: s400,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          trip.operador,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: s600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 14,
                                        color: s400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trip.plannedProducts.length} productos',
                                        style: const TextStyle(
                                          color: s600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 11),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        count == 0
                                            ? 'Sin capturas registradas'
                                            : '$count registro(s) válido(s) • $auditedProducts/${trip.plannedProducts.length} productos',
                                        style: const TextStyle(
                                          color: s500,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const Text(
                                        'ABRIR VALE  ›',
                                        style: TextStyle(
                                          color: kBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: s100,
                                      color: kBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: s200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: s900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: s500,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _filterChip(String value, String labelText) => ChoiceChip(
    label: Text(
      labelText,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _filter == value ? Colors.white : s600,
      ),
    ),
    selected: _filter == value,
    selectedColor: kBlue,
    backgroundColor: Colors.white,
    side: BorderSide(color: _filter == value ? kBlue : s200),
    onSelected: (_) => setState(() => _filter = value),
    visualDensity: VisualDensity.compact,
  );
}

// ───────── PANTALLA 2: Captura unificada ─────────
class CaptureScreen extends StatefulWidget {
  final Trip trip;
  const CaptureScreen({super.key, required this.trip});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _temp = TextEditingController(text: '3.5');
  final _sku = TextEditingController();
  final _qty = TextEditingController();
  final _skuF = FocusNode(), _qtyF = FocusNode();
  String _mode = 'ROTATIVA';
  bool _scanMode = true, _photo = false;
  Product? _product;
  bool _isExtra = false;
  String? _motivo, _eTemp, _eSku, _eQty, _eMotivo;

  double? get _t => double.tryParse(_temp.text.trim().replaceAll(',', '.'));

  // ── Validaciones ──
  String? _vTemp() {
    final t = _temp.text.trim();
    if (t.isEmpty) return 'Ingresa la temperatura.';
    if (_t == null) return 'Valor no numérico (Ej. 3.5).';
    if (_t! < -30 || _t! > 40)
      return 'Fuera de rango (-30 a 40 °C). Verifica la lectura.';
    return null;
  }

  String? _vSku() {
    final s = _sku.text.trim().toUpperCase();
    if (s.isEmpty)
      return _scanMode
          ? 'Escanea el UPC o SKU del producto.'
          : 'Digita el UPC o SKU del producto.';
    return null; // un producto fuera del vale se acepta y se registra como extra (NC)
  }

  String? _vQty() {
    if (_qty.text.isEmpty) return 'Ingresa la cantidad.';
    final n = int.tryParse(_qty.text);
    if (n == null || n < 1) return 'Debe ser un número entero mayor a 0.';
    if (n > 9999)
      return 'Máximo 9,999 ${(_product?.unit ?? 'unidades').toLowerCase()} por registro.';
    return null;
  }

  void _lookup() {
    final e = _vSku();
    Product? p;
    var extra = false;
    if (e == null) {
      final code = _sku.text.trim().toUpperCase();
      final planned = widget.trip.plannedProducts
          .where((x) => x.product.matches(code))
          .toList();
      if (planned.isNotEmpty) {
        p = planned.first.product;
      } else {
        extra = true;
        p =
            findProduct(code) ??
            Product(code, code, 'Producto no planeado ($code)', 'Cajas');
      }
    }
    setState(() {
      _eSku = e;
      _product = p;
      _isExtra = extra;
    });
    if (e == null) {
      if (extra) {
        toast(
          context,
          'Producto fuera del vale',
          'Se registrará como extra en la NC.',
          Icons.warning_amber_rounded,
          kAmber,
        );
      }
      _qtyF.requestFocus();
    }
  }

  // Toque = cámara real. Mantener presionado = simulador con productos demo.
  Future<void> _scan() async {
    try {
      final code = await ScannerService.scan();
      if (code == null) return; // cancelado
      _sku.text = code;
      _lookup();
      final ok = _eSku == null;
      toast(
        context,
        ok ? 'SKU Escaneado' : 'Código no reconocido',
        'Código: $code',
        ok ? Icons.qr_code_2 : Icons.warning_amber_rounded,
        ok ? kGreen : kAmber,
      );
    } catch (_) {
      toast(
        context,
        'Cámara no disponible',
        'Revisa el permiso de cámara en Ajustes.',
        Icons.no_photography,
        kRed,
      );
    }
  }

  Future<void> _scanDemo() async {
    final p = await showDialog<Product>(
      context: context,
      builder: (_) => const ScannerDialog(),
    );
    if (p == null) return;
    _sku.text = p.upc;
    _lookup();
    toast(
      context,
      'SKU Escaneado (demo)',
      'Código: ${p.upc}',
      Icons.qr_code_2,
      kGreen,
    );
  }

  // Foto con cámara real
  final _picker = ImagePicker();
  File? _photoFile;
  Future<void> _takePhoto() async {
    try {
      final st = await Permission.camera.request();
      if (!st.isGranted) {
        toast(
          context,
          'Permiso de cámara',
          'Activa el permiso de cámara para tomar la foto.',
          Icons.no_photography,
          kRed,
        );
        return;
      }
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (x == null) return;
      setState(() {
        _photoFile = File(x.path);
        _photo = true;
      });
      toast(
        context,
        'Fotografía Adjuntada',
        'Evidencia fotográfica cargada.',
        Icons.photo_camera,
        kGreen,
      );
    } catch (_) {
      toast(
        context,
        'Cámara no disponible',
        'No se pudo abrir la cámara.',
        Icons.no_photography,
        kRed,
      );
    }
  }

  void _clear({bool silent = false}) {
    setState(() {
      _sku.clear();
      _qty.clear();
      _product = null;
      _isExtra = false;
      _motivo = null;
      _photo = false;
      _photoFile = null;
      _eSku = _eQty = _eMotivo = null;
    });
    if (!silent)
      toast(
        context,
        'Formulario Limpio',
        'Campos restablecidos',
        Icons.cleaning_services,
        s700,
      );
  }

  Future<void> _save() async {
    if (isApproved(widget.trip.vale)) {
      toast(
        context,
        'Vale aprobado',
        'Este vale ya fue aprobado y no admite más capturas.',
        Icons.lock_outline,
        kAmber,
      );
      return;
    }
    setState(() {
      _eTemp = _vTemp();
      _eSku = _vSku();
      _eQty = _vQty();
      _eMotivo = (_mode == 'DEFINITIVA' && _motivo == null)
          ? 'Selecciona un motivo para auditoría definitiva.'
          : null;
    });
    if (_eTemp != null || _eSku != null || _eQty != null || _eMotivo != null) {
      toast(
        context,
        _eMotivo != null && _eSku == null && _eQty == null && _eTemp == null
            ? 'Motivo Requerido'
            : 'Campos Incompletos',
        'Corrige los campos marcados en rojo.',
        Icons.warning_amber_rounded,
        _eMotivo != null ? kRed : kAmber,
      );
      return;
    }
    final code = _sku.text.trim().toUpperCase();
    final vale = widget.trip.vale;
    final entered = int.parse(_qty.text);
    final matches = widget.trip.plannedProducts
        .where((x) => x.product.matches(code))
        .toList();

    // 1) Producto fuera del vale -> todo va como extra a la NC (lista de no planeados).
    if (matches.isEmpty) {
      final p =
          _product ??
          findProduct(code) ??
          Product(code, code, 'Producto no planeado ($code)', 'Cajas');
      await addRecords([
        AuditRecord(
          vale,
          _mode,
          p.sku,
          p.name,
          entered,
          _t!,
          motivo: 'Producto no incluido en el vale',
          photo: _photo,
          kind: RecordKind.extra,
          unit: p.unit,
        ),
      ]);
      if (!mounted) return;
      toast(
        context,
        'Producto extra registrado',
        '$entered ${p.unit.toLowerCase()} de ${p.name} se guardaron como extra en la NC. El vale no se modificó.',
        Icons.warning_amber_rounded,
        kAmber,
      );
      _clear(silent: true);
      _skuF.requestFocus();
      return;
    }

    // 2) Producto planeado: se compara contra la cantidad esperada de SU modo.
    final planned = matches.first;
    final p = planned.product;
    final expected = planned.expectedFor(_mode);
    final alreadyCaptured = records
        .where(
          (r) =>
              r.kind == RecordKind.valid &&
              r.vale == vale &&
              r.mode == _mode &&
              r.sku == p.sku,
        )
        .fold<int>(0, (sum, r) => sum + r.qty);
    final remaining = (expected - alreadyCaptured).clamp(0, expected).toInt();
    final validQty = entered < remaining ? entered : remaining;
    final excessQty = entered - validQty;
    final unit = p.unit.toLowerCase();
    final toAdd = <AuditRecord>[];
    if (validQty > 0) {
      toAdd.add(
        AuditRecord(
          vale,
          _mode,
          p.sku,
          p.name,
          validQty,
          _t!,
          motivo: _motivo ?? '',
          photo: _photo,
          unit: p.unit,
        ),
      );
    }
    if (excessQty > 0) {
      // El excedente se guarda aparte: no se suma a lo recibido ni cambia el vale.
      toAdd.add(
        AuditRecord(
          vale,
          _mode,
          p.sku,
          p.name,
          excessQty,
          _t!,
          motivo: 'Cantidad excedente sobre lo planeado ($_mode)',
          photo: _photo,
          kind: RecordKind.excess,
          unit: p.unit,
        ),
      );
    }
    await addRecords(toAdd);
    if (!mounted) return;
    toast(
      context,
      excessQty > 0 ? 'Captura registrada con NC' : '¡Guardado con éxito!',
      excessQty > 0
          ? '$validQty $unit válidas y $excessQty $unit enviadas a NC por exceder lo planeado en $_mode.'
          : 'Registro ($_mode) guardado correctamente. Pendiente por recibir: ${remaining - validQty} $unit.',
      excessQty > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
      excessQty > 0 ? kAmber : kGreen,
    );
    _clear(silent: true); // listo para el siguiente producto
    _skuF.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final warn = (_t ?? 0) > 4.0 && _eTemp == null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Back + vale tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: s200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_back, size: 13, color: kRed),
                              SizedBox(width: 4),
                              Text(
                                'Cambiar Vale',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: s600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: blue50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: blue200),
                        ),
                        child: Text(
                          t.vale,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Data informativa + temperatura
                  card(
                    accent: true,
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DATA INFORMATIVA DEL VIAJE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: s400,
                                letterSpacing: .8,
                              ),
                            ),
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: kBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _dataRow('RUTA:', Text(t.ruta, style: _bold)),
                        _dataRow('OPERADOR:', Text(t.operador, style: _bold)),
                        _dataRow(
                          'CORTINA:',
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: blue50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                            ),
                            child: Text(
                              t.cortina,
                              style: _bold.copyWith(color: kBlue),
                            ),
                          ),
                          last: true,
                        ),
                        const Divider(height: 14, color: s100),
                        Row(
                          children: [
                            const Icon(Icons.thermostat, size: 16, color: kRed),
                            const SizedBox(width: 2),
                            const Text(
                              'TEMP. (°C):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: s700,
                              ),
                            ),
                            const Spacer(),
                            /*     SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _temp,
                                
                                textAlign: TextAlign.right,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,\-]'),
                                  ),
                                ],
                                onChanged: (_) => setState(() => _eTemp = null),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: s900,
                                ),
                                decoration: deco(dense: true, suffixText: '°C')
                                    .copyWith(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: _eTemp != null ? kRed : s300,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: _eTemp != null ? kRed : s300,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                              ),
                            ), */

                            SizedBox(
                              width: 170,
                              child: Row(
                                children: [
                                  // Disminuir temperatura
                                  IconButton(
                                    onPressed: () {
                                      double value =
                                          double.tryParse(
                                            _temp.text.replaceAll(',', '.'),
                                          ) ??
                                          0;

                                      value = (value - 0.5).clamp(-50.0, 100.0);

                                      setState(() {
                                        _temp.text = value.toStringAsFixed(1);
                                        _eTemp = null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: s900,
                                  ),

                                  // Campo numérico
                                  Expanded(
                                    child: TextField(
                                      controller: _temp,
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.,\-]'),
                                        ),
                                      ],
                                      onChanged: (_) =>
                                          setState(() => _eTemp = null),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: s900,
                                      ),
                                      decoration:
                                          deco(
                                            dense: true,
                                            suffixText: '°C',
                                          ).copyWith(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: _eTemp != null
                                                    ? kRed
                                                    : s300,
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: _eTemp != null
                                                    ? kRed
                                                    : s300,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),

                                  // Aumentar temperatura
                                  IconButton(
                                    onPressed: () {
                                      double value =
                                          double.tryParse(
                                            _temp.text.replaceAll(',', '.'),
                                          ) ??
                                          0;

                                      value = (value + 0.5).clamp(-50.0, 100.0);

                                      setState(() {
                                        _temp.text = value.toStringAsFixed(1);
                                        _eTemp = null;
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: s900,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_eTemp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _eTemp!,
                                style: const TextStyle(
                                  color: kRed,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        if (warn)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFCD34D),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: kAmber,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '⚠️ Alerta Cadena de Frío (> 4.0°C)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Modo
                  const Text(
                    'SELECCIONE MODO DE AUDITORÍA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: s600,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: s200.withOpacity(.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _modeBtn('ROTATIVA', Icons.autorenew, kBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _modeBtn(
                            'DEFINITIVA',
                            Icons.shield_outlined,
                            kRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // SKU
                  card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            label('SKU DEL PRODUCTO', req: true),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: s100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: s200),
                              ),
                              child: Row(
                                children: [
                                  _pill(
                                    'Escanear',
                                    Icons.qr_code_scanner,
                                    _scanMode,
                                    kBlue,
                                    () => setState(() => _scanMode = true),
                                  ),
                                  _pill(
                                    'Digitar',
                                    Icons.keyboard,
                                    !_scanMode,
                                    kRed,
                                    () {
                                      setState(() => _scanMode = false);
                                      _skuF.requestFocus();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sku,
                                focusNode: _skuF,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _lookup(),
                                onChanged: (v) {
                                  final s = v.trim().toUpperCase();
                                  setState(() {
                                    _eSku = null;
                                    _product = null;
                                  });
                                  _lookup();
                                  if (RegExp(r'^(\d{13}|LAL-\d{6})$')
                                          .hasMatch(s) &&
                                      findProduct(s) != null)
                                    _lookup();
                                },
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                decoration: deco(
                                  dense: true,
                                  hint: _scanMode
                                      ? 'Escanear SKU de Lácteos...'
                                      : 'Digitar código SKU manualmente...',
                                  error: _eSku,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: s800,
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: _scanMode ? _scan : _lookup,
                              onLongPress: _scanMode ? _scanDemo : null,
                              icon: Icon(
                                _scanMode ? Icons.qr_code_scanner : Icons.check,
                                size: 16,
                                color: _scanMode ? kRed : Colors.white,
                              ),
                              label: Text(
                                _scanMode ? 'Capturar' : 'Buscar',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_product != null && _isExtra)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kAmber),
                            ),
                            child: const Text(
                              'Este producto NO está en el vale. Se guardará como extra en la NC y no modificará lo planeado.',
                              style: TextStyle(
                                fontSize: 11,
                                color: kAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_product != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: s100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: s200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESCRIPCIÓN DEL PRODUCTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kBlue,
                                    letterSpacing: .6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _product!.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: s800,
                                  ),
                                ),
                                Text(
                                  'UPC: ${_product!.upc} · SKU: ${_product!.sku}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: s500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cantidad
                  card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'CANTIDAD ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: s700,
                            ),
                            children: const [
                              TextSpan(
                                text: '(Números enteros)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                  color: s400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _qty,
                          focusNode: _qtyF,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          onChanged: (_) => setState(() => _eQty = null),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: s900,
                          ),
                          decoration: deco(
                            dense: true,
                            hint: '0',
                            error: _eQty,
                            suffixText: _product?.unit ?? 'Cajas',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_mode == 'DEFINITIVA') ...[
                    const SizedBox(height: 8),
                    const Divider(color: s200),
                    card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('SELECCIONE MOTIVO DEFINITIVA', req: true),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _motivo,
                            isExpanded: true,
                            hint: const Text(
                              '-- Selecciona motivo --',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: s800,
                            ),
                            items: [
                              for (final m in motivosDef)
                                DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _motivo = v;
                              _eMotivo = null;
                            }),
                            decoration: deco(dense: true, error: _eMotivo),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('OPCIÓN PARA COLOCAR FOTOGRAFÍA'),
                          const SizedBox(height: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _takePhoto,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: s50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: s300, width: 1.5),
                              ),
                              child: _photo
                                  ? Center(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: _photoFile != null
                                                ? Image.file(
                                                    _photoFile!,
                                                    width: 110,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 110,
                                                    height: 80,
                                                    color: s200,
                                                    child: const Icon(
                                                      Icons.image,
                                                      color: s500,
                                                    ),
                                                  ),
                                          ),
                                          Positioned(
                                            top: -8,
                                            right: -8,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _photo = false;
                                                  _photoFile = null;
                                                });
                                                toast(
                                                  context,
                                                  'Evidencia Eliminada',
                                                  'Se removió la fotografía.',
                                                  Icons.delete,
                                                  s600,
                                                );
                                              },
                                              child: const CircleAvatar(
                                                radius: 10,
                                                backgroundColor: kRed,
                                                child: Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 11,
                                          backgroundColor: s200,
                                          child: Icon(
                                            Icons.photo_camera,
                                            size: 12,
                                            color: s600,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Adjuntar Fotografía',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: s700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Botones LIMPIAR / GUARDAR
            /*   Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue,
                    side: const BorderSide(color: blue200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReconciliationScreen(trip: t),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text(
                    'CONCILIAR / APROBAR VALE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ), */
            Container(
              decoration: const BoxDecoration(
                color: s50,
                border: Border(top: BorderSide(color: s200)),
              ),
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: s700,
                        side: const BorderSide(color: s300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _clear,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: s400,
                      ),
                      label: const Text(
                        'LIMPIAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _save,
                      icon: const Icon(Icons.save, size: 16, color: kRed),
                      label: const Text(
                        'GUARDAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _bold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: s800,
  );

  Widget _dataRow(String k, Widget v, {bool last = false}) => Container(
    padding: const EdgeInsets.only(bottom: 3, top: 2),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: s100)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: const TextStyle(
            fontSize: 12,
            color: s500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: v),
      ],
    ),
  );

  Widget _modeBtn(String m, IconData icon, Color color) {
    final sel = _mode == m;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = m;
          _eMotivo = null;
        });
        toast(
          context,
          'Modo Seleccionado',
          'Auditoría en modo ${m == 'ROTATIVA' ? 'Rotativa' : 'Definitiva'}',
          icon,
          color,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: sel ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: sel ? (m == 'ROTATIVA' ? kRed : Colors.white) : s600,
            ),
            const SizedBox(width: 4),
            Text(
              m,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: sel ? Colors.white : s600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, IconData i, bool sel, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(i, size: 11, color: sel ? c : s500),
              const SizedBox(width: 3),
              Text(
                t,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: sel ? c : s500,
                ),
              ),
            ],
          ),
        ),
      );
}

// ───────── PLANEACIÓN DEL VALE ─────────
class PlanValeScreen extends StatefulWidget {
  final Trip? editing; // si viene, se edita esa planeación
  const PlanValeScreen({super.key, this.editing});
  @override
  State<PlanValeScreen> createState() => _PlanValeScreenState();
}

class _PlanValeScreenState extends State<PlanValeScreen> {
  final _vale = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _rotativa = TextEditingController(text: '0');
  final _definitiva = TextEditingController(text: '0');
  final List<PlannedProduct> _items = [];
  String? _error;
  String _unit = 'Cajas';
  Product? _origin; // producto original mientras se edita una línea
  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editing;
    if (t != null) {
      _vale.text = t.vale;
      _items.addAll(t.plannedProducts);
    }
  }

  void _editItem(int i) {
    final it = _items[i];
    setState(() {
      _items.removeAt(i);
      _origin = it.product;
      _code.text = it.product.upc.isNotEmpty ? it.product.upc : it.product.sku;
      _description.text = it.product.name;
      _rotativa.text = '${it.rotativa}';
      _definitiva.text = '${it.definitiva}';
      _unit = it.product.unit;
      _error = null;
    });
  }

  @override
  void dispose() {
    _vale.dispose();
    _code.dispose();
    _description.dispose();
    _rotativa.dispose();
    _definitiva.dispose();
    super.dispose();
  }

  void _addProduct() {
    final code = _code.text.trim().toUpperCase();
    final description = _description.text.trim();
    final rot = int.tryParse(_rotativa.text.trim());
    final def = int.tryParse(_definitiva.text.trim());
    if (code.isEmpty ||
        description.isEmpty ||
        rot == null ||
        def == null ||
        rot < 0 ||
        def < 0 ||
        (rot == 0 && def == 0)) {
      setState(
        () => _error = 'Completa el código, descripción y al menos una cantidad mayor a cero.',
      );
      return;
    }
    if (_items.any((x) => x.product.matches(code))) {
      setState(() => _error = 'Ese UPC/SKU ya fue agregado a este vale.');
      return;
    }
    final origin = _origin;
    final product = (origin != null && origin.matches(code))
        ? Product(origin.sku, origin.upc, description, _unit)
        : Product(
            code.startsWith('LAL-') ? code : code,
            code.startsWith('LAL-') ? '' : code,
            description,
            _unit,
          );
    _origin = null;
    setState(() {
      _items.add(PlannedProduct(product, rot, def));
      _code.clear();
      _description.clear();
      _rotativa.text = '0';
      _definitiva.text = '0';
      _error = null;
    });
  }

  Future<void> _savePlan() async {
    final name = _vale.text.trim().toUpperCase();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe el nombre o número del vale.');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto antes de guardar.');
      return;
    }
    if (!_editing && findTrip(name) != null) {
      setState(() => _error = 'Ya existe un vale con ese nombre.');
      return;
    }
    final trip = Trip(
      name,
      widget.editing?.ruta ?? 'Ruta de prueba',
      widget.editing?.operador ?? 'Operador de prueba',
      widget.editing?.cortina ?? 'Cortina de prueba',
      List<PlannedProduct>.from(_items),
    );
    await saveTrip(trip);
    if (!mounted) return;
    toast(
      context,
      _editing ? 'Planeación actualizada' : 'Vale planeado',
      '$name quedó guardado con ${_items.length} producto(s).',
      Icons.check_circle,
      kGreen,
    );
    Navigator.pop(context, trip);
  }

  Widget _field(
    String title,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    bool readOnly = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label(title, req: true),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.characters,

        onTap: () {
          if (controller.text == '0') {
            controller.clear();
          }
        },

        decoration: deco(hint: hint, dense: true),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: kBlue,
      foregroundColor: Colors.white,
      title: Text(_editing ? 'Editar planeación' : 'Planeación del vale'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        card(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CONFIGURA TU PRUEBA',
                style: TextStyle(
                  color: kBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Define el vale y las cantidades esperadas por producto. Después podrás iniciar la auditoría en cualquiera de los dos modos.',
                style: TextStyle(color: s600, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                'NOMBRE / NÚMERO DEL VALE',
                _vale,
                hint: 'Ej. VALE-PRUEBA-01',
                readOnly: _editing,
              ),
              const SizedBox(height: 16),
              const Text(
                'PRODUCTO A AGREGAR',
                style: TextStyle(
                  color: kBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _field('UPC O SKU', _code, hint: 'Escanea o escribe el código'),
              const SizedBox(height: 10),
              _field(
                'DESCRIPCIÓN DEL PRODUCTO',
                _description,
                hint: 'Ej. Leche entera 1 litro',
              ),
              const SizedBox(height: 10),
              label('UNIDAD DE MEDIDA', req: true),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: deco(dense: true),
                items: unitOptions
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'CANT. ROTATIVA',
                      _rotativa,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      'CANT. DEFINITIVA',
                      _definitiva,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('AGREGAR PRODUCTO'),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: kRed, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PRODUCTOS PLANEADOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: s700,
              ),
            ),
            Text(
              '${_items.length} producto(s)',
              style: const TextStyle(fontSize: 11, color: s500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          card(
            child: const Text(
              'Aún no agregas productos. Captura los datos de arriba y pulsa “Agregar producto”.',
              style: TextStyle(color: s500, fontSize: 12),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: card(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: blue50,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: kBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: s800,
                            ),
                          ),
                          Text(
                            item.product.upc.isNotEmpty
                                ? item.product.upc
                                : item.product.sku,
                            style: const TextStyle(fontSize: 10, color: s500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rotativa: ${item.rotativa}  •  Definitiva: ${item.definitiva}  •  ${item.product.unit}',
                            style: const TextStyle(fontSize: 11, color: s600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editItem(i),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: kBlue,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _items.removeAt(i)),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: kRed,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _savePlan,
            icon: const Icon(Icons.save),
            label: const Text('GUARDAR PLANEACIÓN'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

// ───────── Modal de escáner simulado ─────────
class ScannerDialog extends StatefulWidget {
  const ScannerDialog({super.key});
  @override
  State<ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<ScannerDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: s900,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: s800),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_camera, size: 14, color: kRed),
                  SizedBox(width: 6),
                  Text(
                    'Escaneando SKU / Código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: s400, size: 18),
              ),
            ],
          ),
          const Divider(color: s800),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s800),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 60, color: s800),
                Container(
                  width: 140,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: kRed, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Alinee el código',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                AnimatedBuilder(
                  animation: _a,
                  builder: (_, __) => Align(
                    alignment: Alignment(0, -0.9 + 1.7 * _a.value),
                    child: Container(height: 2, color: kRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Seleccione un producto para simular la lectura:',
            style: TextStyle(color: s400, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView(
              children: [
                for (final p in products.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: s800,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context, p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                p.upc,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ───────── CONCILIACIÓN Y APROBACIÓN DEL VALE ─────────
class ReconciliationScreen extends StatefulWidget {
  final Trip trip;
  const ReconciliationScreen({super.key, required this.trip});
  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

Future<void> imprimirTicketAuditoria(Trip trip, Reconciliation recon) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final fechaStr =
      "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80, // Formato ticket de 80mm
      margin: const pw.EdgeInsets.all(10),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'AUDIT TOOLS - TRAXIÓN',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'COMPROBANTE DE CONCILIACIÓN',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Divider(thickness: 1),
            pw.Text(
              'VALE / VIAJE: ${trip.vale}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.Text(
              'FECHA/HORA: $fechaStr',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'RUTA: ${trip.ruta}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'OPERADOR: ${trip.operador}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'CORTINA: ${trip.cortina}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 5),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Text(
              'DETALLE DE AUDITORÍA',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.SizedBox(height: 4),

            // Filas de conciliación
            ...recon.lines.map((line) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${line.item.product.sku} - ${line.item.product.name}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Modo: ${line.mode}',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          'Esp: ${line.expected} | Rec: ${line.received}',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                    if (line.excess > 0)
                      pw.Text(
                        'Excedente (NC): ${line.excess}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.orange900,
                        ),
                      ),
                  ],
                ),
              );
            }),

            if (recon.unplanned.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text(
                'NO PLANEADOS (NC)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              ...recon.unplanned.map(
                (u) => pw.Text(
                  '${u.sku} - Cant: ${u.qty} (${u.mode})',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],

            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1),
            pw.Center(
              child: pw.Text(
                '*** AUDITORÍA APROBADA ***',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // Muestra la previsualización y diálogo de impresión del sistema
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Ticket_Conciliacion_${trip.vale}.pdf',
  );
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  Future<void> _approve(Reconciliation r) async {
    if (!r.canApprove) {
      toast(
        context,
        'No se puede aprobar',
        r.lines.isEmpty
            ? 'Aún no hay productos que conciliar.'
            : r.blockers.join(' '),
        Icons.block,
        kRed,
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar auditoría'),
        content: Text(
          'Todas las cantidades coinciden con ${widget.trip.vale}. Después de aprobar ya no se podrán agregar capturas. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('APROBAR'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await approveVale(widget.trip.vale);
    if (!mounted) return;
    await imprimirTicketAuditoria(widget.trip, r);
    toast(
      context,
      'Auditoría aprobada',
      '${widget.trip.vale} quedó aprobado.',
      Icons.verified,
      kGreen,
    );
    setState(() {});
  }

  Widget _chip(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withOpacity(.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c),
    ),
  );

  Widget _lineCard(ReconLine l) {
    final u = l.unit.toLowerCase();
    final color = l.complete ? kGreen : kRed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.item.product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: s800,
                    ),
                  ),
                ),
                _chip(l.complete ? 'COMPLETO' : 'FALTAN ${l.missing}', color),
              ],
            ),
            Text(
              l.item.product.upc.isNotEmpty
                  ? l.item.product.upc
                  : l.item.product.sku,
              style: const TextStyle(fontSize: 10, color: s500),
            ),
            const SizedBox(height: 6),
            Text(
              'Planeado: ${l.expected} $u  •  Recibido: ${l.received} $u',
              style: const TextStyle(fontSize: 11, color: s600),
            ),
            if (l.excess > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'Excedente (NC): ${l.excess} $u',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: s700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = reconcile(widget.trip);
    final approved = isApproved(widget.trip.vale);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: Text('Conciliación ${widget.trip.vale}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  card(
                    accent: true,
                    child: Row(
                      children: [
                        Icon(
                          approved
                              ? Icons.verified
                              : (r.canApprove
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline),
                          color: approved || r.canApprove ? kGreen : kRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            approved
                                ? 'Auditoría aprobada.'
                                : r.canApprove
                                ? 'Todas las cantidades coinciden. Listo para aprobar.'
                                : 'Hay diferencias: no se puede aprobar.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final m in modes) ...[
                    _title(m == 'ROTATIVA' ? 'ROTATIVAS' : 'DEFINITIVAS'),
                    if (r.lines.where((l) => l.mode == m).isEmpty)
                      card(
                        child: const Text(
                          'Sin productos planeados en este modo.',
                          style: TextStyle(color: s500, fontSize: 12),
                        ),
                      )
                    else
                      ...r.lines.where((l) => l.mode == m).map(_lineCard),
                  ],
                  _title('PRODUCTOS NO PLANEADOS (NC)'),
                  if (r.unplanned.isEmpty)
                    card(
                      child: const Text(
                        'No se recibieron productos fuera del vale.',
                        style: TextStyle(color: s500, fontSize: 12),
                      ),
                    )
                  else
                    ...r.unplanned.map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: card(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.report_gmailerrorred,
                                color: kAmber,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      x.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: s800,
                                      ),
                                    ),
                                    Text(
                                      '${x.sku} • ${x.mode}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: s500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${x.qty} ${x.unit.toLowerCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: kAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!approved && !r.canApprove && r.lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        r.blockers.join('\n'),
                        style: const TextStyle(color: kRed, fontSize: 11),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: r.canApprove && !approved
                            ? kGreen
                            : s300,
                      ),
                      onPressed: approved ? null : () => _approve(r),
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(approved ? 'APROBADO' : 'APROBAR AUDITORÍA'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
