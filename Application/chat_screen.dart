class ChatMessage {
  final String? id;
  final String role;
  final String content;
  final String? conversationId;
  final DateTime? createdDate;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.conversationId,
    this.createdDate,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    conversationId: json['conversation_id'],
    createdDate: DateTime.tryParse(json['created_date'] ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'conversation_id': conversationId,
  };
}
