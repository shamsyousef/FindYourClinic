import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final SendImageMessageUseCase _sendImageMessageUseCase;
  final SendVideoMessageUseCase _sendVideoMessageUseCase;
  final SendVoiceMessageUseCase _sendVoiceMessageUseCase;
  final ReactToMessageUseCase _reactToMessageUseCase;
  final MarkConversationAsReadUseCase _markConversationAsReadUseCase;
  final IChatRepository _chatRepository;

  final String conversationId;
  final String? currentUserId;

  StreamSubscription? _messageReceivedSubscription;
  StreamSubscription? _messagesReadSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _reactionSubscription;
  Timer? _typingStopTimer;
  bool _isCurrentlyTyping = false;
  int _tempCounter = 0;

  ChatCubit({
    required this.conversationId,
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required SendImageMessageUseCase sendImageMessageUseCase,
    required SendVideoMessageUseCase sendVideoMessageUseCase,
    required SendVoiceMessageUseCase sendVoiceMessageUseCase,
    required ReactToMessageUseCase reactToMessageUseCase,
    required MarkConversationAsReadUseCase markConversationAsReadUseCase,
    required IChatRepository chatRepository,
    this.currentUserId,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _sendImageMessageUseCase = sendImageMessageUseCase,
        _sendVideoMessageUseCase = sendVideoMessageUseCase,
        _sendVoiceMessageUseCase = sendVoiceMessageUseCase,
        _reactToMessageUseCase = reactToMessageUseCase,
        _markConversationAsReadUseCase = markConversationAsReadUseCase,
        _chatRepository = chatRepository,
        super(ChatInitial());

  void init() async {
    emit(ChatLoading());

    await _chatRepository.joinConversation(conversationId);
    await _markConversationAsReadUseCase(conversationId);

    final result = await _getMessagesUseCase(conversationId);
    if (result is Success<List<ChatMessage>>) {
      emit(ChatLoaded(result.data));
      _listenToRealtimeEvents();
    } else if (result is Error<List<ChatMessage>>) {
      emit(ChatError(result.failure.message));
    }
  }

  void _listenToRealtimeEvents() {
    _messageReceivedSubscription?.cancel();
    _messagesReadSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionSubscription?.cancel();

    _messageReceivedSubscription =
        _chatRepository.onMessageReceived.listen((newMessage) {
      if (newMessage.conversationId != conversationId) return;
      if (state is! ChatLoaded) return;

      final current = state as ChatLoaded;
      if (current.messages.any((m) => m.id == newMessage.id)) return;

      emit(current.copyWith(
        messages: [...current.messages, newMessage],
        isOtherPartyTyping: false,
      ));
      _markConversationAsReadUseCase(conversationId);
    });

    _messagesReadSubscription =
        _chatRepository.onMessagesRead.listen((eventConvId) {
      if (eventConvId != conversationId) return;
      if (state is! ChatLoaded) return;

      final current = state as ChatLoaded;
      final updated = current.messages
          .map((msg) => !msg.isRead ? msg.copyWith(isRead: true) : msg)
          .toList();
      emit(current.copyWith(messages: updated));
    });

    _typingSubscription = _chatRepository.onTyping.listen((isTyping) {
      if (state is! ChatLoaded) return;
      emit((state as ChatLoaded).copyWith(isOtherPartyTyping: isTyping));
      if (isTyping) {
        _typingStopTimer?.cancel();
        _typingStopTimer = Timer(const Duration(seconds: 4), () {
          if (state is ChatLoaded) {
            emit((state as ChatLoaded).copyWith(isOtherPartyTyping: false));
          }
        });
      }
    });

    _reactionSubscription =
        _chatRepository.onReactionUpdated.listen((update) {
      if (update.conversationId != conversationId) return;
      if (state is! ChatLoaded) return;

      final current = state as ChatLoaded;
      final updated = current.messages.map((m) {
        if (m.id != update.messageId) return m;
        return m.copyWith(reactions: update.reactions);
      }).toList();
      emit(current.copyWith(messages: updated));
    });
  }

  void setReplyingTo(ChatMessage? message) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    emit(current.copyWith(replyingTo: message, clearReplyingTo: message == null));
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state is! ChatLoaded) return;

    _stopTypingSignal();
    final replyTo = (state as ChatLoaded).replyingTo;

    final result = await _sendMessageUseCase(
      conversationId,
      content,
      replyToMessageId: replyTo?.id,
    );

    if (result is Success<ChatMessage>) {
      _appendIfNotPresent(result.data);
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(clearReplyingTo: true));
      }
    }
  }

  Future<void> sendImage(String filePath) async {
    await _sendMediaOptimistically(
      type: ChatMessageType.image,
      filePath: filePath,
      send: (replyId) => _sendImageMessageUseCase(
        conversationId,
        filePath,
        replyToMessageId: replyId,
      ),
    );
  }

  Future<void> sendVideo(String filePath) async {
    await _sendMediaOptimistically(
      type: ChatMessageType.video,
      filePath: filePath,
      send: (replyId) => _sendVideoMessageUseCase(
        conversationId,
        filePath,
        replyToMessageId: replyId,
      ),
    );
  }

  Future<void> sendVoice(String filePath, {int? durationSeconds}) async {
    await _sendMediaOptimistically(
      type: ChatMessageType.voice,
      filePath: filePath,
      durationSeconds: durationSeconds,
      send: (replyId) => _sendVoiceMessageUseCase(
        conversationId,
        filePath,
        durationSeconds: durationSeconds,
        replyToMessageId: replyId,
      ),
    );
  }

  Future<void> _sendMediaOptimistically({
    required ChatMessageType type,
    required String filePath,
    int? durationSeconds,
    required Future<ApiResult<ChatMessage>> Function(String? replyId) send,
  }) async {
    if (state is! ChatLoaded) return;

    final current = state as ChatLoaded;
    final replyTo = current.replyingTo;
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}-${++_tempCounter}';
    final pending = ChatMessage(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId ?? '',
      senderName: '',
      content: '',
      sentAt: DateTime.now(),
      isRead: false,
      type: type,
      localMediaPath: filePath,
      mediaDurationSeconds: durationSeconds,
      isPending: true,
      replyToMessageId: replyTo?.id,
      replyPreview: replyTo == null
          ? null
          : ReplyPreview(
              id: replyTo.id,
              senderId: replyTo.senderId,
              content: replyTo.content,
              type: replyTo.type,
            ),
    );

    emit(current.copyWith(
      messages: [...current.messages, pending],
      clearReplyingTo: true,
    ));

    final result = await send(replyTo?.id);

    if (state is! ChatLoaded) return;
    final after = state as ChatLoaded;

    if (result is Success<ChatMessage>) {
      final withoutTemp =
          after.messages.where((m) => m.id != tempId).toList(growable: false);
      if (withoutTemp.any((m) => m.id == result.data.id)) {
        emit(after.copyWith(messages: withoutTemp));
      } else {
        emit(after.copyWith(messages: [...withoutTemp, result.data]));
      }
    } else {
      final failed = after.messages
          .map((m) => m.id == tempId
              ? m.copyWith(isPending: false, hasFailed: true)
              : m)
          .toList();
      emit(after.copyWith(messages: failed));
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    // Optimistic: flip the user's reaction locally first.
    if (state is ChatLoaded && currentUserId != null) {
      final current = state as ChatLoaded;
      final updated = current.messages.map((m) {
        if (m.id != messageId) return m;
        final mine = m.reactions
            .where((r) => r.userId == currentUserId)
            .toList();
        final others = m.reactions
            .where((r) => r.userId != currentUserId)
            .toList();
        final alreadyHadSame =
            mine.any((r) => r.emoji == emoji);
        final next = [
          ...others,
          if (!alreadyHadSame)
            MessageReaction(userId: currentUserId!, emoji: emoji),
        ];
        return m.copyWith(reactions: next);
      }).toList();
      emit(current.copyWith(messages: updated));
    }

    await _reactToMessageUseCase(messageId, emoji);
    // The real result will arrive via the reactionUpdated SignalR event.
  }

  void notifyTyping() {
    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      _chatRepository.sendTypingStarted(conversationId);
    }
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), _stopTypingSignal);
  }

  void _stopTypingSignal() {
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _chatRepository.sendTypingStopped(conversationId);
    }
    _typingStopTimer?.cancel();
  }

  void _appendIfNotPresent(ChatMessage message) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    if (current.messages.any((m) => m.id == message.id)) return;
    emit(current.copyWith(messages: [...current.messages, message]));
  }

  @override
  Future<void> close() {
    _messageReceivedSubscription?.cancel();
    _messagesReadSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionSubscription?.cancel();
    _typingStopTimer?.cancel();
    _stopTypingSignal();
    _chatRepository.leaveConversation(conversationId);
    return super.close();
  }
}
