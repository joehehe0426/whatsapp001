import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../history_controller.dart';

class ToolsScreen extends StatelessWidget {
  final HistoryController controller;

  const ToolsScreen({super.key, required this.controller});

  Future<void> _import(BuildContext context) async {
    final raw = await _promptText(
      context,
      title: 'Import JSON',
      label: 'Paste exported JSON',
      primaryAction: 'Import',
      maxLines: 14,
    );
    if (raw == null) return;
    try {
      await controller.importJson(raw);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Imported history')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _export(BuildContext context) async {
    final raw = await controller.exportJson();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Export copied to clipboard')));
  }

  Future<void> _resetSample(BuildContext context) async {
    await controller.resetToSample();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reset to sample history')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Import history JSON'),
            subtitle: const Text('Paste JSON to overwrite local history'),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export history JSON'),
            subtitle: const Text('Copies JSON to clipboard'),
            onTap: () => _export(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: const Text('Reset to sample'),
            subtitle: const Text('Replaces local history with sample data'),
            onTap: () => _resetSample(context),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text(
              'Note: This app is local-only. Nothing is sent to WhatsApp.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _promptText(
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

