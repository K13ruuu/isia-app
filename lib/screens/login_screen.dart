import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/isia_theme.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final error = await _authService.signIn(email: _emailController.text.trim(), password: _passwordController.text);
    if (error != null) {
      if (mounted) setState(() { _errorMessage = error; _isLoading = false; });
      return;
    }
    final user = _authService.currentUser;
    if (user == null) return;
    final role = await _authService.getUserRole(user.uid);
    final notifications = NotificationService();
    await notifications.requestPermission();
    await notifications.saveTokenForCurrentUser();
    notifications.listenForTokenRefresh();
    notifications.listenForForegroundMessages();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminHomeScreen() : const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF5F3FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 12),
            Center(child: Image.asset('ISIA UI.png', width: 172, height: 172, fit: BoxFit.contain)),
            const SizedBox(height: 6),
            const Text('Information, Support, and Inspiration for All', textAlign: TextAlign.center, style: TextStyle(color: IsiaColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 34),
            const Text('Welcome back', style: TextStyle(color: IsiaColors.ink, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Sign in to stay connected with your school.', style: TextStyle(color: IsiaColors.muted)),
            const SizedBox(height: 22),
            TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'School email', prefixIcon: Icon(Icons.alternate_email_rounded)), validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            }),
            const SizedBox(height: 14),
            TextFormField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14)), child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFB91C1C)), textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _login, child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in')),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text("New to ISIA? Create an account")),
          ]),
        )),
      ))),
    ),
  );
}
