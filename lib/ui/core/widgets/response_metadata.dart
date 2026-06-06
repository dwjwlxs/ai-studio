import 'package:flutter/material.dart';

class ResponseMetadata extends StatelessWidget {
  final int? latencyMs;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? model;

  const ResponseMetadata({
    super.key,
    this.latencyMs,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MetaItem>[];
    if (model != null) items.add(_MetaItem(label: 'Model', value: model!));
    if (latencyMs != null) {
      items.add(_MetaItem(label: 'Latency', value: '${latencyMs}ms'));
    }
    if (totalTokens != null && totalTokens! > 0) {
      items.add(
          _MetaItem(label: 'Tokens', value: '$totalTokens (in:$promptTokens out:$completionTokens)'));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${item.label}: ',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Theme.of(context).hintColor)),
                  Text(item.value,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ))
          .toList(),
    );
  }
}

class _MetaItem {
  final String label;
  final String value;
  _MetaItem({required this.label, required this.value});
}
