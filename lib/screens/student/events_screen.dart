import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/isia_theme.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  bool _isVisibleFor(Map<String, dynamic> data, String studentSection) {
    final target = (data['targetSection'] ?? 'All').toString();
    if (target == 'All') return true;
    if (studentSection.isEmpty) return false;
    return target == studentSection;
  }

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Not signed in.'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user.uid),
      builder: (context, userSnap) {
        final section = (userSnap.data?['section'] as String?) ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: eventService.getUpcomingEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.hasData ? snapshot.data!.docs : [];
            final visible = all.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _isVisibleFor(data, section);
            }).toList();

            if (visible.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No upcoming events.'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final data =
                    visible[index].data() as Map<String, dynamic>;
                final ts = data['date'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.event,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 10),
                        _infoRow(Icons.calendar_today, _formatDate(ts)),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.access_time,
                          '${data['startTime']} – ${data['endTime']}',
                        ),
                        const SizedBox(height: 4),
                        _infoRow(Icons.location_on, data['location'] ?? ''),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: IsiaColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: IsiaColors.muted),
          ),
        ),
      ],
    );
  }
}