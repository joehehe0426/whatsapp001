import 'package:flutter/material.dart';

import '../history_controller.dart';
import '../models.dart';

class CallsScreen extends StatelessWidget {
  final HistoryController controller;

  const CallsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final calls = controller.calls;
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _prompt(
            context,
            title: 'New call',
            label: 'Name (e.g., Alex)',
            primaryAction: 'Next',
          );
          if (name == null) return;
          final type = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.call_received_outlined),
                    title: const Text('Incoming'),
                    onTap: () => Navigator.of(context).pop('incoming'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_made_outlined),
                    title: const Text('Outgoing'),
                    onTap: () => Navigator.of(context).pop('outgoing'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.call_missed_outlined),
                    title: const Text('Missed'),
                    onTap: () => Navigator.of(context).pop('missed'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
          if (type == null) return;
          final isVideo = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Call type'),
              content: const Text('Is it a video call?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Voice'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Video'),
                ),
              ],
            ),
          );
          final direction = switch (type) {
            'incoming' => CallDirection.incoming,
            'outgoing' => CallDirection.outgoing,
            'missed' => CallDirection.missed,
            _ => CallDirection.incoming,
          };
          await controller.addCall(
            displayName: name,
            direction: direction,
            isVideo: isVideo ?? false,
            durationSeconds: direction == CallDirection.missed ? 0 : 60,
          );
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => CallsScreen(controller: controller)),
          );
        },
        child: const Icon(Icons.add_call),
      ),
      body: calls.isEmpty
          ? const _Empty()
          : ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = calls[i];
                final icon = switch (c.direction) {
                  CallDirection.incoming => Icons.call_received_outlined,
                  CallDirection.outgoing => Icons.call_made_outlined,
                  CallDirection.missed => Icons.call_missed_outlined,
                };
                final color = c.direction == CallDirection.missed
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).hintColor;
                final trailingIcon = c.isVideo ? Icons.videocam_outlined : Icons.call_outlined;
                final subtitle = '${c.direction.name} • ${c.durationSeconds}s';
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(c.displayName),
                  subtitle: Text(subtitle),
                  trailing: Icon(trailingIcon),
                  onLongPress: () async {
                    final del = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete call?'),
                        content: const Text('Deletes this mock call locally.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (del != true) return;
                    await controller.deleteCall(c.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => CallsScreen(controller: controller)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Add mock call history for screenshots.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

Future<String?> _prompt(
  BuildContext context, {
  required String title,
  required String label,
  required String primaryAction,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(primaryAction),
        ),
      ],
    ),
  );
}

