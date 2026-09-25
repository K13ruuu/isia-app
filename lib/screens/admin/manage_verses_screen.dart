import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/verse_service.dart';
import '../../theme/isia_theme.dart';

class ManageVersesScreen extends StatefulWidget {
  const ManageVersesScreen({super.key});

  @override
  State<ManageVersesScreen> createState() => _ManageVersesScreenState();
}

class _ManageVersesScreenState extends State<ManageVersesScreen> {
  final _service = VerseService();
  final _authService = AuthService();
  final _textController = TextEditingController();
  final _authorController = TextEditingController();
  String _type = 'verse';
  bool _isSaving = false;
  bool _loadingSections = true;
  List<String> _availableSections = [];
  String _targetSection = 'All';

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
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
        _availableSections = ['All', ...all];
        _loadingSections = false;
      });
    } else {
      setState(() {
        _availableSections = ['All', ...sections];
        _loadingSections = false;
      });
    }
  }

  Future<void> _add() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the text.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?['fullName'] ?? 'Teacher';

    final error = await _service.addVerse(
      text: _textController.text,
      author: _authorController.text,
      type: _type,
      postedBy: user.uid,
      postedByName: name,
      targetSection: _targetSection,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _textController.clear();
    _authorController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added successfully!')),
    );
  }

  Color _badgeColor(String section) {
    return section == 'All' ? IsiaColors.indigo : Colors.teal;
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
                  'Add Verse or Quote',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IsiaColors.ink),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _targetSection,
                  decoration:
                      const InputDecoration(labelText: 'Target Section'),
                  items: _availableSections
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                s == 'All' ? 'All Sections' : s),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _targetSection = v ?? 'All'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'verse', child: Text('Bible Verse')),
                    DropdownMenuItem(value: 'quote', child: Text('Quote')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    hintText: 'Type the verse or quote here...',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: _type == 'verse'
                        ? 'Reference (e.g., John 3:16 NIV)'
                        : 'Author',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _add,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Saving...' : 'Add'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Custom Verses & Quotes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _service.getCustomVerses(),
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
                  child: Center(
                      child: Text('No custom verses yet. Built-in ones will show.')),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] ?? 'quote';
                  final ts = data['targetSection'] ?? 'All';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: type == 'verse'
                              ? IsiaColors.indigo
                              : IsiaColors.purple,
                          child: Icon(
                            type == 'verse'
                                ? Icons.menu_book
                                : Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '"${data['text']}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('— ${data['author']}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _badgeColor(ts).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ts == 'All' ? 'All Sections' : ts,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _badgeColor(ts),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _service.deleteVerse(doc.id);
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