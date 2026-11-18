
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    this.image,
    this.createdAt,
  });

  final int id;
  final String sender;
  final String content;
  final String? image;
  final DateTime? createdAt;

  bool get isUser => sender == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      sender: json['sender'] as String,
      content: json['content'] as String? ?? '',
      image: json['image'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
