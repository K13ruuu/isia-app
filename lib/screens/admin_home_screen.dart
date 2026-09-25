import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/announcement_service.dart';
import '../services/notification_service.dart';
import '../services/mood_service.dart';
import '../services/feedback_service.dart';
import 'login_screen.dart';
import 'notification_history_screen.dart';
import 'admin/manage_schedule_screen.dart';
import 'admin/manage_deadlines_screen.dart';
import 'admin/manage_events_screen.dart';
import 'admin/manage_support_screen.dart';
import 'admin/manage_verses_screen.dart';
import 'admin/manage_polls_screen.dart';
import 'student/search_screen.dart';
import '../theme/isia_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _AdminHomeTab(),
      const SearchScreen(),
      const ManageScheduleScreen(),
      const ManageDeadlinesScreen(),
      const ManageEventsScreen(),
      const ManageSupportScreen(),
      const ManageVersesScreen(),
      const ManagePollsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            IsiaBrandMark(size: 34),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ISIA'),
                Text('TEACHER PORTAL',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: IsiaColors.muted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notification History',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationHistoryScreen()),
              );
            },
          ),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 72,
        indicatorColor: const Color(0xFFEDE9FE),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.campaign), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today), label: 'Sched'),
          NavigationDestination(
              icon: Icon(Icons.assignment), label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(
              icon: Icon(Icons.support_agent), label: 'Help'),
          NavigationDestination(
              icon: Icon(Icons.menu_book), label: 'Verses'),
          NavigationDestination(
              icon: Icon(Icons.poll), label: 'Polls'),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  final _authService = AuthService();
  final _announcementService = AnnouncementService();
  final _notificationService = NotificationService();
  final _moodService = MoodService();
  final _feedbackService = FeedbackService();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Reminder';
  bool _isPosting = false;
  bool _loadingSections = true;
  List<String> _availableSections = ['All'];
  List<String> _myAssignedSections = [];
  String _targetSection = 'All';
  String _displayName = 'Teacher';

  final List<String> _categories = [
    'Reminder',
    'Urgent',
    'Inspiration',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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
        _availableSections = ['All', ...all];
        _myAssignedSections = const [];
        _displayName = display;
        _loadingSections = false;
      });
    } else {
      setState(() {
        _availableSections = ['All', ...sections];
        _myAssignedSections = sections;
        _displayName = display;
        _loadingSections = false;
      });
    }
  }

  // Check whether a mood check-in is from a section this teacher handles
  bool _canSeeMood(Map<String, dynamic> data) {
    // Teachers with no assigned sections see everything (backward compat)
    if (_myAssignedSections.isEmpty) return true;
    final s = (data['section'] ?? '').toString();
    return _myAssignedSections.contains(s);
  }

  bool _isToday(Timestamp? ts) {
    if (ts == null) return false;
    final dt = ts.toDate();
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Urgent':
        return Colors.red;
      case 'Reminder':
        return Colors.orange;
      case 'Inspiration':
        return IsiaColors.purple;
      case 'Support':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _feedbackColor(String category) {
    switch (category) {
      case 'Concern':
        return Colors.orange;
      case 'Compliment':
        return Colors.green;
      case 'Bug Report':
        return Colors.red;
      default:
        return IsiaColors.indigo;
    }
  }

  Color _badgeColor(String section) {
    return section == 'All' ? IsiaColors.indigo : Colors.teal;
  }

  Future<void> _postAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isPosting = false);
      return;
    }

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    String? error = await _announcementService.createAnnouncement(
      title: title,
      message: message,
      category: _selectedCategory,
      postedBy: user.uid,
      postedByName: _displayName,
      targetSection: _targetSection,
    );

    if (error != null) {
      setState(() => _isPosting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _titleController.clear();
    _messageController.clear();

    final result = await _notificationService.sendNotificationToAllStudents(
      title: title,
      body: message,
      targetSection: _targetSection,
    );

    setState(() => _isPosting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Announcement posted! $result')),
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text(
            'This will permanently remove it for all students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await _announcementService.deleteAnnouncement(docId);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement deleted.')),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSections) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUid = _authService.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Announcement composer ----
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF5F3FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Post an Announcement',
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
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isPosting ? null : _postAnnouncement,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label:
                      Text(_isPosting ? 'Posting...' : 'Post Announcement'),
                ),
              ],
            ),
          ),

          // ---- Feedback Inbox ----
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Feedback Inbox',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _feedbackService.getAllFeedback(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.hasData
                  ? snapshot.data!.docs
                  : <QueryDocumentSnapshot>[];

              if (docs.isEmpty) {
                return const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('No feedback yet.',
                      style: TextStyle(color: IsiaColors.muted)),
                );
              }

              return Column(
                children: docs.take(20).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] ?? 'Suggestion';
                  final anonymous = data['anonymous'] == true;
                  final name = data['fullName'] ?? 'Student';
                  final section = data['section'] ?? '';
                  final message = data['message'] ?? '';
                  final ts = data['createdAt'] as Timestamp?;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _feedbackColor(category)
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _feedbackColor(category),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(ts),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: IsiaColors.muted),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  onPressed: () async {
                                    await _feedbackService
                                        .deleteFeedback(doc.id);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: const TextStyle(
                                  color: IsiaColors.ink, fontSize: 13.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  anonymous
                                      ? Icons.visibility_off
                                      : Icons.person,
                                  size: 12,
                                  color: IsiaColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  anonymous
                                      ? 'Anonymous'
                                      : '$name${section.isNotEmpty ? ' • $section' : ''}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: IsiaColors.muted),
                                ),
                              ],
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

          // ---- Posted announcements (only mine) ----
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'My Posted Announcements',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _announcementService.getAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final all = snapshot.hasData ? snapshot.data!.docs : [];
              final mine = all
                  .where((d) =>
                      (d.data() as Map<String, dynamic>)['postedBy'] ==
                      currentUid)
                  .toList();

              if (mine.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('You haven\'t posted any announcements yet.'),
                );
              }

              return Column(
                children: mine.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] ?? 'Reminder';
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
                                CircleAvatar(
                                  backgroundColor:
                                      _categoryColor(category),
                                  child: const Icon(Icons.campaign,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(doc.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(data['message'] ?? ''),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '$category • by ${data['postedByName'] ?? 'Teacher'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _categoryColor(category),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _badgeColor(ts)
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(8),
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
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ---- Mood Check-Ins (today only, from my sections) ----
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Mood Check-Ins (Today)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: IsiaColors.ink),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _moodService.getAllCheckIns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final all = snapshot.hasData
                  ? snapshot.data!.docs
                  : <QueryDocumentSnapshot>[];

              // Filter: today only + from sections this teacher handles
              final visible = all.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (!_isToday(ts)) return false;
                if (!_canSeeMood(data)) return false;
                return true;
              }).toList();

              if (visible.isEmpty) {
                return const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'No mood check-ins today from your sections.',
                    style: TextStyle(color: IsiaColors.muted),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Text(
                      '${visible.length} check-in${visible.length == 1 ? '' : 's'} today from your sections',
                      style: const TextStyle(
                        color: IsiaColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...visible.take(20).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final mood = data['mood'] ?? '🙂';
                    final label = data['moodLabel'] ?? '';
                    final name = data['fullName'] ?? 'Student';
                    final section = data['section'] ?? '';
                    final note = (data['note'] ?? '').toString();
                    final ts = data['createdAt'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mood,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$name • $label',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: IsiaColors.ink,
                                      ),
                                    ),
                                    Text(
                                      '$section • ${_formatTime(ts)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: IsiaColors.muted,
                                      ),
                                    ),
                                    if (note.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        note,
                                        style: const TextStyle(
                                            color: IsiaColors.ink,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}