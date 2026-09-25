import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/poll_service.dart';
import '../../theme/isia_theme.dart';

class ManagePollsScreen extends StatefulWidget {
  const ManagePollsScreen({super.key});

  @override
  State<ManagePollsScreen> createState() => _ManagePollsScreenState();
}

class _ManagePollsScreenState extends State<ManagePollsScreen> {
  final _service = PollService();
  final _authService = AuthService();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
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
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
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

  Future<void> _create() async {
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (_questionController.text.trim().isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a question and at least 2 options.')),
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

    final error = await _service.createPoll(
      question: _questionController.text,
      options: options,
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

    _questionController.clear();
    for (final c in _optionControllers) {
      c.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll created!')),
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
                  'Create a Poll',
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
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'e.g., Which club should we join?',
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _optionControllers[i],
                      decoration: InputDecoration(
                        labelText:
                            'Option ${i + 1}${i < 2 ? ' (required)' : ' (optional)'}',
                        isDense: true,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _create,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Creating...' : 'Post Poll'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Existing Polls',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _service.getAllPolls(),
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
                  child: Center(child: Text('No polls yet.')),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isOpen = data['isOpen'] == true;
                  final options =
                      (data['options'] as List? ?? []).cast<String>();
                  final ts = data['targetSection'] ?? 'All';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['question'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: IsiaColors.ink,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? Colors.green.withOpacity(0.15)
                                        : IsiaColors.muted.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isOpen ? 'OPEN' : 'CLOSED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: isOpen
                                          ? Colors.green.shade700
                                          : IsiaColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: _service.getVotes(doc.id),
                              builder: (context, votesSnap) {
                                final votes = votesSnap.hasData
                                    ? votesSnap.data!.docs
                                    : [];
                                final counts =
                                    List<int>.filled(options.length, 0);
                                for (final v in votes) {
                                  final d =
                                      v.data() as Map<String, dynamic>;
                                  final idx =
                                      (d['optionIndex'] as num?)?.toInt();
                                  if (idx != null &&
                                      idx >= 0 &&
                                      idx < counts.length) {
                                    counts[idx]++;
                                  }
                                }
                                final total =
                                    counts.fold<int>(0, (a, b) => a + b);

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ...List.generate(options.length, (idx) {
                                      final count = counts[idx];
                                      final pct = total == 0
                                          ? 0.0
                                          : count / total;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    options[idx],
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                ),
                                                Text(
                                                  '$count',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: IsiaColors.indigo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 5,
                                                backgroundColor: const Color(
                                                    0xFFE2E8F0),
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                        IsiaColors.indigo),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '$total vote${total == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: IsiaColors.muted,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () async {
                                            await _service.togglePollStatus(
                                                doc.id, isOpen);
                                          },
                                          icon: Icon(
                                            isOpen
                                                ? Icons.lock_outline
                                                : Icons.lock_open,
                                            size: 14,
                                          ),
                                          label: Text(
                                              isOpen ? 'Close' : 'Reopen',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                IsiaColors.indigo,
                                            padding: const EdgeInsets
                                                .symmetric(horizontal: 8),
                                            minimumSize:
                                                const Size(0, 32),
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 18),
                                          onPressed: () async {
                                            await _service
                                                .deletePoll(doc.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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