import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/announcement_service.dart';
import '../services/poll_service.dart';
import 'login_screen.dart';
import 'notification_history_screen.dart';
import 'student/schedule_screen.dart';
import 'student/deadlines_screen.dart';
import 'student/events_screen.dart';
import 'student/support_screen.dart';
import 'student/search_screen.dart';
import 'student/mood_checkin_card.dart';
import 'student/quote_card.dart';
import 'student/poll_card.dart';
import '../theme/isia_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      const _AnnouncementsTab(),
      const SearchScreen(),
      const ScheduleScreen(),
      const DeadlinesScreen(),
      const EventsScreen(),
      const SupportScreen(),
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
                Text('STUDENT PORTAL',
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
        indicatorColor: const Color(0xFFE0E7FF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.campaign), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.assignment), label: 'Deadlines'),
          NavigationDestination(
              icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(
              icon: Icon(Icons.support_agent), label: 'Support'),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Urgent':
        return Icons.warning;
      case 'Reminder':
        return Icons.notifications;
      case 'Inspiration':
        return Icons.lightbulb;
      case 'Support':
        return Icons.support_agent;
      default:
        return Icons.campaign;
    }
  }

  bool _isVisibleFor(Map<String, dynamic> data, String studentSection) {
    final target = (data['targetSection'] ?? 'All').toString();
    if (target == 'All') return true;
    if (studentSection.isEmpty) return false;
    return target == studentSection;
  }

  @override
  Widget build(BuildContext context) {
    final announcementService = AnnouncementService();
    final pollService = PollService();
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Not signed in.'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user.uid),
      builder: (context, userSnap) {
        final studentSection =
            (userSnap.data?['section'] as String?) ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: announcementService.getAnnouncements(),
          builder: (context, annSnap) {
            if (annSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = annSnap.hasData ? annSnap.data!.docs : [];
            final visible = all.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _isVisibleFor(data, studentSection);
            }).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: pollService.getAllPolls(),
              builder: (context, pollSnap) {
                final openPolls =
                    (pollSnap.hasData ? pollSnap.data!.docs : [])
                        .where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  if (data['isOpen'] != true) return false;
                  return _isVisibleFor(data, studentSection);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const QuoteCard(),
                    const MoodCheckInCard(),

                    if (openPolls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PollCard(
                        pollId: openPolls.first.id,
                        data: openPolls.first.data()
                            as Map<String, dynamic>,
                      ),
                    ],

                    const SizedBox(height: 8),

                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No announcements yet.'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...visible.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final category =
                            data['category'] ?? 'Reminder';

                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            _categoryColor(category),
                                        child: Icon(
                                            _categoryIcon(category),
                                            color: Colors.white,
                                            size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? '',
                                          maxLines: null,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data['message'] ?? '',
                                    maxLines: null,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              _categoryColor(category)
                                                  .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _categoryColor(
                                                category),
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          data['postedByName'] ??
                                              'Admin',
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ],
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
            );
          },
        );
      },
    );
  }
}