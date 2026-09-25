import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../theme/isia_theme.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final _scheduleService = ScheduleService();
  final _authService = AuthService();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();

  String? _selectedSection;
  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 30);
  bool _isSaving = false;
  bool _loadingSections = true;
  List<String> _availableSections = [];
  String _displayName = 'Teacher';

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _honorificName(String fullName, String gender) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Teacher';
    final parts = trimmed.split(RegExp(r'\s+'));
    final lastName = parts.last;
    final honorific = gender.toLowerCase() == 'female' ? "Ma'am" : 'Sir';
    return '$honorific $lastName';
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _loadingSections = false);
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final fullName = userData?['fullName'] as String? ?? 'Teacher';
    final gender = userData?['gender'] as String? ?? 'male';
    final display = _honorificName(fullName, gender);

    final sections = await _authService.getAssignedSections(user.uid);

    if (sections.isEmpty) {
      const all = [
        'Grade 11 - STEM A',
        'Grade 11 - STEM B',
        'Grade 11 - ABM A',
        'Grade 11 - HUMSS A',
        'Grade 12 - STEM A',
        'Grade 12 - STEM B',
        'Grade 12 - ABM A',
        'Grade 12 - HUMSS A',
      ];
      setState(() {
        _availableSections = all;
        _selectedSection = all.first;
        _displayName = display;
        _loadingSections = false;
      });
    } else {
      setState(() {
        _availableSections = sections;
        _selectedSection = sections.first;
        _displayName = display;
        _loadingSections = false;
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _addClass() async {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? error = await _scheduleService.addClass(
      section: _selectedSection!,
      day: _selectedDay,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      subject: _subjectController.text.trim(),
      teacher: _displayName,
      room: _roomController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    _subjectController.clear();
    _roomController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class added!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSections) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF5F3FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Class to Schedule',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IsiaColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posting as: $_displayName',
                  style: const TextStyle(
                      fontSize: 12, color: IsiaColors.muted),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: _availableSections
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSection = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: _days
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDay = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(true),
                        child: Text('Start: ${_formatTime(_startTime)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(false),
                        child: Text('End: ${_formatTime(_endTime)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addClass,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Saving...' : 'Add Class'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Existing Classes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _scheduleService.getScheduleForSection(_selectedSection!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No classes yet.')),
                );
              }

              final docs = snapshot.data!.docs.toList();
              // Sort client-side by day then time
              int toMinutes(String t) {
                final p = t.split(':');
                if (p.length != 2) return 0;
                return (int.tryParse(p[0]) ?? 0) * 60 +
                    (int.tryParse(p[1]) ?? 0);
              }

              const dayOrder = {
                'Monday': 1,
                'Tuesday': 2,
                'Wednesday': 3,
                'Thursday': 4,
                'Friday': 5,
              };
              docs.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                final oa = dayOrder[da['day']] ?? 99;
                final ob = dayOrder[db['day']] ?? 99;
                if (oa != ob) return oa.compareTo(ob);
                return toMinutes((da['startTime'] ?? '').toString())
                    .compareTo(
                        toMinutes((db['startTime'] ?? '').toString()));
              });

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Card(
                      child: ListTile(
                        title: Text(data['subject'] ?? ''),
                        subtitle: Text(
                          '${data['day']} • ${data['startTime']}-${data['endTime']} • ${data['room']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _scheduleService.deleteClass(doc.id);
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}