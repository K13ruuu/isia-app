import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/feedback_service.dart';
import '../../theme/isia_theme.dart';

class FeedbackCard extends StatefulWidget {
  const FeedbackCard({super.key});

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
  final _service = FeedbackService();
  final _authService = AuthService();
  final _messageController = TextEditingController();

  String _selectedCategory = 'Suggestion';
  bool _anonymous = false;
  bool _isSending = false;

  final List<String> _categories = [
    'Suggestion',
    'Concern',
    'Compliment',
    'Bug Report',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'Concern':
        return Colors.orange;
      case 'Compliment':
        return Colors.green;
      case 'Bug Report':
        return Colors.red;
      case 'Suggestion':
      default:
        return IsiaColors.indigo;
    }
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback.')),
      );
      return;
    }

    setState(() => _isSending = true);

    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isSending = false);
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final fullName = userData?['fullName'] ?? 'Student';
    final section = userData?['section'] ?? '';

    final error = await _service.submitFeedback(
      category: _selectedCategory,
      message: _messageController.text,
      anonymous: _anonymous,
      fullName: fullName,
      section: section,
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _messageController.clear();
    setState(() => _anonymous = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Feedback sent. Thank you for sharing!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.forum, color: IsiaColors.indigo, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: IsiaColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _categoryColor(c),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, concerns, or ideas...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v ?? false),
              title: const Text(
                'Submit anonymously',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Your name and section will be hidden.',
                style: TextStyle(fontSize: 11, color: IsiaColors.muted),
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}