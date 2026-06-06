import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class RawJsonViewer extends StatefulWidget {
  final Map<String, dynamic>? data;
  const RawJsonViewer({super.key, this.data});

  @override
  State<RawJsonViewer> createState() => _RawJsonViewerState();
}

class _RawJsonViewerState extends State<RawJsonViewer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) return const SizedBox.shrink();

    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(widget.data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18),
              const SizedBox(width: 4),
              Text('Raw JSON Response',
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy JSON',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('JSON copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              jsonStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
