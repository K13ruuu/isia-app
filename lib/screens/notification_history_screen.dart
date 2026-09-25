import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_history_service.dart';
import '../theme/isia_theme.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  final _service = NotificationHistoryService();
  final _authService = AuthService();
  String _filter = 'All';

  final List<String> _filters = [
    'All',
    'Reminder',
    'Urgent',
    'Inspiration',
    'Support',
  ];

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

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  bool _isVisibleFor(Map<String, dynamic> data, String studentSection) {
    final target = (data['targetSection'] ?? 'All').toString();
    if (target == 'All') return true;
    if (studentSection.isEmpty) return false;
    return target == studentSection;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final snap = await _service.getAnnouncements().first;
              final ids = snap.docs.map((d) => d.id).toList();
              await _service.markManyAsRead(ids);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All marked as read')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _authService.getUserData(user.uid),
        builder: (context, userSnap) {
          final section = (userSnap.data?['section'] as String?) ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: _service.getReadIds(),
            builder: (context, readSnap) {
              final readIds = <String>{};
              if (readSnap.hasData) {
                for (final d in readSnap.data!.docs) {
                  readIds.add(d.id);
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _service.getAnnouncements(),
                builder: (context, annSnap) {
                  if (annSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final all = annSnap.hasData ? annSnap.data!.docs : [];

                  // Filter by visibility and category
                  final visible = all.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!_isVisibleFor(data, section)) return false;
                    if (_filter != 'All' &&
                        data['category'] != _filter) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (all.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No notifications yet.'),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildFilterChips(),
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(
                                child: Text(
                                    'No notifications in this category.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 4, 12, 24),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final doc = visible[index];
                                  final data = doc.data()
                                      as Map<String, dynamic>;
                                  final category =
                                      data['category'] ?? 'Reminder';
                                  final isUnread =
                                      !readIds.contains(doc.id);

                                  return _buildCard(
                                    id: doc.id,
                                    data: data,
                                    category: category,
                                    isUnread: isUnread,
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
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = f == _filter;
          return ChoiceChip(
            label: Text(f),
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
    );
  }

  Widget _buildCard({
    required String id,
    required Map<String, dynamic> data,
    required String category,
    required bool isUnread,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (isUnread) {
            await _service.markAsRead(id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: _categoryColor(category),
                        child: Icon(_categoryIcon(category),
                            color: Colors.white, size: 20),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['title'] ?? '',
                      maxLines: null,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isUnread
                            ? IsiaColors.ink
                            : IsiaColors.ink.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['message'] ?? '',
                maxLines: null,
                softWrap: true,
                style: TextStyle(
                  color: isUnread
                      ? IsiaColors.ink.withOpacity(0.85)
                      : IsiaColors.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _categoryColor(category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        color: _categoryColor(category),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(data['createdAt'] as Timestamp?),
                    style: const TextStyle(
                        fontSize: 11, color: IsiaColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}