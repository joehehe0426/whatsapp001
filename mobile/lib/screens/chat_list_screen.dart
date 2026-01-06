import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../history_controller.dart';
import '../models.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final HistoryController controller;

  const ChatListScreen({super.key, required this.controller});

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

  Future<void> _import() async {
    final raw = await _promptText(
      title: 'Import JSON',
      label: 'Paste exported JSON',
      maxLines: 12,
      primaryAction: 'Import',
    );
    if (raw == null) return;
    try {
      await widget.controller.importJson(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported history')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _export() async {
    final raw = await widget.controller.exportJson();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export copied to clipboard')),
    );
  }

  Future<void> _resetSample() async {
    await widget.controller.resetToSample();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to sample history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chats = widget.controller.chats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'import':
                  await _import();
                  break;
                case 'export':
                  await _export();
                  break;
                case 'reset':
                  await _resetSample();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import', child: Text('Import JSON')),
              PopupMenuItem(value: 'export', child: Text('Export JSON (copy)')),
              PopupMenuItem(value: 'reset', child: Text('Reset to sample')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChat,
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: chats.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final chat = chats[i];
                final last = chat.lastMessage;
                final subtitle = last?.text ?? 'No messages yet';
                final trailing = last == null ? '' : _timeFmt.format(last.timestamp);
                return ListTile(
                  leading: _Avatar(name: chat.title),
                  title: Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  onTap: () async {
                    await widget.controller.markRead(chat.id);
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(controller: widget.controller, chatId: chat.id),
                      ),
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
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

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\\s+')).take(2).map((p) => p[0]).join().toUpperCase();
    return CircleAvatar(
      child: Text(initials),
    );
  }
}

