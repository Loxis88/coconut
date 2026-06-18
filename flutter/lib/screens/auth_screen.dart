import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onLogin,
    required this.onRegister,
  });

  final bool loading;
  final String? error;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String email, String password) onRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _email = '';
  var _password = '';
  var _isLogin = true;

  void _submit() async {
    if (_isLogin) {
      await widget.onLogin(_email, _password);
    } else {
      await widget.onRegister(_email, _password);
      if (mounted) {
        setState(() => _isLogin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Регистрация успешна! Подтвердите почту и войдите.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MayakTheme.bg,
      body: Column(
        children: [
          // Dark Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: MayakTheme.darkHeader,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Ambient glow
                  Positioned(
                    top: -48,
                    right: -48,
                    child: Container(
                      width: 192,
                      height: 192,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x1F5BAF64),
                            Colors.transparent
                          ], // 0.12 opacity approx
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 28, right: 28, top: 24, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo row
                        Row(
                          children: [
                            CustomPaint(
                              size: const Size(28, 36),
                              painter: MiniLighthousePainter(),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'МАЯК',
                              style: GoogleFonts.fraunces(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                color: Colors.white,
                                letterSpacing: 22 * 0.15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        // Hero text
                        Text(
                          'Навигатор\nпитания',
                          style: GoogleFonts.fraunces(
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: 36 * -0.02,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ваши данные хранятся на устройстве\nи не передаются третьим лицам',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.35),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLogin ? 'Email и пароль' : 'Регистрация',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: MayakTheme.fg,
                      letterSpacing: 18 * -0.02,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => _email = v,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Пароль',
                    hint: '••••••••',
                    obscureText: true,
                    onChanged: (v) => _password = v,
                  ),
                  const SizedBox(height: 24),
                  if (widget.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.error!,
                        style: GoogleFonts.dmSans(
                            color: MayakTheme.scorePoor, fontSize: 13),
                      ),
                    ),
                  widget.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MayakTheme.primary))
                      : GestureDetector(
                          onTap: _submit,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: MayakTheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isLogin ? 'Войти' : 'Создать аккаунт',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: MayakTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fade().slideX(
                  begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: MayakTheme.mutedFg,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(fontSize: 15, color: MayakTheme.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: MayakTheme.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0x1A0C1A09), width: 1.5), // 0.1 opacity
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0x1A0C1A09), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: MayakTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class MiniLighthousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = Colors.white.withValues(alpha: 0.85);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 14, 8, 20), const Radius.circular(1)),
        paint);

    paint.color = Colors.white.withValues(alpha: 0.25);
    canvas.drawRect(const Rect.fromLTWH(10, 21, 8, 4), paint);

    paint.color = Colors.white;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 8, 16, 8), const Radius.circular(2)),
        paint);

    paint.color = const Color(0xFFFFD566);
    canvas.drawCircle(const Offset(14, 12), 3, paint);

    paint.color = Colors.white.withValues(alpha: 0.85);
    final path = Path()
      ..moveTo(8, 8)
      ..quadraticBezierTo(14, 3, 20, 8);
    canvas.drawPath(path, paint);

    paint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 33, 12, 3), const Radius.circular(1)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
