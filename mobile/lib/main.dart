import 'dart:async';

import 'package:flutter/material.dart';

import 'history_controller.dart';
import 'history_store.dart';
import 'screens/chat_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = HistoryController(HistoryStore());
  await controller.loadOrSeed();

  runApp(ChatHistoryMockApp(controller: controller));
}

class ChatHistoryMockApp extends StatelessWidget {
  final HistoryController controller;

  const ChatHistoryMockApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0A8F5B));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat History Mock',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
      ),
      home: ChatListScreen(controller: controller),
    );
  }
}

