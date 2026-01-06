import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../history_controller.dart';
import '../models.dart';

class ChatScreen extends StatefulWidget {
  final HistoryController controller;
  final String chatId;

  const ChatScreen({super.key, required this.controller, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composer = TextEditingController();
  final _timeFmt = DateFormat('HH:mm');

  bool _sendAsMe = true;

  ChatThread get _chat => widget.controller.document.chats.firstWhere((c) => c.id == widget.chatId);

  String _meId(ChatThread chat) => chat.participantById('me')?.id ?? 'me';

  String _otherId(ChatThread chat) {
    final me = _meId(chat);
    return chat.participants.firstWhere((p) => p.id != me).id;
  }

  Future<void> _send() async {
    final chat = _chat;
    final authorId = _sendAsMe ? _meId(chat) : _otherId(chat);
    await widget.controller.addMessage(chatId: chat.id, authorId: authorId, text: _composer.text);
    _composer.clear();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _renameChat() async {
    final title = await _promptText(
      title: 'Rename chat',
      label: 'Chat name',
      initialValue: _chat.title,
      primaryAction: 'Save',
    );
    if (title == null) return;
    await widget.controller.renameChat(chatId: widget.chatId, title: title);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text('This deletes the chat locally on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.controller.deleteChat(widget.chatId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final me = _meId(chat);
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.title),
        actions: [
          IconButton(
            tooltip: 'Rename',
            onPressed: _renameChat,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'delete':
                  await _deleteChat();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: chat.messages.length,
              itemBuilder: (context, i) {
                final m = chat.messages[i];
                final isMe = m.authorId == me;
                return _MessageBubble(
                  isMe: isMe,
                  text: m.text,
                  time: _timeFmt.format(m.timestamp),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: _sendAsMe ? 'Sending as: You' : 'Sending as: Them',
                  onPressed: () => setState(() => _sendAsMe = !_sendAsMe),
                  icon: Icon(_sendAsMe ? Icons.person : Icons.person_outline),
                ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _send,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    required String primaryAction,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
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

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;

  const _MessageBubble({
    required this.isMe,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isMe ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(text, style: TextStyle(color: fg)),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

