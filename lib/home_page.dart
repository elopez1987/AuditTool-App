import 'package:audit_tool/test_aut/main_mockup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/login_screen.dart';

// ---------- HomePage unificado sin doble barra ----------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: s50,
        // Usamos directamente ValeScreen como cuerpo.
        // Como ValeScreen ya trae su propio diseño de cabecera impecable,
        // solo le inyectamos los accesos globales (perfil y salir) si es necesario,
        // o dejamos que muestre su AppHeader original sin duplicados.
        body: const ValeScreen(),
      ),
    );
  }
}
