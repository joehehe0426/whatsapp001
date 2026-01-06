import 'package:flutter/material.dart';

import '../history_controller.dart';
import 'calls_screen.dart';
import 'chat_list_screen.dart';
import 'status_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatefulWidget {
  final HistoryController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ChatListScreen(controller: widget.controller),
          StatusScreen(controller: widget.controller),
          CallsScreen(controller: widget.controller),
          ToolsScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.donut_small_outlined), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'Tools'),
        ],
      ),
    );
  }
}

