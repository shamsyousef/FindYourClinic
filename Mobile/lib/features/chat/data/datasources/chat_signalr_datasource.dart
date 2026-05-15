import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

abstract class ChatSignalRDataSource {
  Stream<ChatMessageModel> get onMessageReceived;
  Stream<String> get onConversationUpdated;
  Stream<String> get onMessagesRead;
  Stream<bool> get onTyping;
  Stream<ReactionUpdate> get onReactionUpdated;

  Future<void> connect();
  Future<void> joinConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);
  Future<void> disconnect();
  Future<void> sendTypingStarted(String conversationId);
  Future<void> sendTypingStopped(String conversationId);
}

class ChatSignalRDataSourceImpl implements ChatSignalRDataSource {
  final TokenStorage _tokenStorage;
  final String _baseUrl;
  HubConnection? _hubConnection;
  String? _connectedToken;

  final _messageReceivedController =
      StreamController<ChatMessageModel>.broadcast();
  final _conversationUpdatedController = StreamController<String>.broadcast();
  final _messagesReadController = StreamController<String>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _reactionUpdatedController =
      StreamController<ReactionUpdate>.broadcast();

  ChatSignalRDataSourceImpl(this._tokenStorage, this._baseUrl);

  @override
  Stream<ChatMessageModel> get onMessageReceived =>
      _messageReceivedController.stream;

  @override
  Stream<String> get onConversationUpdated =>
      _conversationUpdatedController.stream;

  @override
  Stream<String> get onMessagesRead => _messagesReadController.stream;

  @override
  Stream<bool> get onTyping => _typingController.stream;

  @override
  Stream<ReactionUpdate> get onReactionUpdated =>
      _reactionUpdatedController.stream;

  @override
  Future<void> connect() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return;

    if (_hubConnection?.state == HubConnectionState.Connected) {
      if (_connectedToken == token) return;
      await _hubConnection!.stop();
      _hubConnection = null;
      _connectedToken = null;
    }

    _connectedToken = token;
    final url = '$_baseUrl${ApiEndpoints.chatHub}?access_token=$token';

    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('messageReceived', _handleMessageReceived);
    _hubConnection!.on('conversationUpdated', _handleConversationUpdated);
    _hubConnection!.on('messagesRead', _handleMessagesRead);
    _hubConnection!.on('reactionUpdated', _handleReactionUpdated);
    _hubConnection!.on('userTyping', (_) => _typingController.add(true));
    _hubConnection!
        .on('userStoppedTyping', (_) => _typingController.add(false));

    try {
      await _hubConnection!.start();
    } catch (_) {
      // ignore
    }
  }

  void _handleMessageReceived(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final payload = args.first as Map<String, dynamic>;

    Map<String, dynamic>? replyJson =
        (payload['replyPreview'] ?? payload['ReplyPreview'])
            as Map<String, dynamic>?;
    final reactionsRaw =
        (payload['reactions'] ?? payload['Reactions']) as List<dynamic>?;

    final message = ChatMessageModel(
      id: (payload['id'] ?? payload['Id']).toString(),
      conversationId:
          (payload['conversationId'] ?? payload['ConversationId']).toString(),
      senderId: (payload['senderId'] ?? payload['SenderId']).toString(),
      senderName:
          (payload['senderName'] ?? payload['SenderName'] ?? '').toString(),
      content: (payload['content'] ?? payload['Content'] ?? '').toString(),
      sentAt: parseServerDateTime(
          (payload['sentAt'] ?? payload['SentAt']).toString()),
      isRead: (payload['isRead'] ?? payload['IsRead']) as bool? ?? false,
      type: chatMessageTypeFromInt(
          ((payload['type'] ?? payload['Type']) as num?)?.toInt() ?? 0),
      mediaUrl: (payload['mediaUrl'] ?? payload['MediaUrl']) as String?,
      mediaThumbnailUrl: (payload['mediaThumbnailUrl'] ??
          payload['MediaThumbnailUrl']) as String?,
      mediaDurationSeconds: ((payload['mediaDurationSeconds'] ??
              payload['MediaDurationSeconds']) as num?)
          ?.toInt(),
      replyToMessageId:
          (payload['replyToMessageId'] ?? payload['ReplyToMessageId'])
              ?.toString(),
      replyPreview: replyJson == null
          ? null
          : ReplyPreview(
              id: (replyJson['id'] ?? replyJson['Id']).toString(),
              senderId:
                  (replyJson['senderId'] ?? replyJson['SenderId']).toString(),
              content:
                  (replyJson['content'] ?? replyJson['Content'] ?? '').toString(),
              type: chatMessageTypeFromInt(
                  ((replyJson['type'] ?? replyJson['Type']) as num?)
                          ?.toInt() ??
                      0),
            ),
      reactions: reactionsRaw == null
          ? const []
          : reactionsRaw.map((r) {
              final m = r as Map<String, dynamic>;
              return MessageReaction(
                userId: (m['userId'] ?? m['UserId']).toString(),
                emoji: (m['emoji'] ?? m['Emoji'] ?? '').toString(),
              );
            }).toList(growable: false),
    );
    _messageReceivedController.add(message);
  }

  void _handleConversationUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final payload = args.first as Map<String, dynamic>;
    final conversationId =
        payload['conversationId'] ?? payload['ConversationId'];
    _conversationUpdatedController.add(conversationId.toString());
  }

  void _handleMessagesRead(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final payload = args.first as Map<String, dynamic>;
    final conversationId =
        payload['conversationId'] ?? payload['ConversationId'];
    _messagesReadController.add(conversationId.toString());
  }

  void _handleReactionUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final payload = args.first as Map<String, dynamic>;
    final conversationId =
        (payload['conversationId'] ?? payload['ConversationId']).toString();
    final messageId = (payload['messageId'] ?? payload['MessageId']).toString();
    final reactionsRaw =
        (payload['reactions'] ?? payload['Reactions']) as List<dynamic>? ??
            const [];
    final reactions = reactionsRaw.map((r) {
      final m = r as Map<String, dynamic>;
      return MessageReaction(
        userId: (m['userId'] ?? m['UserId']).toString(),
        emoji: (m['emoji'] ?? m['Emoji'] ?? '').toString(),
      );
    }).toList(growable: false);
    _reactionUpdatedController.add(ReactionUpdate(
      conversationId: conversationId,
      messageId: messageId,
      reactions: reactions,
    ));
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
    _hubConnection = null;
    _connectedToken = null;
  }

  @override
  Future<void> sendTypingStarted(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('StartTyping', args: [conversationId]);
    }
  }

  @override
  Future<void> sendTypingStopped(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke('StopTyping', args: [conversationId]);
    }
  }
}
