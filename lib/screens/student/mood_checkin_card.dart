import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/mood_service.dart';
import '../../theme/isia_theme.dart';

class MoodCheckInCard extends StatefulWidget {
  const MoodCheckInCard({super.key});

  @override
  State<MoodCheckInCard> createState() => _MoodCheckInCardState();
}

class _MoodCheckInCardState extends State<MoodCheckInCard> {
  final _moodService = MoodService();
  final _authService = AuthService();
  final _noteController = TextEditingController();

  String? _selectedMood;
  String? _selectedLabel;
  bool _isSaving = false;

  final List<Map<String, String>> _moods = const [
    {'emoji': '😊', 'label': 'Great'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😢', 'label': 'Struggling'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a mood first.')),
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
    final fullName = userData?['fullName'] ?? 'Student';
    final section = userData?['section'] ?? '';

    final error = await _moodService.checkIn(
      mood: _selectedMood!,
      moodLabel: _selectedLabel!,
      note: _noteController.text.trim(),
      fullName: fullName,
      section: section,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _noteController.clear();
    setState(() {
      _selectedMood = null;
      _selectedLabel = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved. Thanks for sharing!')),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _moodService.getMyLatestCheckIn(),
      builder: (context, snapshot) {
        String? lastMood;
        String? lastLabel;
        Timestamp? lastTime;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final d = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          lastMood = d['mood'];
          lastLabel = d['moodLabel'];
          lastTime = d['createdAt'] as Timestamp?;
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite,
                        color: IsiaColors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: IsiaColors.ink,
                        ),
                      ),
                    ),
                    if (lastMood != null)
                      Text(lastMood,
                          style: const TextStyle(fontSize: 22)),
                  ],
                ),
                if (lastLabel != null && lastTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last check-in: $lastLabel • ${_formatTime(lastTime)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: IsiaColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _moods.map((m) {
                    final selected = _selectedMood == m['emoji'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedMood = m['emoji'];
                          _selectedLabel = m['label'];
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? IsiaColors.indigo.withOpacity(0.12)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? IsiaColors.indigo
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(m['emoji']!,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                m['label']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? IsiaColors.indigo
                                      : IsiaColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add a note (optional)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Check In'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}