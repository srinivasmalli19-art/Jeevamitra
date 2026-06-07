import 'user_model.dart';
import 'animal_listing.dart';

enum MessageType { text, image }

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
  });
}

class ChatConversation {
  final String id;
  final AnimalListing listing;
  final UserModel otherUser;
  final List<ChatMessage> messages;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.listing,
    required this.otherUser,
    required this.messages,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  String get lastMessageText {
    if (messages.isEmpty) return '';
    return messages.last.content;
  }
}
