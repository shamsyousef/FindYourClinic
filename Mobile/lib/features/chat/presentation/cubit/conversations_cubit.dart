import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'conversations_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  final GetConversationsUseCase _getConversationsUseCase;
  final IChatRepository _chatRepository;

  StreamSubscription? _conversationUpdatedSubscription;
  StreamSubscription? _messagesReadSubscription;

  ConversationsCubit(this._getConversationsUseCase, this._chatRepository)
      : super(ConversationsInitial());

  void loadConversations() async {
    emit(ConversationsLoading());
    final result = await _getConversationsUseCase();
    
    if (result is Success<List<Conversation>>) {
      emit(ConversationsLoaded(result.data));
      _listenToRealtimeEvents();
    } else if (result is Error<List<Conversation>>) {
      emit(ConversationsError(result.failure.message));
    }
  }

  void _listenToRealtimeEvents() {
    _conversationUpdatedSubscription?.cancel();
    _messagesReadSubscription?.cancel();

    _conversationUpdatedSubscription = _chatRepository.onConversationUpdated.listen((_) {
      // Reload the entire list to keep sorting and unread counts accurate.
      // A more optimized approach would update the single item locally.
      _reloadSilently();
    });

    _messagesReadSubscription = _chatRepository.onMessagesRead.listen((_) {
      _reloadSilently();
    });
  }

  void _reloadSilently() async {
    if (state is! ConversationsLoaded) return;
    
    final result = await _getConversationsUseCase();
    if (result is Success<List<Conversation>>) {
      emit(ConversationsLoaded(result.data));
    }
  }

  @override
  Future<void> close() {
    _conversationUpdatedSubscription?.cancel();
    _messagesReadSubscription?.cancel();
    return super.close();
  }
}
