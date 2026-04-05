class MessageEntity {
  final String text;
  final bool isUser;
  final String? grammarFeedback;

  const MessageEntity({
    required this.text, 
    required this.isUser,
    this.grammarFeedback,
  });
}
