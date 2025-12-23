class ChatMessage {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'text': text,
        'sentAt': sentAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        fromUserId: json['fromUserId'] as String,
        toUserId: json['toUserId'] as String,
        text: json['text'] as String? ?? '',
        sentAt: DateTime.fromMillisecondsSinceEpoch(
          json['sentAt'] as int? ?? 0,
        ),
      );
}
