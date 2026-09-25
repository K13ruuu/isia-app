import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../theme/isia_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _scheduleService = ScheduleService();

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Preselect today if it's a weekday, otherwise Monday
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // Monday=0 … Friday=4
    final initialIndex = (todayIndex >= 0 && todayIndex <= 4) ? todayIndex : 0;
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(user.uid),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final section = (userSnap.data?['section'] as String?) ?? '';

        if (section.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No section assigned. Please contact the registrar.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              color: const Color(0xFFF5F3FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: IsiaColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Your weekly class schedule',
                    style: TextStyle(
                        fontSize: 12, color: IsiaColors.muted),
                  ),
                ],
              ),
            ),

            // Day tabs
            Container(
              color: const Color(0xFFF5F3FF),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: IsiaColors.indigo,
                unselectedLabelColor: IsiaColors.muted,
                indicatorColor: IsiaColors.indigo,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: _days.map((d) => Tab(text: d)).toList(),
              ),
            ),

            // Body
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _scheduleService.getScheduleForSection(section),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No schedule posted yet.'),
                        ],
                      ),
                    );
                  }

                  // Group by day
                  final byDay =
                      <String, List<Map<String, dynamic>>>{};
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final day = (data['day'] ?? '').toString();
                    if (day.isEmpty) continue;
                    byDay.putIfAbsent(day, () => []).add(data);
                  }

                  // Sort each day's classes
                  for (final list in byDay.values) {
                    list.sort((a, b) => (a['startTime'] ?? '')
                        .compareTo(b['startTime'] ?? ''));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: _days.map((day) {
                      final classes = byDay[day] ?? [];
                      if (classes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_busy,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('No classes on $day.'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: classes.length,
                        itemBuilder: (context, i) {
                          final c = classes[i];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: IsiaColors.indigo
                                          .withOpacity(0.10),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          (c['startTime'] ?? '')
                                              .substring(0, 2),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: IsiaColors.indigo,
                                          ),
                                        ),
                                        Text(
                                          (c['startTime'] ?? '')
                                                  .length >=
                                              5
                                              ? (c['startTime'] ?? '')
                                                  .substring(3, 5)
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: IsiaColors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['subject'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w800,
                                            color: IsiaColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c['startTime']} – ${c['endTime']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: IsiaColors.muted,
                                          ),
                                        ),
                                        if ((c['room'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            'Room: ${c['room']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: IsiaColors.muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}