import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/deadline_service.dart';
import '../../theme/isia_theme.dart';

class ManageDeadlinesScreen extends StatefulWidget {
  const ManageDeadlinesScreen({super.key});

  @override
  State<ManageDeadlinesScreen> createState() => _ManageDeadlinesScreenState();
}

class _ManageDeadlinesScreenState extends State<ManageDeadlinesScreen> {
  final _deadlineService = DeadlineService();
  final _authService = AuthService();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSection;
  String _selectedType = 'Activity';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  bool _loadingSections = true;
  List<String> _availableSections = [];

  final List<String> _types = ['Quiz', 'Exam', 'Activity'];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _loadingSections = false);
      return;
    }

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
        _loadingSections = false;
      });
    } else {
      setState(() {
        _availableSections = sections;
        _selectedSection = sections.first;
        _loadingSections = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Exam':
        return Colors.red;
      case 'Quiz':
        return Colors.orange;
      case 'Activity':
        return IsiaColors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _addDeadline() async {
    if (_titleController.text.isEmpty || _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subject and title.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? error = await _deadlineService.addDeadline(
      section: _selectedSection!,
      subject: _subjectController.text.trim(),
      title: _titleController.text.trim(),
      type: _selectedType,
      dueDate: _dueDate,
      description: _descriptionController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _subjectController.clear();
    _titleController.clear();
    _descriptionController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deadline added!')),
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
                  'Add Deadline',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IsiaColors.ink),
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
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Title (e.g., Chapter 3 Quiz)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Due: ${_formatDate(_dueDate)}'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addDeadline,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Saving...' : 'Add Deadline'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'All Deadlines You Posted',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _deadlineService.getAllDeadlines(),
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
                  child: Center(child: Text('No deadlines yet.')),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] ?? 'Activity';
                  final section = data['section'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _typeColor(type),
                          child: Icon(
                            type == 'Exam'
                                ? Icons.assignment_late
                                : type == 'Quiz'
                                    ? Icons.quiz
                                    : Icons.task,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text('$type: ${data['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['subject'] ?? ''),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                section,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _deadlineService.deleteDeadline(doc.id);
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