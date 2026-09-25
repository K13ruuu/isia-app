import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/platform_settings_service.dart';
import '../theme/isia_theme.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;

  static const int _totalSteps = 4;

  final List<_WizardStep> _steps = const [
    _WizardStep(
      icon: Icons.notifications_active,
      title: 'Allow Notifications',
      description:
          'ISIA needs permission to send you announcements, reminders, and urgent alerts — even when the app is closed.',
      openLabel: 'Allow Notifications',
      openAction: _WizardOpenAction.requestNotificationPermission,
    ),
    _WizardStep(
      icon: Icons.battery_saver,
      title: 'Disable Battery Restrictions',
      description:
          'Your phone may block ISIA from receiving notifications while the app is closed. On the next screen, set ISIA to "No restrictions" or "Unrestricted".',
      openLabel: 'Open Battery Settings',
      openAction: _WizardOpenAction.openBatterySettings,
    ),
    _WizardStep(
      icon: Icons.tune,
      title: 'Set Notification Priority',
      description:
          'On the next screen, tap "ISIA Alerts" and set it to Urgent or High. Turn on sound, vibration, and lock-screen notifications.',
      openLabel: 'Open Notification Settings',
      openAction: _WizardOpenAction.openNotificationSettings,
    ),
    _WizardStep(
      icon: Icons.autorenew,
      title: 'Allow Autostart',
      description:
          'On Xiaomi, Redmi, POCO, OPPO, Realme, OnePlus, Vivo, or Huawei phones, enable "Autostart" for ISIA so notifications arrive in the background.',
      openLabel: 'Open Autostart Settings',
      openAction: _WizardOpenAction.openAutostartSettings,
    ),
  ];

  Future<void> _handleOpen(_WizardOpenAction action) async {
    switch (action) {
      case _WizardOpenAction.requestNotificationPermission:
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        break;

      case _WizardOpenAction.openBatterySettings:
        await PlatformSettingsService.openBatterySettings();
        break;

      case _WizardOpenAction.openNotificationSettings:
        await PlatformSettingsService.openNotificationSettings();
        break;

      case _WizardOpenAction.openAutostartSettings:
        await PlatformSettingsService.openAutostartSettings();
        break;
    }
  }

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFF5F3FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: List.generate(_totalSteps, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active
                              ? IsiaColors.indigo
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Step ${_step + 1} of $_totalSteps',
                    style: const TextStyle(
                      fontSize: 12,
                      color: IsiaColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const IsiaBrandMark(size: 56),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE8EDF4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: IsiaColors.indigo.withOpacity(0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 40,
                                color: IsiaColors.indigo,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: IsiaColors.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: IsiaColors.muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              onPressed: () => _handleOpen(step.openAction),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(step.openLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    if (_step > 0)
                      OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 92),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 54),
                      ),
                      child: Text(
                        _step == _totalSteps - 1
                            ? 'Start Using ISIA'
                            : 'Next',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WizardOpenAction {
  requestNotificationPermission,
  openBatterySettings,
  openNotificationSettings,
  openAutostartSettings,
}

class _WizardStep {
  const _WizardStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.openLabel,
    required this.openAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String openLabel;
  final _WizardOpenAction openAction;
}