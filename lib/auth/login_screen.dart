import 'package:audit_tool/core/api_config.dart';
import 'package:flutter/material.dart';

import '../core/api_settings_screen.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  final _auth = AuthService();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // Usuario de acceso offline-google
  static const String _offlineUser = 'auditor.master';
  static const String _offlinePassword = 'Audit2026!';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;

    setState(() {
      _loading = true;
      _error = null;
    });

    // 1. Validar usuario especial offline
    if (username == _offlineUser && password == _offlinePassword) {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }

    // 2. Autenticación normal mediante API
    try {
      final result = await _auth.signIn(username, password);
      if (!mounted) return;
      if (result.ok) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        setState(() {
          _loading = false;
          _error = result.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No fue posible conectar con el servidor.';
      });
    }
  }

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    const line = Color(0xFFC9CED4);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _border(line),
      enabledBorder: _border(line),
      focusedBorder: _border(AppColors.blue, 1.5),
      errorBorder: _border(AppColors.fail),
      focusedErrorBorder: _border(AppColors.fail, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const _Header(),
                          Expanded(child: _buildPanel(context)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 12,
              child: IconButton(
                tooltip: 'Configuración de API',
                color: Colors.white,
                iconSize: 28,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ApiSettingsScreen(),
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

  Widget _buildPanel(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: const Color(0xFF374151), fontWeight: FontWeight.w500);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Iniciar sesión',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),

              Text('Correo o usuario', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _userCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: _decoration('nombre@empresa.com'),
                onFieldSubmitted: (_) => _passFocus.requestFocus(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa tu correo o usuario'
                    : null,
              ),
              const SizedBox(height: 16),

              Text('Contraseña', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                focusNode: _passFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: _decoration(
                  'Tu contraseña',
                  suffix: IconButton(
                    tooltip: _obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _soon(
                    'Contacta a tu administrador para '
                    'restablecer tu contraseña.',
                  ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.fail,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.fail),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _soon('Acceso corporativo: pendiente de conectar.'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Ingresar con cuenta corporativa'),
              ),

              const Spacer(),
              const SizedBox(height: 16),
              const Text(
                'Versión 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        children: [
          // El PNG tiene margen alrededor de la figura; se recorta al contenido.
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              widthFactor: 0.6,
              heightFactor: 0.66,
              child: Image.asset(
                'assets/logo/logo_blanco.png',
                width: 150,
                height: 150,
                semanticLabel: 'Logo Audit Tool',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Audit Tool',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Auditoría de producto en campo',
            style: TextStyle(fontSize: 14, color: Color(0xFFD3DEF3)),
          ),
        ],
      ),
    );
  }
}
