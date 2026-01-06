import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../history_controller.dart';
import '../models.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final HistoryController controller;
  final bool showArchivedOnly;

  const ChatListScreen({
    super.key,
    required this.controller,
    this.showArchivedOnly = false,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _timeFmt = DateFormat('HH:mm');

  Future<void> _createChat() async {
    final title = await _promptText(
      title: 'New chat',
      label: 'Chat name',
      primaryAction: 'Create',
    );
    if (title == null) return;
    final chat = await widget.controller.createChat(title: title);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(controller: widget.controller, chatId: chat.id),
      ),
    );
    setState(() {});
  }

  Future<void> _createGroup() async {
    final title = await _promptText(
      title: 'New group',
      label: 'Group name',
      primaryAction: 'Next',
    );
    if (title == null) return;
    final membersRaw = await _promptText(
      title: 'Group members',
      label: 'Names (comma separated)',
      primaryAction: 'Create',
      maxLines: 2,
    );
    if (membersRaw == null) return;
    final members = membersRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final chat = await widget.controller.createGroup(title: title, memberNames: members);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(controller: widget.controller, chatId: chat.id),
      ),
    );
    setState(() {});
  }

  Future<void> _fabMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: const Text('New chat'),
              onTap: () => Navigator.of(context).pop('chat'),
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('New group'),
              onTap: () => Navigator.of(context).pop('group'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'chat') {
      await _createChat();
    } else if (action == 'group') {
      await _createGroup();
    }
  }

  Future<void> _openChatActions(ChatThread chat) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(chat.isPinned ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            ListTile(
              leading: Icon(chat.isArchived ? Icons.archive_outlined : Icons.archive),
              title: Text(chat.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () => Navigator.of(context).pop('archive'),
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_unread_outlined),
              title: const Text('Mark unread'),
              onTap: () => Navigator.of(context).pop('unread'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete chat'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (action) {
      case 'pin':
        await widget.controller.setPinned(chatId: chat.id, pinned: !chat.isPinned);
        if (!mounted) return;
        setState(() {});
        break;
      case 'archive':
        await widget.controller.setArchived(chatId: chat.id, archived: !chat.isArchived);
        if (!mounted) return;
        setState(() {});
        break;
      case 'unread':
        await widget.controller.markUnread(chat.id, count: 1);
        if (!mounted) return;
        setState(() {});
        break;
      case 'delete':
        await widget.controller.deleteChat(chat.id);
        if (!mounted) return;
        setState(() {});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final archivedCount = widget.controller.chatsFiltered(archived: true).length;
    final chats = widget.controller.chatsFiltered(archived: widget.showArchivedOnly);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showArchivedOnly ? 'Archived' : 'Chats'),
      ),
      floatingActionButton: widget.showArchivedOnly
          ? null
          : FloatingActionButton(
              onPressed: _fabMenu,
              child: const Icon(Icons.add_comment_outlined),
            ),
      body: (chats.isEmpty && (widget.showArchivedOnly || archivedCount == 0))
          ? const _EmptyState()
          : ListView.separated(
              itemCount: chats.length + ((widget.showArchivedOnly || archivedCount == 0) ? 0 : 1),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (!widget.showArchivedOnly && archivedCount > 0 && i == 0) {
                  return ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('Archived'),
                    trailing: Text('$archivedCount'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatListScreen(
                            controller: widget.controller,
                            showArchivedOnly: true,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  );
                }

                final idx = i - ((!widget.showArchivedOnly && archivedCount > 0) ? 1 : 0);
                final chat = chats[idx];
                final last = chat.lastMessage;
                final subtitle = _subtitleForLastMessage(last);
                final trailing = last == null ? '' : _timeFmt.format(last.timestamp);
                return ListTile(
                  leading: _Avatar(name: chat.title, isGroup: chat.participants.length > 2),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isPinned) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.push_pin, size: 16, color: Theme.of(context).hintColor),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(trailing, style: Theme.of(context).textTheme.labelSmall),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        _UnreadBadge(count: chat.unreadCount),
                      ],
                    ],
                  ),
                  onLongPress: () => _openChatActions(chat),
                  onTap: () async {
                    await widget.controller.markRead(chat.id);
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(controller: widget.controller, chatId: chat.id),
                      ),
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
  }

  String _subtitleForLastMessage(Message? last) {
    if (last == null) return 'No messages yet';
    if (last.isDeleted) return 'This message was deleted';
    if (last.kind == MessageKind.attachment) {
      return last.attachmentLabel ?? 'Attachment';
    }
    return last.text;
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    required String primaryAction,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            maxLines: maxLines,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(primaryAction),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined, size: 56, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(
              'Create a chat to start writing mock history.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This app is local-only and does not connect to WhatsApp.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primary;
    final fg = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isGroup;

  const _Avatar({required this.name, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\\s+')).take(2).map((p) => p[0]).join().toUpperCase();
    return CircleAvatar(
      child: isGroup
          ? const Icon(Icons.group_outlined)
          : Text(initials),
    );
  }
}

