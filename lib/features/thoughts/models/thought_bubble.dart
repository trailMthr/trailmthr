class ThoughtBubble {
  final String id;
  String title;
  String body;
  String? parentId;
  List<String> children;

  // 🎨 bubble color (hex string)
  String color;

  ThoughtBubble({
    required this.id,
    required this.title,
    required this.body,
    this.parentId,
    this.children = const [],
    this.color = "#888888",
  });
}
