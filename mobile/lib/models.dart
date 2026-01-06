import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Participant {
  final String id;
  final String displayName;

  const Participant({
    required this.id,
    required this.displayName,
  });

  factory Participant.me() => const Participant(id: 'me', displayName: 'You');

  factory Participant.other({required String displayName}) => Participant(
        id: _uuid.v4(),
        displayName: displayName,
      );

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
      };
}

class Message {
  final String id;
  final String chatId;
  final String authorId;
  final String text;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.chatId,
    required this.authorId,
    required this.text,
    required this.timestamp,
  });

  factory Message.create({
    required String chatId,
    required String authorId,
    required String text,
    DateTime? timestamp,
  }) =>
      Message(
        id: _uuid.v4(),
        chatId: chatId,
        authorId: authorId,
        text: text,
        timestamp: timestamp ?? DateTime.now(),
      );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        authorId: json['authorId'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'authorId': authorId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ChatThread {
  final String id;
  final String title;
  final List<Participant> participants;
  final List<Message> messages;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
    required this.unreadCount,
  });

  factory ChatThread.create({required String title, Participant? other}) {
    final me = Participant.me();
    final them = other ?? Participant.other(displayName: 'Contact');
    return ChatThread(
      id: _uuid.v4(),
      title: title,
      participants: [me, them],
      messages: const [],
      unreadCount: 0,
    );
  }

  ChatThread copyWith({
    String? title,
    List<Participant>? participants,
    List<Message>? messages,
    int? unreadCount,
  }) =>
      ChatThread(
        id: id,
        title: title ?? this.title,
        participants: participants ?? this.participants,
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  Participant? participantById(String id) {
    for (final p in participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        title: json['title'] as String,
        participants: (json['participants'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Participant.fromJson)
            .toList(),
        messages: (json['messages'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Message.fromJson)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'participants': participants.map((p) => p.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'unreadCount': unreadCount,
      };
}

class HistoryDocument {
  final int schemaVersion;
  final List<ChatThread> chats;

  const HistoryDocument({
    required this.schemaVersion,
    required this.chats,
  });

  factory HistoryDocument.empty() =>
      const HistoryDocument(schemaVersion: 1, chats: []);

  factory HistoryDocument.sample() {
    final chat = ChatThread.create(title: 'Alex');
    final me = chat.participantById('me')!;
    final them = chat.participants.firstWhere((p) => p.id != me.id);
    final seeded = chat.copyWith(
      messages: [
        Message.create(
          chatId: chat.id,
          authorId: them.id,
          text: 'Hey — this is a mock chat history.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        Message.create(
          chatId: chat.id,
          authorId: me.id,
          text: 'Nice. It stays on this phone only.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
        Message.create(
          chatId: chat.id,
          authorId: them.id,
          text: 'You can import/export JSON too.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ],
      unreadCount: 1,
    );
    return HistoryDocument(schemaVersion: 1, chats: [seeded]);
  }

  factory HistoryDocument.fromJson(Map<String, dynamic> json) => HistoryDocument(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        chats: (json['chats'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ChatThread.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'chats': chats.map((c) => c.toJson()).toList(),
      };
}

