import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/deadline_service.dart';
import '../../theme/isia_theme.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  String _filter = 'All';

  final List<String> _filters = ['All', 'Exam', 'Quiz', 'Activity'];

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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Exam':
        return Icons.assignment_late;
      case 'Quiz':
        return Icons.quiz;
      case 'Activity':
        return Icons.task;
      default:
        return Icons.assignment;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _daysUntil(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final due = ts.toDate();
    final diff =
        due.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'In $diff days';
  }

  int _urgencyLevel(Timestamp? ts) {
    if (ts == null) return 3;
    final now = DateTime.now();
    final due = ts.toDate();
    final diff =
        due.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 0;
    if (diff <= 2) return 1;
    if (diff <= 7) return 2;
    return 3;
  }

  Color _urgencyColor(int level) {
    switch (level) {
      case 0:
        return Colors.red.shade900;
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return IsiaColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final deadlineService = DeadlineService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final section = (userSnapshot.data?['section'] as String?) ?? '';

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

        return StreamBuilder<QuerySnapshot>(
          stream: deadlineService.getDeadlinesForSection(section),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            final all = snapshot.hasData ? snapshot.data!.docs : [];

            if (all.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_turned_in,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('No deadlines for $section yet.'),
                  ],
                ),
              );
            }

            // Sort client-side by dueDate ascending
            final sorted = all.toList()
              ..sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                final ta = da['dueDate'] as Timestamp?;
                final tb = db['dueDate'] as Timestamp?;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return ta.compareTo(tb);
              });

            // Count per type
            final counts = {
              'All': sorted.length,
              'Exam': 0,
              'Quiz': 0,
              'Activity': 0,
            };
            for (final doc in sorted) {
              final data = doc.data() as Map<String, dynamic>;
              final type = (data['type'] ?? 'Activity').toString();
              if (counts.containsKey(type)) {
                counts[type] = counts[type]! + 1;
              }
            }

            // Apply filter
            final visible = _filter == 'All'
                ? sorted
                : sorted.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['type'] ?? 'Activity') == _filter;
                  }).toList();

            return Column(
              children: [
                _buildFilterChips(counts),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_alt_off,
                                  size: 80, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('No $_filter deadlines.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final data = visible[index].data()
                                as Map<String, dynamic>;
                            final type =
                                data['type'] ?? 'Activity';
                            final ts = data['dueDate'] as Timestamp?;
                            final urgency = _urgencyLevel(ts);

                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
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
                                              _typeColor(type),
                                          child: Icon(
                                              _typeIcon(type),
                                              color: Colors.white,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                data['title'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                data['subject'] ?? '',
                                                style:
                                                    const TextStyle(
                                                  fontSize: 12,
                                                  color: IsiaColors
                                                      .muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _typeColor(type)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  _typeColor(type),
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if ((data['description'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(data['description']),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: IsiaColors.muted),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(ts),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  IsiaColors.muted),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _daysUntil(ts),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                _urgencyColor(urgency),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips(Map<String, int> counts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final selected = f == _filter;
            final count = counts[f] ?? 0;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.25)
                            : IsiaColors.ink.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : IsiaColors.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: IsiaColors.indigo,
              labelStyle: TextStyle(
                color: selected ? Colors.white : IsiaColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
    );
  }
}