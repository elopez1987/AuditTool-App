import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'home_page.dart';
import 'auth/login_screen.dart';
import 'auth/session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final session = await SessionStore.restore();

    if (!mounted) return;

    if (session != null) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blue,
              const Color(0xFF12345A),
              const Color(0xFF081B32),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Elementos decorativos
            Positioned(
              top: -100,
              right: -80,
              child: _buildCircle(250, Colors.white.withOpacity(0.04)),
            ),

            Positioned(
              bottom: -120,
              left: -90,
              child: _buildCircle(280, Colors.white.withOpacity(0.04)),
            ),

            // Contenido principal
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      // Logo de Audit Tool
                      Container(
                        width: 135,
                        height: 135,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 30,
                              spreadRadius: 3,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nombre
                      const Text(
                        'AUDIT TOOL',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtítulo
                      Text(
                        'CONTROL • SEGURIDAD • AUDITORÍA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),

                      const SizedBox(height: 55),

                      // Indicador de carga
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF65C8FF),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Preparando tu espacio de trabajo...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pie de pantalla
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 35,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF65C8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AUDIT TOOL  •  SECURE ACCESS',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Colors.white.withOpacity(0.45),
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

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
