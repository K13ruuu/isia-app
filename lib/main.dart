import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/setup_wizard_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/isia_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const ISIAApp());

  NotificationService().initializeLocalNotifications();
}

class ISIAApp extends StatelessWidget {
  const ISIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISIA',
      debugShowCheckedModeBanner: false,
      theme: buildIsiaTheme(),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  final _authService = AuthService();
  bool _checking = true;
  Widget _destination = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final setupDone = prefs.getBool('setup_completed') ?? false;

    if (!setupDone) {
      if (!mounted) return;
      setState(() {
        _destination = SetupWizardScreen(
          onComplete: () {
            if (!mounted) return;
            setState(() {
              _destination = const LoginScreen();
            });
          },
        );
        _checking = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _destination = const LoginScreen();
        _checking = false;
      });
      return;
    }

    try {
      final role = await _authService.getUserRole(user.uid);
      if (!mounted) return;
      setState(() {
        _destination = (role == 'admin')
            ? const AdminHomeScreen()
            : const HomeScreen();
        _checking = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _destination = const LoginScreen();
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF4F46E5),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return _destination;
  }
}