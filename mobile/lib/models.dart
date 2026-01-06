import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum MessageKind {
  text,
  attachment,
}

MessageKind messageKindFromJson(Object? value) {
  final raw = value?.toString();
  for (final k in MessageKind.values) {
    if (k.name == raw) return k;
  }
  return MessageKind.text;
}

enum ReceiptStatus {
  none,
  sent,
  delivered,
  read,
}

ReceiptStatus receiptStatusFromJson(Object? value) {
  final raw = value?.toString();
  for (final s in ReceiptStatus.values) {
    if (s.name == raw) return s;
  }
  return ReceiptStatus.none;
}

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
  final MessageKind kind;
  final String text;
  final String? attachmentLabel;
  final DateTime timestamp;
  final ReceiptStatus receipt;
  final String? replyToMessageId;
  final bool isStarred;
  final bool isEdited;
  final bool isDeleted;

  const Message({
    required this.id,
    required this.chatId,
    required this.authorId,
    required this.kind,
    required this.text,
    required this.attachmentLabel,
    required this.timestamp,
    required this.receipt,
    required this.replyToMessageId,
    required this.isStarred,
    required this.isEdited,
    required this.isDeleted,
  });

  factory Message.create({
    required String chatId,
    required String authorId,
    required String text,
    MessageKind kind = MessageKind.text,
    String? attachmentLabel,
    DateTime? timestamp,
    ReceiptStatus receipt = ReceiptStatus.none,
    String? replyToMessageId,
    bool isStarred = false,
    bool isEdited = false,
    bool isDeleted = false,
  }) =>
      Message(
        id: _uuid.v4(),
        chatId: chatId,
        authorId: authorId,
        kind: kind,
        text: text,
        attachmentLabel: attachmentLabel,
        timestamp: timestamp ?? DateTime.now(),
        receipt: receipt,
        replyToMessageId: replyToMessageId,
        isStarred: isStarred,
        isEdited: isEdited,
        isDeleted: isDeleted,
      );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        authorId: json['authorId'] as String,
        kind: messageKindFromJson(json['kind']),
        text: (json['text'] as String?) ?? '',
        attachmentLabel: json['attachmentLabel'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        receipt: receiptStatusFromJson(json['receipt']),
        replyToMessageId: json['replyToMessageId'] as String?,
        isStarred: json['isStarred'] as bool? ?? false,
        isEdited: json['isEdited'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'authorId': authorId,
        'kind': kind.name,
        'text': text,
        'attachmentLabel': attachmentLabel,
        'timestamp': timestamp.toIso8601String(),
        'receipt': receipt.name,
        'replyToMessageId': replyToMessageId,
        'isStarred': isStarred,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
      };
}

class ChatThread {
  final String id;
  final String title;
  final List<Participant> participants;
  final List<Message> messages;
  final int unreadCount;
  final bool isArchived;
  final bool isPinned;

  const ChatThread({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
    required this.unreadCount,
    required this.isArchived,
    required this.isPinned,
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
      isArchived: false,
      isPinned: false,
    );
  }

  factory ChatThread.createGroup({
    required String title,
    required List<String> memberNames,
  }) {
    final me = Participant.me();
    final members = memberNames
        .where((n) => n.trim().isNotEmpty)
        .map((n) => Participant.other(displayName: n.trim()))
        .toList();
    return ChatThread(
      id: _uuid.v4(),
      title: title,
      participants: [me, ...members],
      messages: const [],
      unreadCount: 0,
      isArchived: false,
      isPinned: false,
    );
  }

