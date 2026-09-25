import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/verse_service.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key});

  IconData _iconFor(String type) {
    return type == 'verse' ? Icons.menu_book : Icons.auto_awesome;
  }

  String _labelFor(String type, bool isCustom) {
    if (isCustom) return 'FROM YOUR TEACHER';
    return type == 'verse' ? 'VERSE OF THE DAY' : 'DAILY INSPIRATION';
  }

  bool _isVisibleFor(Map<String, dynamic> data, String studentSection) {
    final target = (data['targetSection'] ?? 'All').toString();
    if (target == 'All') return true;
    if (studentSection.isEmpty) return false;
    return target == studentSection;
  }

  @override
  Widget build(BuildContext context) {
    final service = VerseService();
    final authService = AuthService();
    final user = authService.currentUser;
    final builtIn = service.getTodayEntry();

    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user.uid),
      builder: (context, userSnap) {
        final section = (userSnap.data?['section'] as String?) ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: service.getCustomVerses(),
          builder: (context, snapshot) {
            String text = builtIn['text'] ?? '';
            String author = builtIn['author'] ?? 'ISIA';
            String type = builtIn['type'] ?? 'quote';
            bool isCustom = false;

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final matching = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _isVisibleFor(data, section);
              }).toList();

              if (matching.isNotEmpty) {
                final latest =
                    matching.first.data() as Map<String, dynamic>;
                text = latest['text'] ?? text;
                author = latest['author'] ?? author;
                type = latest['type'] ?? type;
                isCustom = true;
              }
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconFor(type),
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _labelFor(type, isCustom),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '"$text"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '— $author',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}