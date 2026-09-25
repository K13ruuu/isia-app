import 'package:cloud_firestore/cloud_firestore.dart';

class VerseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 31 built-in entries — mix of NIV Bible verses and motivational quotes
  static const List<Map<String, String>> _builtIn = [
    {
      'text': 'I can do all this through him who gives me strength.',
      'author': 'Philippians 4:13 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Trust in the Lord with all your heart and lean not on your own understanding.',
      'author': 'Proverbs 3:5 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'The Lord is my shepherd, I lack nothing.',
      'author': 'Psalm 23:1 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      'author': 'Joshua 1:9 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'For I know the plans I have for you, plans to prosper you and not to harm you, plans to give you hope and a future.',
      'author': 'Jeremiah 29:11 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Your word is a lamp for my feet, a light on my path.',
      'author': 'Psalm 119:105 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Cast all your anxiety on him because he cares for you.',
      'author': '1 Peter 5:7 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'The joy of the Lord is your strength.',
      'author': 'Nehemiah 8:10 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'And we know that in all things God works for the good of those who love him.',
      'author': 'Romans 8:28 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Do everything in love.',
      'author': '1 Corinthians 16:14 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Every small step you take today brings you closer to your goals.',
      'author': 'ISIA',
      'type': 'quote',
    },
    {
      'text': 'Believe in yourself. You are capable of more than you know.',
      'author': 'ISIA',
      'type': 'quote',
    },
    {
      'text': 'You don\'t have to be great to start, but you have to start to be great.',
      'author': 'Zig Ziglar',
      'type': 'quote',
    },
    {
      'text': 'The expert in anything was once a beginner.',
      'author': 'Helen Hayes',
      'type': 'quote',
    },
    {
      'text': 'The future belongs to those who believe in the beauty of their dreams.',
      'author': 'Eleanor Roosevelt',
      'type': 'quote',
    },
    {
      'text': 'Education is the most powerful weapon which you can use to change the world.',
      'author': 'Nelson Mandela',
      'type': 'quote',
    },
    {
      'text': 'I have fought the good fight, I have finished the race, I have kept the faith.',
      'author': '2 Timothy 4:7 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Whatever you do, work at it with all your heart, as working for the Lord.',
      'author': 'Colossians 3:23 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Let all that you do be done in love.',
      'author': '1 Corinthians 16:14 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Do not be anxious about tomorrow, for tomorrow will be anxious for itself.',
      'author': 'Matthew 6:34 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Success is the sum of small efforts repeated day in and day out.',
      'author': 'Robert Collier',
      'type': 'quote',
    },
    {
      'text': 'The Lord is my light and my salvation — whom shall I fear?',
      'author': 'Psalm 27:1 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Whatever is true, whatever is noble, whatever is right, whatever is pure — think about such things.',
      'author': 'Philippians 4:8 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Start where you are. Use what you have. Do what you can.',
      'author': 'Arthur Ashe',
      'type': 'quote',
    },
    {
      'text': 'Be still, and know that I am God.',
      'author': 'Psalm 46:10 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'The steadfast love of the Lord never ceases; his mercies never come to an end.',
      'author': 'Lamentations 3:22 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Do something today that your future self will thank you for.',
      'author': 'ISIA',
      'type': 'quote',
    },
    {
      'text': 'Ask and it will be given to you; seek and you will find; knock and the door will be opened to you.',
      'author': 'Matthew 7:7 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'In all your ways submit to him, and he will make your paths straight.',
      'author': 'Proverbs 3:6 (NIV)',
      'type': 'verse',
    },
    {
      'text': 'Keep your face always toward the sunshine, and shadows will fall behind you.',
      'author': 'Walt Whitman',
      'type': 'quote',
    },
    {
      'text': 'The Lord bless you and keep you; the Lord make his face shine on you.',
      'author': 'Numbers 6:24-25 (NIV)',
      'type': 'verse',
    },
  ];

  Map<String, String> getTodayEntry() {
    final day = DateTime.now().day;
    final index = (day - 1) % _builtIn.length;
    return _builtIn[index];
  }

  Stream<QuerySnapshot> getCustomVerses() {
    return _firestore
        .collection('quotes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get custom verses targeted to a specific section (or 'All')
  Stream<QuerySnapshot> getCustomVersesForSection(String section) {
    return _firestore
        .collection('quotes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String?> addVerse({
    required String text,
    required String author,
    required String type, // 'verse' or 'quote'
    required String postedBy,
    required String postedByName,
    String targetSection = 'All',
  }) async {
    try {
      await _firestore.collection('quotes').add({
        'text': text.trim(),
        'author': author.trim().isEmpty ? 'ISIA' : author.trim(),
        'type': type,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'targetSection': targetSection,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to add verse: $e';
    }
  }

  Future<void> deleteVerse(String docId) async {
    await _firestore.collection('quotes').doc(docId).delete();
  }
}