import 'package:flutter/material.dart';

import '../history_controller.dart';
class StatusScreen extends StatelessWidget {
  final HistoryController controller;

  const StatusScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.statuses;
    return Scaffold(
      appBar: AppBar(title: const Text('Status')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final displayName = await _prompt(
            context,
            title: 'New status',
            label: 'Name (e.g., You, Alex)',
            primaryAction: 'Next',
          );
          if (displayName == null) return;
          final text = await _prompt(
            context,
            title: 'Status text',
            label: 'Type something',
            primaryAction: 'Add',
            maxLines: 3,
          );
          if (text == null) return;
          await controller.addStatus(displayName: displayName, text: text);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Added status')));
          // Trigger rebuild by pushing replacement (StatelessWidget).
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => StatusScreen(controller: controller)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const _Empty()
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      s.displayName.isEmpty ? '?' : s.displayName.trim()[0].toUpperCase(),
                    ),
                  ),
                  title: Text(s.displayName),
                  subtitle: Text(
                    s.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!s.viewed)
                        const Icon(Icons.circle, size: 10)
                      else
                        Icon(Icons.check, size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: s.viewed ? 'Mark unviewed' : 'Mark viewed',
                        onPressed: () async {
                          await controller.setStatusViewed(statusId: s.id, viewed: !s.viewed);
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => StatusScreen(controller: controller)),
                          );
                        },
                        icon: Icon(s.viewed ? Icons.visibility_off_outlined : Icons.visibility),
                      ),
                    ],
                  ),
                  onLongPress: () async {
                    final del = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete status?'),
                        content: const Text('Deletes this mock status locally.'),
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
                    await controller.deleteStatus(s.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => StatusScreen(controller: controller)),
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
          'Add a mock status for screenshots.',
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
  int maxLines = 1,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
      ),
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

