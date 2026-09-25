import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/search_service.dart';
import '../../theme/isia_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _searchService = SearchService();
  final _authService = AuthService();

  bool _isSearching = false;
  bool _hasSearched = false;
  String _query = '';
  Map<String, List<Map<String, dynamic>>> _results = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _query = q;
    });

    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isSearching = false);
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final role = userData?['role'] ?? 'student';
    final section = userData?['section'] ?? '';

    final results = await _searchService.searchAll(
      keyword: q,
      role: role,
      section: section,
    );

    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  int get _totalResults =>
      _results.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: 'Search announcements, schedule, deadlines...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _runSearch,
              ),
            ),
          ),
        ),

        if (_isSearching)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!_hasSearched)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Type a keyword to search across ISIA.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: IsiaColors.muted),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Try: "science", "quiz", "guidance", "foundation"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: IsiaColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_totalResults == 0)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No results for "$_query".',
                      style: const TextStyle(color: IsiaColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  '$_totalResults result${_totalResults == 1 ? '' : 's'} for "$_query"',
                  style: const TextStyle(
                    color: IsiaColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildSection('Announcements', Icons.campaign,
                    IsiaColors.indigo, _results['announcements']!),
                ..._buildSection('Schedule', Icons.calendar_today,
                    IsiaColors.blue, _results['schedules']!),
                ..._buildSection('Deadlines', Icons.assignment,
                    Colors.orange, _results['deadlines']!),
                ..._buildSection('Events', Icons.event,
                    Colors.teal, _results['events']!),
                ..._buildSection('Contacts', Icons.support_agent,
                    Colors.green, _results['contacts']!),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      ...items.map((item) => _buildCard(title, color, item)),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildCard(String type, Color color, Map<String, dynamic> item) {
    String primary = '';
    String secondary = '';

    switch (type) {
      case 'Announcements':
        primary = item['title'] ?? '';
        secondary = item['message'] ?? '';
        break;
      case 'Schedule':
        primary = item['subject'] ?? '';
        secondary =
            '${item['day']} ${item['startTime']}–${item['endTime']} • ${item['room']}';
        break;
      case 'Deadlines':
        primary = '${item['type']}: ${item['title']}';
        secondary = '${item['subject']} • ${item['section']}';
        break;
      case 'Events':
        primary = item['title'] ?? '';
        final ts = item['date'] as Timestamp?;
        final dateStr = ts != null
            ? '${ts.toDate().month}/${ts.toDate().day}/${ts.toDate().year}'
            : '';
        secondary = '$dateStr • ${item['location']}';
        break;
      case 'Contacts':
        primary = item['name'] ?? '';
        secondary = '${item['role']} • ${item['phone']}';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: IsiaColors.ink,
                    ),
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: IsiaColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}