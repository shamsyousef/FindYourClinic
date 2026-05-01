import '../../domain/entities/ai_chat_message.dart';

/// Sealed state for AiChatCubit.
sealed class AiChatState {
  const AiChatState();
}

class AiChatInitial extends AiChatState {}

class AiChatLoading extends AiChatState {}

class AiChatLoaded extends AiChatState {
  final List<AiChatMessage> messages;
  const AiChatLoaded(this.messages);
}

class AiChatSending extends AiChatState {
  /// Optimistic list with the user message already appended.
  final List<AiChatMessage> messages;
  const AiChatSending(this.messages);
}

class AiChatError extends AiChatState {
  final String message;
  const AiChatError(this.message);
}
