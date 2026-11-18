import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email/password account management. Anonymous users can attach credentials
/// to their existing Supabase identity, preserving the existing UUID.
class NovaAccountDialog extends StatefulWidget {
  const NovaAccountDialog({super.key, required this.onAccountChanged});

  final Future<void> Function() onAccountChanged;

  @override
  State<NovaAccountDialog> createState() => _NovaAccountDialogState();
}

class _NovaAccountDialogState extends State<NovaAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _reset = false;
  bool _busy = false;
  String? _message;
  bool _error = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _show(String value, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = value;
      _error = error;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final email = _email.text.trim();
    final password = _password.text;
    final auth = Supabase.instance.client.auth;
    try {
      if (_reset) {
        await auth.resetPasswordForEmail(email);
        _show('Если адрес зарегистрирован, письмо для сброса пароля отправлено.');
      } else if (_register) {
        final user = auth.currentUser;
        if (user?.isAnonymous == true) {
          // Convert the guest account instead of creating a new UUID.
          await auth.updateUser(UserAttributes(email: email, password: password));
        } else {
          await auth.signUp(email: email, password: password);
        }
        await widget.onAccountChanged();
        _show('Запрос регистрации принят. Проверь почту и подтверди Email, если подтверждение включено в Supabase.');
      } else {
        await auth.signInWithPassword(email: email, password: password);
        await widget.onAccountChanged();
        if (mounted) Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      _show(e.message, error: true);
    } catch (e) {
      _show('Не удалось выполнить операцию: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anonymous = Supabase.instance.client.auth.currentUser?.isAnonymous ?? false;
    return AlertDialog(
      title: Text(_reset
          ? 'Восстановление пароля'
          : _register
              ? 'Регистрация Nova'
              : 'Вход в Nova'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (anonymous && _register && !_reset)
                const Text(
                  'Email и пароль будут привязаны к текущему гостевому аккаунту. Твой ID и выданный Premium сохранятся.',
                  style: TextStyle(fontSize: 12),
                ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                    return 'Введи корректный Email';
                  }
                  return null;
                },
              ),
              if (!_reset) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: _register
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  validator: (value) {
                    if ((value ?? '').length < 8) return 'Минимум 8 символов';
                    return null;
                  },
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _error ? Theme.of(context).colorScheme.error : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _reset = !_reset;
                    _message = null;
                  }),
          child: Text(_reset ? 'Назад' : 'Забыли пароль?'),
        ),
        if (!_reset)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _register = !_register;
                      _message = null;
                    }),
            child: Text(_register ? 'Уже есть аккаунт? Войти' : 'Создать аккаунт'),
          ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_reset ? 'Отправить письмо' : _register ? 'Зарегистрироваться' : 'Войти'),
        ),
      ],
    );
  }
}
