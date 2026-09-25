import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/contact_service.dart';
import 'feedback_card.dart';
import '../../theme/isia_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactService = ContactService();

    return StreamBuilder<QuerySnapshot>(
      stream: contactService.getContacts(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData ? snapshot.data!.docs : [];

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const FeedbackCard(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'School Contacts',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: IsiaColors.ink),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No support contacts yet.',
                  style: TextStyle(color: IsiaColors.muted),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.support_agent,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: IsiaColors.ink,
                                      ),
                                    ),
                                    Text(
                                      data['role'] ?? '',
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
                          const SizedBox(height: 10),
                          if ((data['phone'] ?? '')
                              .toString()
                              .isNotEmpty)
                            _row(Icons.phone, data['phone']),
                          if ((data['email'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _row(Icons.email, data['email']),
                          ],
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
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.green),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}