  ChatThread copyWith({
    String? title,
    List<Participant>? participants,
    List<Message>? messages,
    int? unreadCount,
    bool? isArchived,
    bool? isPinned,
  }) =>
      ChatThread(
        id: id,
        title: title ?? this.title,
        participants: participants ?? this.participants,
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
        isArchived: isArchived ?? this.isArchived,
        isPinned: isPinned ?? this.isPinned,
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
        isArchived: json['isArchived'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'participants': participants.map((p) => p.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'unreadCount': unreadCount,
        'isArchived': isArchived,
        'isPinned': isPinned,
      };
}

enum CallDirection {
  incoming,
  outgoing,
  missed,
}

CallDirection callDirectionFromJson(Object? value) {
  final raw = value?.toString();
  for (final d in CallDirection.values) {
    if (d.name == raw) return d;
  }
  return CallDirection.incoming;
}

class CallEntry {
  final String id;
  final String displayName;
  final CallDirection direction;
  final bool isVideo;
  final DateTime timestamp;
  final int durationSeconds;

  const CallEntry({
    required this.id,
    required this.displayName,
    required this.direction,
    required this.isVideo,
    required this.timestamp,
    required this.durationSeconds,
  });

  factory CallEntry.create({
    required String displayName,
    required CallDirection direction,
    required bool isVideo,
    DateTime? timestamp,
    int durationSeconds = 0,
  }) =>
      CallEntry(
        id: _uuid.v4(),
        displayName: displayName,
        direction: direction,
        isVideo: isVideo,
        timestamp: timestamp ?? DateTime.now(),
        durationSeconds: durationSeconds,
      );

  factory CallEntry.fromJson(Map<String, dynamic> json) => CallEntry(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        direction: callDirectionFromJson(json['direction']),
        isVideo: json['isVideo'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'direction': direction.name,
        'isVideo': isVideo,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
      };
}

class StatusItem {
  final String id;
  final String displayName;
  final String text;
  final DateTime timestamp;
  final bool viewed;

  const StatusItem({
    required this.id,
    required this.displayName,
    required this.text,
    required this.timestamp,
    required this.viewed,
  });

  factory StatusItem.create({
    required String displayName,
    required String text,
    DateTime? timestamp,
    bool viewed = false,
  }) =>
      StatusItem(
        id: _uuid.v4(),
        displayName: displayName,
        text: text,
        timestamp: timestamp ?? DateTime.now(),
        viewed: viewed,
      );

  factory StatusItem.fromJson(Map<String, dynamic> json) => StatusItem(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        text: (json['text'] as String?) ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        viewed: json['viewed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'viewed': viewed,
      };
}

class HistoryDocument {
  final int schemaVersion;
  final List<ChatThread> chats;
  final List<StatusItem> statuses;
  final List<CallEntry> calls;

  const HistoryDocument({
    required this.schemaVersion,
    required this.chats,
    required this.statuses,
    required this.calls,
  });

  factory HistoryDocument.empty() =>
      const HistoryDocument(schemaVersion: 3, chats: [], statuses: [], calls: []);

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
          receipt: ReceiptStatus.read,
        ),
        Message.create(
          chatId: chat.id,
          authorId: them.id,
          text: 'You can import/export JSON too.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        Message.create(
          chatId: chat.id,
          authorId: me.id,
          kind: MessageKind.attachment,
          text: '',
          attachmentLabel: 'Photo (placeholder)',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          receipt: ReceiptStatus.delivered,
        ),
      ],
      unreadCount: 1,
    );
    final group = ChatThread.createGroup(
      title: 'Weekend Plans',
      memberNames: const ['Sam', 'Taylor'],
    );
    final groupMe = group.participantById('me')!;
    final groupThem = group.participants.firstWhere((p) => p.id != groupMe.id);
    final seededGroup = group.copyWith(
      isPinned: true,
      messages: [
        Message.create(
          chatId: group.id,
          authorId: groupThem.id,
          text: 'Mock group chat works too.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
        ),
        Message.create(
          chatId: group.id,
          authorId: groupMe.id,
          text: 'Long-press a message for reply/star/edit/delete.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 8)),
          receipt: ReceiptStatus.read,
        ),
      ],
      unreadCount: 0,
    );
    final statuses = [
      StatusItem.create(
        displayName: 'You',
        text: 'Mock status: having a great day.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        viewed: true,
      ),
      StatusItem.create(
        displayName: 'Alex',
        text: 'Mock status: coffee time.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
        viewed: false,
      ),
    ];
    final calls = [
      CallEntry.create(
        displayName: 'Alex',
        direction: CallDirection.incoming,
        isVideo: false,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        durationSeconds: 184,
      ),
      CallEntry.create(
        displayName: 'Weekend Plans',
        direction: CallDirection.missed,
        isVideo: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 9)),
        durationSeconds: 0,
      ),
    ];
    return HistoryDocument(schemaVersion: 3, chats: [seededGroup, seeded], statuses: statuses, calls: calls);
  }

  factory HistoryDocument.fromJson(Map<String, dynamic> json) => HistoryDocument(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        chats: (json['chats'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ChatThread.fromJson)
            .toList(),
        statuses: (json['statuses'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(StatusItem.fromJson)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        calls: (json['calls'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CallEntry.fromJson)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'chats': chats.map((c) => c.toJson()).toList(),
        'statuses': statuses.map((s) => s.toJson()).toList(),
        'calls': calls.map((c) => c.toJson()).toList(),
      };
}

