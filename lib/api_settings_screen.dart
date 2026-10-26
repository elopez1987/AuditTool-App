import 'package:flutter/material.dart';

import 'api_config.dart';
import 'app_theme.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _urlCtrl;
  late String _originalUrl;

  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();

    _originalUrl = ApiConfig.baseUrl;
    _urlCtrl = TextEditingController(text: _originalUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _originalUrl = ApiConfig.baseUrl;
      _urlCtrl.text = _originalUrl;
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _urlCtrl.text = _originalUrl;
      _editing = false;
    });
  }

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return 'Ingresa una URL HTTP o HTTPS válida';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_editing || _saving) return;
    if (!_formKey.currentState!.validate()) return;

    final newUrl = _urlCtrl.text.trim().replaceFirst(RegExp(r'/+$'), '');

    if (newUrl == _originalUrl) {
      setState(() => _editing = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cambio de API'),
        content: const Text(
          'Cambiar la URL puede afectar el inicio de sesión '
          'y las peticiones al servidor.\n\n'
          '¿Deseas guardar la nueva dirección?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar cambio'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _saving = true);

    try {
      await ApiConfig.saveBaseUrl(newUrl);

      if (!mounted) return;

      setState(() {
        _originalUrl = ApiConfig.baseUrl;
        _urlCtrl.text = _originalUrl;
        _editing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL de API guardada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar la URL: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedUrl = _editing
        ? _urlCtrl.text.trim().replaceFirst(RegExp(r'/+$'), '')
        : ApiConfig.baseUrl;

    return Scaffold(
      backgroundColor: AppColors.blue,
      appBar: AppBar(
        title: const Text('Configuración de API'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Conexión con el servidor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La dirección del servidor está protegida '
                'para evitar modificaciones accidentales.',
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _urlCtrl,
                readOnly: !_editing || _saving,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableInteractiveSelection: _editing,
                decoration: InputDecoration(
                  labelText: 'URL base de la API',
                  hintText: 'https://api.empresa.com',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: Icon(_editing ? Icons.edit : Icons.lock_outline),
                  filled: true,
                  fillColor: _editing ? Colors.white : const Color(0xFFF3F4F6),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateUrl,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (_editing) _save();
                },
              ),

              const SizedBox(height: 12),

              Text(
                _editing
                    ? 'Edita la dirección y guarda únicamente '
                          'cuando estés seguro del cambio.'
                    : 'URL bloqueada. Pulsa "Editar URL" '
                          'para habilitar los cambios.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),

              const SizedBox(height: 24),

              if (!_editing)
                FilledButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar URL'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    minimumSize: const Size.fromHeight(52),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Guardar URL'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _cancelEditing,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar cambios'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
