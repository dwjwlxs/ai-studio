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
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _query = '';
  bool _isCustomMode = false;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _closeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _customController.dispose();
    super.dispose();
  }

  bool _matchesFuzzy(String text, String query) {
    if (query.isEmpty) return true;
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    if (lower.contains(q)) return true;
    // Fuzzy: all query chars appear in order
    int qi = 0;
    for (int i = 0; i < lower.length && qi < q.length; i++) {
      if (lower[i] == q[qi]) qi++;
    }
    return qi == q.length;
  }

  void _openOverlay(List<ModelInfo> models) {
    if (_isOpen) return;
    _isOpen = true;
    _query = '';
    _controller.clear();
    _focusNode.requestFocus();

    _overlayEntry = _buildOverlay(models);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _selectModel(String id) {
    widget.onChanged(id);
    _closeOverlay();
  }

  OverlayEntry _buildOverlay(List<ModelInfo> models) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-away layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown panel
          Positioned(
            width: size.width.clamp(280.0, 480.0),
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 2),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search field
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search models...',
                            prefixIcon:
                                const Icon(Icons.search, size: 18),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        size: 16),
                                    onPressed: () {
                                      _controller.clear();
                                      _query = '';
                                      _overlayEntry?.markNeedsBuild();
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            _query = v;
                            _overlayEntry?.markNeedsBuild();
                          },
                          onSubmitted: (v) {
                            // If exact match, select it
                            final match = models.firstWhere(
                              (m) => m.id.toLowerCase() ==
                                  v.trim().toLowerCase(),
                              orElse: () => models.first,
                            );
                            _selectModel(match.id);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Filtered list
                      Flexible(
                        child: _buildFilteredList(models),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(List<ModelInfo> models) {
    final filtered =
        models.where((m) => _matchesFuzzy(m.id, _query)).toList();

    if (filtered.isEmpty && !widget.allowCustom) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No models match "$_query"',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    // +1 for the "Custom model ID..." entry when allowCustom
    final extraItemCount = widget.allowCustom ? 1 : 0;
    final totalItems = filtered.length + extraItemCount;

    if (totalItems == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No models match "$_query"',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Custom model ID entry at the bottom
        if (index >= filtered.length) {
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.edit, size: 16),
            title: const Text('Custom model ID...',
                style: TextStyle(
                    fontStyle: FontStyle.italic, fontSize: 13)),
            onTap: () {
              _closeOverlay();
              _switchToCustom();
            },
          );
        }

        final model = filtered[index];
        final isSelected = model.id == widget.value;
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: isSelected,
          title: Text(
            model.id,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _selectModel(model.id),
        );
      },
    );
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
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () {
                  if (_isOpen) {
                    _closeOverlay();
                  } else {
                    _openOverlay(displayItems);
                  }
                },
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 160, maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _isOpen
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.value ?? 'Select model',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.value != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
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
