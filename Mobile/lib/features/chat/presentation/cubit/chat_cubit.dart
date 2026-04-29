import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkConversationAsReadUseCase _markConversationAsReadUseCase;
  final IChatRepository _chatRepository;

  final String conversationId;
  StreamSubscription? _messageReceivedSubscription;
  StreamSubscription? _messagesReadSubscription;

  ChatCubit({
    required this.conversationId,
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required MarkConversationAsReadUseCase markConversationAsReadUseCase,
    required IChatRepository chatRepository,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _markConversationAsReadUseCase = markConversationAsReadUseCase,
        _chatRepository = chatRepository,
        super(ChatInitial());

  void init() async {
    emit(ChatLoading());
    
    // Join SignalR group
    await _chatRepository.joinConversation(conversationId);
    
    // Mark as read immediately when opening
    await _markConversationAsReadUseCase(conversationId);

    // Fetch historical messages
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

    _messageReceivedSubscription = _chatRepository.onMessageReceived.listen((newMessage) {
      if (newMessage.conversationId != conversationId) return;

      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        // Check if message already exists (sometimes REST API returns it right before SignalR fires)
        if (!currentMessages.any((m) => m.id == newMessage.id)) {
          emit(ChatLoaded([...currentMessages, newMessage]));
        }
        
        // Mark conversation as read because we are currently looking at it
        _markConversationAsReadUseCase(conversationId);
      }
    });

    _messagesReadSubscription = _chatRepository.onMessagesRead.listen((eventConvId) {
      if (eventConvId != conversationId) return;

      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        final updatedMessages = currentMessages.map((msg) {
          if (!msg.isRead) {
            return msg.copyWith(isRead: true);
          }
          return msg;
        }).toList();
        
        emit(ChatLoaded(updatedMessages));
      }
    });
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final result = await _sendMessageUseCase(conversationId, content);
    if (result is Success<ChatMessage>) {
      // Message added successfully via REST, SignalR 'messageReceived' will also trigger and add it,
      // but to be responsive, we can append it immediately if it's not already there.
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        if (!currentMessages.any((m) => m.id == result.data.id)) {
          emit(ChatLoaded([...currentMessages, result.data]));
        }
      }
    } else if (result is Error<ChatMessage>) {
      // Handle error gracefully, maybe show a toast
    }
  }

  @override
  Future<void> close() {
    _messageReceivedSubscription?.cancel();
    _messagesReadSubscription?.cancel();
    _chatRepository.leaveConversation(conversationId);
    return super.close();
  }
}
