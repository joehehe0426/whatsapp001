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
  String? _replyToMessageId;
  String? _editingMessageId;

  ChatThread get _chat =>
      widget.controller.document.chats.firstWhere((c) => c.id == widget.chatId);

  String _meId(ChatThread chat) => chat.participantById('me')?.id ?? 'me';

  String _otherId(ChatThread chat) {
    final me = _meId(chat);
    return chat.participants.firstWhere((p) => p.id != me).id;
  }

  Future<void> _send() async {
    final chat = _chat;
    final authorId = _sendAsMe ? _meId(chat) : _otherId(chat);
    final raw = _composer.text;
    if (_editingMessageId != null) {
      await widget.controller.editMessage(
        chatId: chat.id,
        messageId: _editingMessageId!,
        newText: raw,
      );
      _editingMessageId = null;
    } else {
      await widget.controller.addMessage(
        chatId: chat.id,
        authorId: authorId,
        text: raw,
        replyToMessageId: _replyToMessageId,
      );
    }
    _replyToMessageId = null;
    _composer.clear();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Photo (placeholder)'),
              onTap: () => Navigator.of(context).pop('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video (placeholder)'),
              onTap: () => Navigator.of(context).pop('video'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Document (placeholder)'),
              onTap: () => Navigator.of(context).pop('doc'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final chat = _chat;
    final authorId = _sendAsMe ? _meId(chat) : _otherId(chat);
    final label = switch (choice) {
      'photo' => 'Photo (placeholder)',
      'video' => 'Video (placeholder)',
      'doc' => 'Document (placeholder)',
      _ => 'Attachment (placeholder)',
    };
    await widget.controller.addMessage(
      chatId: chat.id,
      authorId: authorId,
      text: '',
      kind: MessageKind.attachment,
      attachmentLabel: label,
      replyToMessageId: _replyToMessageId,
    );
    _replyToMessageId = null;
    if (!mounted) return;
    setState(() {});
  }

  Message? _findMessage(String messageId) {
    for (final m in _chat.messages) {
      if (m.id == messageId) return m;
    }
    return null;
  }

  Future<void> _openMessageActions(Message message) async {
    final chat = _chat;
    final me = _meId(chat);
    final isMe = message.authorId == me;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Reply'),
              onTap: () => Navigator.of(context).pop('reply'),
            ),
            ListTile(
              leading: Icon(message.isStarred ? Icons.star : Icons.star_border),
              title: Text(message.isStarred ? 'Unstar' : 'Star'),
              onTap: () => Navigator.of(context).pop('star'),
            ),
            if (isMe && message.kind == MessageKind.text && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete (local)'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            if (isMe) ...[
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Receipts (ticks)'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.done),
                title: const Text('Sent'),
                onTap: () => Navigator.of(context).pop('sent'),
              ),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Delivered'),
                onTap: () => Navigator.of(context).pop('delivered'),
              ),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Read'),
                onTap: () => Navigator.of(context).pop('read'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    switch (action) {
      case 'reply':
        setState(() {
          _replyToMessageId = message.id;
          _editingMessageId = null;
        });
        break;
      case 'star':
        await widget.controller.toggleStarMessage(chatId: chat.id, messageId: message.id);
        if (!mounted) return;
        setState(() {});
        break;
      case 'edit':
        setState(() {
          _editingMessageId = message.id;
          _replyToMessageId = null;
          _composer.text = message.text;
        });
        break;
      case 'delete':
        await widget.controller.deleteMessage(chatId: chat.id, messageId: message.id);
        if (!mounted) return;
        setState(() {});
        break;
      case 'sent':
        await widget.controller.setMessageReceipt(
          chatId: chat.id,
          messageId: message.id,
          receipt: ReceiptStatus.sent,
        );
        if (!mounted) return;
        setState(() {});
        break;
      case 'delivered':
        await widget.controller.setMessageReceipt(
          chatId: chat.id,
          messageId: message.id,
          receipt: ReceiptStatus.delivered,
        );
        if (!mounted) return;
        setState(() {});
        break;
      case 'read':
        await widget.controller.setMessageReceipt(
          chatId: chat.id,
          messageId: message.id,
          receipt: ReceiptStatus.read,
        );
        if (!mounted) return;
        setState(() {});
        break;
    }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
    final replyMsg = _replyToMessageId == null ? null : _findMessage(_replyToMessageId!);
    final editingMsg =
        _editingMessageId == null ? null : _findMessage(_editingMessageId!);
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
                  message: m,
                  repliedTo: m.replyToMessageId == null ? null : _findMessage(m.replyToMessageId!),
                  time: _timeFmt.format(m.timestamp),
                  onLongPress: () => _openMessageActions(m),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyMsg != null || editingMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ComposerContextBar(
                      mode: editingMsg != null ? _ComposerMode.edit : _ComposerMode.reply,
                      title: editingMsg != null ? 'Editing' : 'Replying to',
                      preview: editingMsg != null
                          ? (editingMsg.isDeleted
                              ? 'Deleted message'
                              : (editingMsg.kind == MessageKind.attachment
                                  ? (editingMsg.attachmentLabel ?? 'Attachment')
                                  : editingMsg.text))
                          : (replyMsg!.isDeleted
                              ? 'Deleted message'
                              : (replyMsg.kind == MessageKind.attachment
                                  ? (replyMsg.attachmentLabel ?? 'Attachment')
                                  : replyMsg.text)),
                      onCancel: () => setState(() {
                        _replyToMessageId = null;
                        _editingMessageId = null;
                        _composer.clear();
                      }),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip: _sendAsMe ? 'Sending as: You' : 'Sending as: Them',
                      onPressed: () => setState(() => _sendAsMe = !_sendAsMe),
                      icon: Icon(_sendAsMe ? Icons.person : Icons.person_outline),
                    ),
                    IconButton(
                      tooltip: 'Attach (placeholder)',
                      onPressed: _attach,
                      icon: const Icon(Icons.attach_file),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        decoration: InputDecoration(
                          hintText: editingMsg != null ? 'Edit message' : 'Message',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _send,
                      child: Text(editingMsg != null ? 'Save' : 'Send'),
                    ),
                  ],
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
  final Message message;
  final Message? repliedTo;
  final String time;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.isMe,
    required this.message,
    required this.repliedTo,
    required this.time,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isMe ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bodyText = message.isDeleted
        ? 'This message was deleted'
        : (message.kind == MessageKind.attachment
            ? (message.attachmentLabel ?? 'Attachment')
            : message.text);
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: GestureDetector(
            onLongPress: onLongPress,
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
                    if (repliedTo != null)
                      _ReplyPreview(
                        isMe: isMe,
                        fg: fg,
                        preview: repliedTo!.isDeleted
                            ? 'Deleted message'
                            : (repliedTo!.kind == MessageKind.attachment
                                ? (repliedTo!.attachmentLabel ?? 'Attachment')
                                : repliedTo!.text),
                      ),
                    if (message.kind == MessageKind.attachment && !message.isDeleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 18, color: fg),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              bodyText,
                              style: TextStyle(color: fg),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        bodyText,
                        style: TextStyle(
                          color: fg,
                          fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isStarred) ...[
                          Icon(Icons.star, size: 14, color: fg),
                          const SizedBox(width: 6),
                        ],
                        if (message.isEdited && !message.isDeleted) ...[
                          Text(
                            'edited',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          time,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          _ReceiptIcon(receipt: message.receipt),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptIcon extends StatelessWidget {
  final ReceiptStatus receipt;

  const _ReceiptIcon({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    final read = Theme.of(context).colorScheme.primary;
    return switch (receipt) {
      ReceiptStatus.none => const SizedBox.shrink(),
      ReceiptStatus.sent => Icon(Icons.done, size: 16, color: hint),
      ReceiptStatus.delivered => Icon(Icons.done_all, size: 16, color: hint),
      ReceiptStatus.read => Icon(Icons.done_all, size: 16, color: read),
    };
  }
}

class _ReplyPreview extends StatelessWidget {
  final bool isMe;
  final Color fg;
  final String preview;

  const _ReplyPreview({
    required this.isMe,
    required this.fg,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final border = isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(width: 3, color: border)),
          color: Colors.black.withOpacity(0.04),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

enum _ComposerMode { reply, edit }

class _ComposerContextBar extends StatelessWidget {
  final _ComposerMode mode;
  final String title;
  final String preview;
  final VoidCallback onCancel;

  const _ComposerContextBar({
    required this.mode,
    required this.title,
    required this.preview,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final icon = mode == _ComposerMode.edit ? Icons.edit_outlined : Icons.reply_outlined;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: onCancel,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

