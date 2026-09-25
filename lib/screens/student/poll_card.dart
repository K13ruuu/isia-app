import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/poll_service.dart';
import '../../theme/isia_theme.dart';

class PollCard extends StatefulWidget {
  const PollCard({
    super.key,
    required this.pollId,
    required this.data,
  });

  final String pollId;
  final Map<String, dynamic> data;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  final _service = PollService();
  int? _myVote;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _loadMyVote();
  }

  Future<void> _loadMyVote() async {
    final vote = await _service.getMyVote(widget.pollId);
    if (!mounted) return;
    setState(() => _myVote = vote);
  }

  Future<void> _vote(int index) async {
    if (widget.data['isOpen'] != true) return;
    setState(() => _isVoting = true);

    final error = await _service.submitVote(
      pollId: widget.pollId,
      optionIndex: index,
    );

    if (!mounted) return;
    setState(() {
      _isVoting = false;
      if (error == null) _myVote = index;
    });

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.data['question'] ?? '';
    final options = (widget.data['options'] as List? ?? []).cast<String>();
    final isOpen = widget.data['isOpen'] == true;

    return StreamBuilder<QuerySnapshot>(
      stream: _service.getVotes(widget.pollId),
      builder: (context, snapshot) {
        final votes = snapshot.hasData ? snapshot.data!.docs : [];

        final counts = List<int>.filled(options.length, 0);
        for (final v in votes) {
          final data = v.data() as Map<String, dynamic>;
          final idx = (data['optionIndex'] as num?)?.toInt();
          if (idx != null && idx >= 0 && idx < counts.length) {
            counts[idx]++;
          }
        }
        final total = counts.fold<int>(0, (a, b) => a + b);

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll,
                        color: IsiaColors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick Poll',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isOpen
                              ? IsiaColors.indigo
                              : IsiaColors.muted,
                        ),
                      ),
                    ),
                    if (!isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: IsiaColors.muted.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'CLOSED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: IsiaColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: IsiaColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(options.length, (i) {
                  final option = options[i];
                  final count = counts[i];
                  final pct = total == 0 ? 0.0 : count / total;
                  final selected = _myVote == i;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: (isOpen && !_isVoting) ? () => _vote(i) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selected
                              ? IsiaColors.indigo.withOpacity(0.10)
                              : const Color(0xFFF8FAFC),
                          border: Border.all(
                            color: selected
                                ? IsiaColors.indigo
                                : const Color(0xFFE2E8F0),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: selected
                                      ? IsiaColors.indigo
                                      : IsiaColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: IsiaColors.ink,
                                    ),
                                  ),
                                ),
                                if (_myVote != null)
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? IsiaColors.indigo
                                          : IsiaColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                            if (_myVote != null) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor:
                                      const Color(0xFFE2E8F0),
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          IsiaColors.indigo),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$total vote${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11, color: IsiaColors.muted),
                    ),
                    const Spacer(),
                    if (_myVote != null)
                      const Text(
                        'You voted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: IsiaColors.indigo,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}