import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isOtherPartyTyping;
  final ChatMessage? replyingTo;

  const ChatLoaded(
    this.messages, {
    this.isOtherPartyTyping = false,
    this.replyingTo,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isOtherPartyTyping,
    ChatMessage? replyingTo,
    bool clearReplyingTo = false,
  }) =>
      ChatLoaded(
        messages ?? this.messages,
        isOtherPartyTyping: isOtherPartyTyping ?? this.isOtherPartyTyping,
        replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      );

  @override
  List<Object?> get props => [messages, isOtherPartyTyping, replyingTo];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
