import 'models.dart';
import 'history_store.dart';

class HistoryController {
  final HistoryStore _store;
  HistoryDocument _doc = HistoryDocument.empty();

  HistoryController(this._store);

  HistoryDocument get document => _doc;

  List<ChatThread> get chats {
    final sorted = [..._doc.chats];
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final at = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return sorted;
  }

  List<ChatThread> chatsFiltered({required bool archived}) {
    return chats.where((c) => c.isArchived == archived).toList();
  }

  List<StatusItem> get statuses {
    final sorted = [..._doc.statuses];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  List<CallEntry> get calls {
    final sorted = [..._doc.calls];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  Future<void> loadOrSeed() async {
    final loaded = await _store.load();
    if (loaded == null || loaded.chats.isEmpty) {
      _doc = HistoryDocument.sample();
      await _store.save(_doc);
      return;
    }
    _doc = loaded;
  }

  Future<void> resetToSample() async {
    _doc = HistoryDocument.sample();
    await _store.save(_doc);
  }

  Future<String> exportJson() => _store.exportJson(_doc);

  Future<void> importJson(String raw) async {
    _doc = await _store.importJson(raw);
  }

  Future<void> addStatus({
    required String displayName,
    required String text,
    DateTime? timestamp,
    bool viewed = false,
  }) async {
    final item = StatusItem.create(
      displayName: displayName,
      text: text,
      timestamp: timestamp,
      viewed: viewed,
    );
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats,
      statuses: [..._doc.statuses, item],
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> setStatusViewed({required String statusId, required bool viewed}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats,
      statuses: _doc.statuses
          .map((s) => s.id == statusId
              ? StatusItem(
                  id: s.id,
                  displayName: s.displayName,
                  text: s.text,
                  timestamp: s.timestamp,
                  viewed: viewed,
                )
              : s)
          .toList(),
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> deleteStatus(String statusId) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats,
      statuses: _doc.statuses.where((s) => s.id != statusId).toList(),
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> addCall({
    required String displayName,
    required CallDirection direction,
    required bool isVideo,
    DateTime? timestamp,
    int durationSeconds = 0,
  }) async {
    final entry = CallEntry.create(
      displayName: displayName,
      direction: direction,
      isVideo: isVideo,
      timestamp: timestamp,
      durationSeconds: durationSeconds,
    );
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats,
      statuses: _doc.statuses,
      calls: [..._doc.calls, entry],
    );
    await _store.save(_doc);
  }

  Future<void> deleteCall(String callId) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats,
      statuses: _doc.statuses,
      calls: _doc.calls.where((c) => c.id != callId).toList(),
    );
    await _store.save(_doc);
  }

  Future<ChatThread> createChat({required String title}) async {
    final chat = ChatThread.create(title: title);
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: [..._doc.chats, chat],
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
    return chat;
  }

  Future<ChatThread> createGroup({
    required String title,
    required List<String> memberNames,
  }) async {
    final chat = ChatThread.createGroup(title: title, memberNames: memberNames);
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: [..._doc.chats, chat],
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
    return chat;
  }

  Future<void> renameChat({required String chatId, required String title}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats
          .map((c) => c.id == chatId ? c.copyWith(title: title) : c)
          .toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> setPinned({required String chatId, required bool pinned}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(isPinned: pinned);
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> setArchived({required String chatId, required bool archived}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(isArchived: archived);
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> markUnread(String chatId, {int count = 1}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(unreadCount: count < 0 ? 0 : count);
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> deleteChat(String chatId) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.where((c) => c.id != chatId).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> addMessage({
    required String chatId,
    required String authorId,
    required String text,
    MessageKind kind = MessageKind.text,
    String? attachmentLabel,
    DateTime? timestamp,
    String? replyToMessageId,
  }) async {
    final trimmed = text.trim();
    if (kind == MessageKind.text && trimmed.isEmpty) return;

    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        final isMe = authorId == (c.participantById('me')?.id ?? 'me');
        final msg = Message.create(
          chatId: chatId,
          authorId: authorId,
          kind: kind,
          text: kind == MessageKind.text ? trimmed : '',
          attachmentLabel: attachmentLabel,
          timestamp: timestamp,
          receipt: isMe ? ReceiptStatus.sent : ReceiptStatus.none,
          replyToMessageId: replyToMessageId,
        );
        return c.copyWith(messages: [...c.messages, msg], unreadCount: c.unreadCount);
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> setMessageReceipt({
    required String chatId,
    required String messageId,
    required ReceiptStatus receipt,
  }) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(
          messages: c.messages.map((m) {
            if (m.id != messageId) return m;
            return Message(
              id: m.id,
              chatId: m.chatId,
              authorId: m.authorId,
              kind: m.kind,
              text: m.text,
              attachmentLabel: m.attachmentLabel,
              timestamp: m.timestamp,
              receipt: receipt,
              replyToMessageId: m.replyToMessageId,
              isStarred: m.isStarred,
              isEdited: m.isEdited,
              isDeleted: m.isDeleted,
            );
          }).toList(),
        );
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> toggleStarMessage({required String chatId, required String messageId}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(
          messages: c.messages.map((m) {
            if (m.id != messageId) return m;
            return Message(
              id: m.id,
              chatId: m.chatId,
              authorId: m.authorId,
              kind: m.kind,
              text: m.text,
              attachmentLabel: m.attachmentLabel,
              timestamp: m.timestamp,
              receipt: m.receipt,
              replyToMessageId: m.replyToMessageId,
              isStarred: !m.isStarred,
              isEdited: m.isEdited,
              isDeleted: m.isDeleted,
            );
          }).toList(),
        );
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> deleteMessage({required String chatId, required String messageId}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(
          messages: c.messages.map((m) {
            if (m.id != messageId) return m;
            return Message(
              id: m.id,
              chatId: m.chatId,
              authorId: m.authorId,
              kind: m.kind,
              text: m.text,
              attachmentLabel: m.attachmentLabel,
              timestamp: m.timestamp,
              receipt: m.receipt,
              replyToMessageId: m.replyToMessageId,
              isStarred: m.isStarred,
              isEdited: m.isEdited,
              isDeleted: true,
            );
          }).toList(),
        );
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(
          messages: c.messages.map((m) {
            if (m.id != messageId) return m;
            return Message(
              id: m.id,
              chatId: m.chatId,
              authorId: m.authorId,
              kind: m.kind,
              text: trimmed,
              attachmentLabel: m.attachmentLabel,
              timestamp: m.timestamp,
              receipt: m.receipt,
              replyToMessageId: m.replyToMessageId,
              isStarred: m.isStarred,
              isEdited: true,
              isDeleted: m.isDeleted,
            );
          }).toList(),
        );
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }

  Future<void> markRead(String chatId) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        return c.copyWith(unreadCount: 0);
      }).toList(),
      statuses: _doc.statuses,
      calls: _doc.calls,
    );
    await _store.save(_doc);
  }
}

