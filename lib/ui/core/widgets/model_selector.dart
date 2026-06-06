import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/model_info.dart';

class ModelSelector extends ConsumerStatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool Function(ModelInfo)? filter;
  final bool allowCustom;

  const ModelSelector({
    super.key,
    this.value,
    required this.onChanged,
    this.filter,
    this.allowCustom = true,
  });

  @override
  ConsumerState<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<ModelSelector> {
  final _customController = TextEditingController();
  bool _isCustomMode = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _switchToCustom() {
    setState(() {
      _isCustomMode = true;
      if (widget.value != null) {
        _customController.text = widget.value!;
      }
    });
  }

  void _switchToDropdown() {
    setState(() {
      _isCustomMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsProvider);

    return modelsAsync.when(
      loading: () => const SizedBox(
        width: 200,
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCustomInput(hint: 'Type model ID (list failed)'),
          _RefreshButton(onRefresh: () => ref.invalidate(modelsProvider)),
        ],
      ),
      data: (models) {
        final filtered =
            widget.filter != null ? models.where(widget.filter!) : models;
        final items = filtered.toList();
        final allModels = models.toList();

        // If filter produced no results but there are models available,
        // show all models instead
        final displayItems = items.isEmpty && allModels.isNotEmpty
            ? allModels
            : items;

        if (_isCustomMode) {
          return _buildCustomInput(hint: 'e.g. openai/dall-e-3');
        }

        if (displayItems.isEmpty) {
          return _buildCustomInput(hint: 'No models found — type model ID');
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: widget.value != null &&
                      displayItems.any((m) => m.id == widget.value)
                  ? widget.value
                  : null,
              hint: Text(
                widget.value ?? 'Select model',
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                ...displayItems
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.id,
                              overflow: TextOverflow.ellipsis),
                        )),
                if (widget.allowCustom)
                  const DropdownMenuItem<String>(
                    value: '__custom__',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14),
                        SizedBox(width: 4),
                        Text('Custom model ID...',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == '__custom__') {
                  _switchToCustom();
                } else {
                  widget.onChanged(v);
                }
              },
              isDense: true,
            ),
            if (widget.value != null &&
                !displayItems.any((m) => m.id == widget.value))
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message:
                      'Current model "${widget.value}" not in list — click ✏️ to edit',
                  child: InkWell(
                    onTap: _switchToCustom,
                    child: Icon(Icons.edit,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            _RefreshButton(
              onRefresh: () => ref.invalidate(modelsProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomInput({required String hint}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _customController,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, size: 16),
                tooltip: 'Confirm',
                onPressed: () {
                  if (_customController.text.trim().isNotEmpty) {
                    widget.onChanged(_customController.text.trim());
                  }
                },
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                widget.onChanged(v.trim());
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          tooltip: 'Back to list',
          onPressed: _switchToDropdown,
        ),
      ],
    );
  }
}

// ─── Refresh button for model list ───
class _RefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;
  const _RefreshButton({required this.onRefresh});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _isRefreshing = false;

  void _handleRefresh() {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    widget.onRefresh();
    // Give the FutureProvider time to start loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isRefreshing
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(Icons.refresh,
              size: 18, color: Theme.of(context).colorScheme.primary),
      tooltip: 'Refresh model list',
      onPressed: _handleRefresh,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
    );
  }
}
