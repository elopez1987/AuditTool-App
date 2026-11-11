import 'package:audit_tool/services/auth_service.dart';
import 'package:audit_tool/auth/login_screen.dart';
import 'package:audit_tool/auth/session.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _loading = true;
  Map<String, dynamic>? _profileData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = await _authService.getProfile();

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _profileData = data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'No se pudo cargar la información del perfil.';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Datos de respaldo desde la sesión local en memoria por si tardan
    final session = SessionStore.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.fail,
                    ),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _fetchProfile,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tarjeta de cabecera con Avatar y Nombre
                Card(
                  elevation: 0,
                  color: AppColors.blue.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.blue,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profileData?['name'] ?? session?.name ?? 'Usuario',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profileData?['centerName'] ??
                              session?.centerName ??
                              '',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Detalles de la cuenta
                const Text(
                  'Detalles del Centro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.business_outlined,
                          color: AppColors.blue,
                        ),
                        title: const Text('ID de Centro'),
                        subtitle: Text(
                          _profileData?['centerId'] ??
                              session?.centerId ??
                              'N/A',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.store_mall_directory_outlined,
                          color: AppColors.blue,
                        ),
                        title: const Text('Centro de Trabajo'),
                        subtitle: Text(
                          _profileData?['centerName'] ??
                              session?.centerName ??
                              'N/A',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de Cerrar Sesión
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.fail,
                    side: const BorderSide(color: AppColors.fail),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
    );
  }
}
