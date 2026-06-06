import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/conversation.dart';

class ConversationSidebar extends ConsumerWidget {
  const ConversationSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListProvider);
    final chatState = ref.watch(chatProvider);
    final currentId = chatState.conversationId;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // New Chat button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(chatProvider.notifier).newConversation(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Chat'),
              ),
            ),
          ),
          const Divider(height: 1),
          // Conversation list
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final isActive = conv.id == currentId;
                      return _ConversationTile(
                        conversation: conv,
                        isActive: isActive,
                        onTap: () => ref
                            .read(chatProvider.notifier)
                            .selectConversation(conv.id),
                        onDelete: () => _confirmDelete(context, ref, conv),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Conversation conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
            'Delete "${conv.title.isNotEmpty ? conv.title : 'Untitled'}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).deleteConversation(conv.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = conversation.title.isNotEmpty
        ? conversation.title
        : 'Untitled';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (conversation.model.isNotEmpty) ...[
                        Icon(Icons.smart_toy, size: 10,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          conversation.model.length > 20
                              ? '${conversation.model.substring(0, 20)}...'
                              : conversation.model,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatDate(conversation.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 16, color: colorScheme.onSurfaceVariant),
              tooltip: 'Delete conversation',
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}
