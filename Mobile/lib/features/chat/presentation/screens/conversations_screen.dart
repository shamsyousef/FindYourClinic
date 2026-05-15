import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/token_storage.dart';
import '../cubit/conversations_cubit.dart';
import '../cubit/conversations_state.dart';
import '../../../../core/widgets/user_avatar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationsCubit _cubit;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ConversationsCubit>()..loadConversations();
    sl<TokenStorage>().getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: BlocBuilder<ConversationsCubit, ConversationsState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is ConversationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: TextStyle(color: theme.colorScheme.error)),
                  TextButton(
                    onPressed: () => _cubit.loadConversations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is ConversationsLoaded) {
            final conversations = state.conversations;
            
            if (conversations.isEmpty) {
              return const Center(
                child: Text('No conversations yet.'),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () => _cubit.loadConversations(),
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  final isUnread = conv.unreadCount > 0;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: UserAvatar(
                      radius: 28,
                      imageUrl: conv.counterpartyImageUrl,
                      fullName: conv.counterpartyName,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      textStyle: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    title: Text(
                      conv.counterpartyName ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessage ?? 'Started a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread 
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(conv.lastMessageAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isUnread)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conv.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      final otherUserId = _currentUserId == conv.patientId
                          ? conv.doctorId
                          : conv.patientId;
                      context.push(
                        '/chat/${conv.id}',
                        extra: {
                          'otherPartyName': conv.counterpartyName,
                          'otherPartyImageUrl': conv.counterpartyImageUrl,
                          'otherPartyUserId': otherUserId,
                        },
                      ).then((_) {
                        if (mounted) _cubit.loadConversations();
                      });
                    },
                  );
                },
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final difference = now.difference(localDate);

    if (difference.inDays == 0 && now.day == localDate.day) {
      return DateFormat.jm().format(localDate);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(localDate);
    } else {
      return DateFormat.yMd().format(localDate);
    }
  }
}
