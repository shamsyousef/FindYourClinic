import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/token_storage.dart';
import '../models/chat_message_model.dart';

abstract class ChatSignalRDataSource {
  Stream<ChatMessageModel> get onMessageReceived;
  Stream<String> get onConversationUpdated;
  Stream<String> get onMessagesRead;

  Future<void> connect();
  Future<void> joinConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);
  Future<void> disconnect();
}

class ChatSignalRDataSourceImpl implements ChatSignalRDataSource {
  final TokenStorage _tokenStorage;
  final String _baseUrl;
  HubConnection? _hubConnection;

  final _messageReceivedController = StreamController<ChatMessageModel>.broadcast();
  final _conversationUpdatedController = StreamController<String>.broadcast();
  final _messagesReadController = StreamController<String>.broadcast();

  ChatSignalRDataSourceImpl(this._tokenStorage, this._baseUrl);

  @override
  Stream<ChatMessageModel> get onMessageReceived => _messageReceivedController.stream;

  @override
  Stream<String> get onConversationUpdated => _conversationUpdatedController.stream;

  @override
  Stream<String> get onMessagesRead => _messagesReadController.stream;

  @override
  Future<void> connect() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null) return;

    final url = '$_baseUrl${ApiEndpoints.chatHub}?access_token=$token';

    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('messageReceived', _handleMessageReceived);
    _hubConnection!.on('conversationUpdated', _handleConversationUpdated);
    _hubConnection!.on('messagesRead', _handleMessagesRead);

    try {
      await _hubConnection!.start();
    } catch (e) {
      // Ignore or log connection error gracefully
    }
  }

  void _handleMessageReceived(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final payload = args.first as Map<String, dynamic>;
      
      final id = payload['id'] ?? payload['Id'];
      final conversationId = payload['conversationId'] ?? payload['ConversationId'];
      final senderId = payload['senderId'] ?? payload['SenderId'];
      final senderName = payload['senderName'] ?? payload['SenderName'];
      final content = payload['content'] ?? payload['Content'];
      final sentAt = payload['sentAt'] ?? payload['SentAt'];
      final isRead = payload['isRead'] ?? payload['IsRead'];

      final message = ChatMessageModel(
        id: id.toString(),
        conversationId: conversationId.toString(),
        senderId: senderId.toString(),
        senderName: senderName.toString(),
        content: content.toString(),
        sentAt: DateTime.parse(sentAt.toString()),
        isRead: isRead as bool,
      );
      _messageReceivedController.add(message);
    }
  }

  void _handleConversationUpdated(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final payload = args.first as Map<String, dynamic>;
      final conversationId = payload['conversationId'] ?? payload['ConversationId'];
      _conversationUpdatedController.add(conversationId.toString());
    }
  }

  void _handleMessagesRead(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final payload = args.first as Map<String, dynamic>;
      final conversationId = payload['conversationId'] ?? payload['ConversationId'];
      _messagesReadController.add(conversationId.toString());
    }
  }

  @override
  Future<void> joinConversation(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('JoinConversation', args: [conversationId]);
    }
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('LeaveConversation', args: [conversationId]);
    }
  }

  @override
  Future<void> disconnect() async {
    await _hubConnection?.stop();
  }
}
