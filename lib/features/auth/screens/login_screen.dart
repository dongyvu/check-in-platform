import 'package:flutter/material.dart';
import 'package:sign/features/admin/screens/admin_main_screen.dart';
import 'package:sign/features/student/screens/student_main_screen.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = SignRepository();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login() async {
    await _runAuthAction(() async {
      final profile = await _repository.signIn(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _goHome(profile.isAdmin);
    });
  }

  Future<void> _register() async {
    await _runAuthAction(() async {
      final email = _usernameController.text.trim();
      final profile = await _repository.signUp(
        email: email,
        password: _passwordController.text,
        displayName: email.split('@').first,
      );

      if (!mounted) return;
      if (profile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('注册成功，请验证邮箱后再登录')));
        return;
      }
      _goHome(profile.isAdmin);
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入邮箱和密码')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goHome(bool isAdmin) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isAdmin ? const AdminMainScreen() : const MainScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MaxWidthContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 32),
                Text(
                  '欢迎登录',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '移动签到平台',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isLoading ? '处理中...' : '登 录',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _register,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('注册账号', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
