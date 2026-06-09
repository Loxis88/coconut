import 'package:flutter/material.dart';
import '../main.dart';

class EmailAuthSheet extends StatefulWidget {
  const EmailAuthSheet({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String email, String password, String nickname) onRegister;

  @override
  State<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<EmailAuthSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  var _isLogin = true;
  var _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      if (_isLogin) {
        await widget.onLogin(_email.text, _password.text);
        if (mounted) Navigator.pop(context);
      } else {
        await widget.onRegister(_email.text, _password.text, _nickname.text);
        setState(() {
          _message = 'Письмо отправлено! Пожалуйста, подтвердите почту перед входом.';
          _isLogin = true;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Coco.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Coco.hairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            _isLogin ? 'С возвращением' : 'Новый аккаунт',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin ? 'Войдите, чтобы продолжить сканирование.' : 'Присоединяйтесь к Coconut сегодня.',
            style: const TextStyle(color: Coco.muted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Coco.emerald.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Coco.emerald),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_message!, style: const TextStyle(color: Coco.emeraldDeep, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!_isLogin) ...[
            _textField(controller: _nickname, label: 'Ваше имя', icon: Icons.person_outline),
            const SizedBox(height: 12),
          ],
          _textField(controller: _email, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _textField(controller: _password, label: 'Пароль', icon: Icons.lock_outline, obscureText: true),
          const SizedBox(height: 24),
          if (_loading)
            const CenteredLoader(compact: true)
          else
            PillButton(
              label: _isLogin ? 'Войти' : 'Создать аккаунт',
              kind: PillKind.brand,
              onTap: _submit,
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Center(child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Coco.red, fontWeight: FontWeight.w700))),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _isLogin = !_isLogin;
                _error = null;
                _message = null;
              }),
              child: Text(
                _isLogin ? 'Еще нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                style: const TextStyle(color: Coco.ink, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Coco.muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        floatingLabelStyle: const TextStyle(color: Coco.emeraldDeep, fontWeight: FontWeight.w800),
      ),
    );
  }
}
