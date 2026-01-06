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
      final at = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
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

  Future<ChatThread> createChat({required String title}) async {
    final chat = ChatThread.create(title: title);
    _doc = HistoryDocument(schemaVersion: _doc.schemaVersion, chats: [..._doc.chats, chat]);
    await _store.save(_doc);
    return chat;
  }

  Future<void> renameChat({required String chatId, required String title}) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats
          .map((c) => c.id == chatId ? c.copyWith(title: title) : c)
          .toList(),
    );
    await _store.save(_doc);
  }

  Future<void> deleteChat(String chatId) async {
    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.where((c) => c.id != chatId).toList(),
    );
    await _store.save(_doc);
  }

  Future<void> addMessage({
    required String chatId,
    required String authorId,
    required String text,
    DateTime? timestamp,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _doc = HistoryDocument(
      schemaVersion: _doc.schemaVersion,
      chats: _doc.chats.map((c) {
        if (c.id != chatId) return c;
        final msg = Message.create(
          chatId: chatId,
          authorId: authorId,
          text: trimmed,
          timestamp: timestamp,
        );
        return c.copyWith(messages: [...c.messages, msg], unreadCount: c.unreadCount);
      }).toList(),
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
    );
    await _store.save(_doc);
  }
}

