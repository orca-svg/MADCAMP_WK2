class BoardPost {
  const BoardPost({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.isMine,
    this.empathyCount = 0,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final bool isMine;
  final int empathyCount;
}

abstract class BoardRepository {
  List<BoardPost> fetchOpen();
  List<BoardPost> fetchMine();
  BoardPost? findById(String id);
  BoardPost submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  });
}

class MockBoardRepository implements BoardRepository {
  final List<BoardPost> _openPosts = [
    BoardPost(
      id: 'post_001',
      title: '밤 라디오를 켜는 이유',
      body: '하루가 너무 길게 느껴져서, 고요한 주파수를 찾고 있어요.',
      tags: const ['#외로움 🌙'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isMine: false,
      empathyCount: 12,
    ),
    BoardPost(
      id: 'post_002',
      title: '출근길에 듣는 숨소리',
      body: '버스 창밖이 너무 빠르게 흘러가요. 숨을 고르고 싶어요.',
      tags: const ['#학업 📚', '#관계 🤝'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isMine: true,
      empathyCount: 4,
    ),
    BoardPost(
      id: 'post_003',
      title: '오늘은 신호가 약해요',
      body: '말을 붙잡아도 사라지는 기분이에요. 누군가 듣고 있을까요?',
      tags: const ['#불안 😰'],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isMine: false,
      empathyCount: 21,
    ),
  ];
  final List<BoardPost> _myPosts = [];

  MockBoardRepository() {
    _myPosts
      ..clear()
      ..addAll(_openPosts.where((post) => post.isMine));
  }

  @override
  List<BoardPost> fetchOpen() => List<BoardPost>.from(_openPosts);

  @override
  List<BoardPost> fetchMine() => List<BoardPost>.from(_myPosts);

  @override
  BoardPost? findById(String id) {
    for (final post in _openPosts) {
      if (post.id == id) return post;
    }
    return null;
  }

  @override
  BoardPost submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  }) {
    final post = BoardPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title.isEmpty ? '새로운 사연' : title,
      body: body,
      tags: tags.isEmpty ? const ['#그냥_들어줘 🎧'] : List<String>.from(tags),
      createdAt: DateTime.now(),
      isMine: true,
      empathyCount: 0,
    );
    _myPosts.insert(0, post);
    if (publish) {
      _openPosts.insert(0, post);
    }
    return post;
  }
}
