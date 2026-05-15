import 'package:flutter/material.dart';

const reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class ReactionPicker extends StatelessWidget {
  final ValueChanged<String> onPick;

  const ReactionPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionEmojis
            .map(
              (e) => InkWell(
                onTap: () => onPick(e),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(e, style: const TextStyle(fontSize: 26)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class MessageActionsSheet extends StatelessWidget {
  final bool canDelete;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback? onDelete;

  const MessageActionsSheet({
    super.key,
    required this.canDelete,
    required this.onReply,
    required this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('Reply'),
            onTap: onReply,
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy'),
            onTap: onCopy,
          ),
          if (canDelete && onDelete != null)
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}
