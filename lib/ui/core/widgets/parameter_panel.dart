import 'package:flutter/material.dart';

class ParameterPanel extends StatefulWidget {
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final ValueChanged<double?> onTemperatureChanged;
  final ValueChanged<int?> onMaxTokensChanged;
  final ValueChanged<double?> onTopPChanged;

  const ParameterPanel({
    super.key,
    this.temperature,
    this.maxTokens,
    this.topP,
    required this.onTemperatureChanged,
    required this.onMaxTokensChanged,
    required this.onTopPChanged,
  });

  @override
  State<ParameterPanel> createState() => _ParameterPanelState();
}

class _ParameterPanelState extends State<ParameterPanel> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Parameters', style: TextStyle(fontSize: 14)),
      initiallyExpanded: false,
      dense: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text('Temperature: ${widget.temperature?.toStringAsFixed(2) ?? "default"}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Slider(
                      value: widget.temperature ?? 1.0,
                      min: 0,
                      max: 2,
                      divisions: 20,
                      label: (widget.temperature ?? 1.0).toStringAsFixed(2),
                      onChanged: (v) => widget.onTemperatureChanged(v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Reset',
                    onPressed: () => widget.onTemperatureChanged(null),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text('Max Tokens: ${widget.maxTokens ?? "default"}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Slider(
                      value: (widget.maxTokens ?? 4096).toDouble(),
                      min: 1,
                      max: 32768,
                      divisions: 100,
                      label: '${widget.maxTokens ?? 4096}',
                      onChanged: (v) => widget.onMaxTokensChanged(v.toInt()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Reset',
                    onPressed: () => widget.onMaxTokensChanged(null),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text('Top P: ${widget.topP?.toStringAsFixed(2) ?? "default"}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Slider(
                      value: widget.topP ?? 1.0,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      label: (widget.topP ?? 1.0).toStringAsFixed(2),
                      onChanged: (v) => widget.onTopPChanged(v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Reset',
                    onPressed: () => widget.onTopPChanged(null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
