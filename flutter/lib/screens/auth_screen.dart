import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/adaptive_screen.dart';
import '../widgets/coconut_mark.dart';
import '../widgets/pill_button.dart';
import '../widgets/score_widgets.dart';

enum AuthRoute { welcome, login, register }

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
  var _route = AuthRoute.welcome;
  var _email = '';
  var _password = '';
  var _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_route == AuthRoute.login) {
        await widget.onLogin(_email, _password);
      } else {
        await widget.onRegister(_email, _password);
        setState(() => _route = AuthRoute.login);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация успешна! Подтвердите почту по ссылке из письма, а затем войдите.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_route == AuthRoute.login || _route == AuthRoute.register) {
      return AdaptiveScreen(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundIcon(icon: Icons.arrow_back, onTap: () => setState(() => _route = AuthRoute.welcome)),
              const SizedBox(height: 24),
              Text(
                _route == AuthRoute.login ? 'С возвращением.' : 'Добро пожаловать.',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => _email = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                obscureText: true,
                onChanged: (v) => _password = v,
              ),
              const SizedBox(height: 32),
              if (_isLoading || widget.loading)
                const CenteredLoader(compact: true)
              else
                PillButton(
                  label: _route == AuthRoute.login ? 'Войти' : 'Зарегистрироваться',
                  kind: PillKind.brand,
                  onTap: _submit,
                ),
              if (widget.error != null) ...[
                const SizedBox(height: 12),
                Text(widget.error!, textAlign: TextAlign.center, style: const TextStyle(color: Coco.red)),
              ],
            ],
          ),
        ),
      );
    }

    return AdaptiveScreen(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.infinite, painter: GlowPainter()),
                const CoconutMark(size: 180),
                const Positioned(left: 28, top: 70, child: ScoreChip(score: 92, big: true)),
                const Positioned(right: 36, top: 120, child: ScoreChip(score: 48, big: true)),
                const Positioned(left: 36, bottom: 140, child: ScoreChip(score: 71, big: true)),
                const Positioned(right: 40, bottom: 90, child: ScoreChip(score: 88, big: true)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coconut.', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: .96)),
                const SizedBox(height: 10),
                const Text(
                  'Раскуси каждый кусочек. Получи честную оценку любого продукта в один скан.',
                  style: TextStyle(color: Coco.ink2, fontSize: 19, height: 1.3),
                ),
                const SizedBox(height: 24),
                if (widget.loading)
                  const CenteredLoader(compact: true)
                else ...[
                  PillButton(label: 'Войти', kind: PillKind.brand, onTap: () => setState(() => _route = AuthRoute.login)),
                  const SizedBox(height: 12),
                  PillButton(label: 'Зарегистрироваться', kind: PillKind.ghost, onTap: () => setState(() => _route = AuthRoute.register)),
                ],
                if (widget.error != null) ...[
                  const SizedBox(height: 12),
                  Text(widget.error!, textAlign: TextAlign.center, style: const TextStyle(color: Coco.red)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
