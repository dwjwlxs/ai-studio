import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/persisted_image.dart';
import '../../core/widgets/model_selector.dart';
import '../../core/widgets/error_display.dart';

class ImagePage extends ConsumerStatefulWidget {
  const ImagePage({super.key});

  @override
  ConsumerState<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends ConsumerState<ImagePage> {
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();
  final _seedController = TextEditingController();
  final _stepsController = TextEditingController();

  String _selectedSize = '1024x1024';
  String _selectedFormat = 'url';
  String _quality = 'auto';
  String _style = 'natural';
  String _background = 'auto';
  String _moderation = 'auto';
  String _outputFormat = 'png';
  int _n = 1;
  bool _showAdvanced = false;
  int _selectedHistoryIndex = -1;

  static const _sizes = [
    '256x256',
    '512x512',
    '1024x1024',
    '1792x1024',
    '1024x1792',
    '1536x1024',
    '1024x1536',
    'auto',
  ];
  static const _formats = ['url', 'b64_json'];
  static const _qualities = ['auto', 'high', 'medium', 'low', 'hd', 'standard'];
  static const _styles = ['natural', 'vivid'];
  static const _backgrounds = ['auto', 'transparent', 'opaque'];
  static const _moderations = ['auto', 'low'];
  static const _outputFormats = ['png', 'webp', 'jpeg'];

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _seedController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _generate() {
    final model = ref.read(selectedModelProvider('image'));
    if (_promptController.text.trim().isEmpty || model == null) return;
    final seedText = _seedController.text.trim();
    final stepsText = _stepsController.text.trim();
    ref.read(imageProvider.notifier).generate(
          _promptController.text.trim(),
          model,
          size: _selectedSize,
          responseFormat: _selectedFormat,
          n: _n,
          quality: _quality,
          style: _style,
          background: _background,
          moderation: _moderation,
          outputFormat: _outputFormat,
          seed: seedText.isEmpty ? null : int.tryParse(seedText),
          negativePrompt: _negativePromptController.text.trim().isEmpty
              ? null
              : _negativePromptController.text.trim(),
          numInferenceSteps:
              stepsText.isEmpty ? null : int.tryParse(stepsText),
        );
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageProvider);
    final selectedModel = ref.watch(selectedModelProvider('image'));
    final history = imageState.history;
    final currentImage = _selectedHistoryIndex >= 0 &&
            _selectedHistoryIndex < history.length
        ? history[_selectedHistoryIndex]
        : (history.isNotEmpty ? history.first : null);

    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Text('Model:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              ModelSelector(
                value: selectedModel,
                onChanged: (v) => ref
                    .read(selectedModelProvider('image').notifier)
                    .setModel(v),
              ),
            ],
          ),
        ),
        // Error
        ErrorDisplay(error: imageState.error),
        // Main content
        Expanded(
          child: Row(
            children: [
              // Image display area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Prompt input
                      TextField(
                        controller: _promptController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe the image you want to generate...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Primary parameters row
                      Row(
                        children: [
                          const Text('Size:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _selectedSize,
                            items: _sizes
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSize = v!),
                            isDense: true,
                          ),
                          const SizedBox(width: 12),
                          const Text('N:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<int>(
                            value: _n,
                            items: List.generate(
                                10,
                                (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text('${i + 1}'))),
                            onChanged: (v) => setState(() => _n = v!),
                            isDense: true,
                          ),
                          const SizedBox(width: 12),
                          const Text('Quality:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _quality,
                            items: _qualities
                                .map((q) => DropdownMenuItem(
                                    value: q, child: Text(q)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _quality = v!),
                            isDense: true,
                          ),
                          const SizedBox(width: 12),
                          const Text('Style:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _style,
                            items: _styles
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _style = v!),
                            isDense: true,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _showAdvanced = !_showAdvanced),
                            icon: Icon(
                              _showAdvanced
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                            label: Text(
                              _showAdvanced ? 'Less' : 'More',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      // Advanced parameters (collapsible)
                      if (_showAdvanced) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Background:',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _background,
                              items: _backgrounds
                                  .map((b) => DropdownMenuItem(
                                      value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _background = v!),
                              isDense: true,
                            ),
                            const SizedBox(width: 12),
                            const Text('Moderation:',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _moderation,
                              items: _moderations
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _moderation = v!),
                              isDense: true,
                            ),
                            const SizedBox(width: 12),
                            const Text('Output:',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _outputFormat,
                              items: _outputFormats
                                  .map((f) => DropdownMenuItem(
                                      value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _outputFormat = v!),
                              isDense: true,
                            ),
                            const SizedBox(width: 12),
                            const Text('Resp:',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _selectedFormat,
                              items: _formats
                                  .map((f) => DropdownMenuItem(
                                      value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedFormat = v!),
                              isDense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _seedController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Seed',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon:
                                      Icon(Icons.shuffle, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _stepsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Inference steps',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.tune,
                                      size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _negativePromptController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText:
                                'Negative prompt (things to avoid)...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed:
                                imageState.isLoading ? null : _generate,
                            icon: imageState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.image),
                            label: Text(imageState.isLoading
                                ? 'Generating...'
                                : 'Generate'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Image display
                      Expanded(
                        child: currentImage != null
                            ? Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImage(context, currentImage),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_outlined,
                                        size: 64,
                                        color:
                                            Theme.of(context).disabledColor),
                                    const SizedBox(height: 16),
                                    Text('No image generated yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                      ),
                      // Metadata
                      if (currentImage != null) ...[
                        const SizedBox(height: 8),
                        if (currentImage.revisedPrompt != null)
                          Text(
                              'Revised prompt: ${currentImage.revisedPrompt}',
                              style:
                                  Theme.of(context).textTheme.labelSmall),
                        Text(
                          'Model: ${currentImage.model} | Size: ${currentImage.size}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          'Created: ${_formatDate(currentImage.createdAt)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // History panel
              if (history.isNotEmpty)
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Text('History',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${history.length}',
                                style:
                                    Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final img = history[index];
                            final isSelected = index == _selectedHistoryIndex ||
                                (_selectedHistoryIndex < 0 && index == 0);
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedHistoryIndex = index),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      child: _buildThumbnail(img),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      onTap: () {
                                        if (img.id != null) {
                                          ref
                                              .read(imageProvider.notifier)
                                              .deleteImage(img.id!);
                                          if (_selectedHistoryIndex ==
                                              index) {
                                            setState(() =>
                                                _selectedHistoryIndex = -1);
                                          } else if (
                                              _selectedHistoryIndex >
                                                  index) {
                                            setState(() =>
                                                _selectedHistoryIndex--);
                                          }
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(Icons.close,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, PersistedImage img) {
    final file = File(img.localFilePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }
    if (img.sourceUrl != null) {
      return Image.network(img.sourceUrl!, fit: BoxFit.contain);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image,
              size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 8),
          Text('Image file not found',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildThumbnail(PersistedImage img) {
    final file = File(img.localFilePath);
    if (file.existsSync()) {
      return Image.file(file, height: 80, fit: BoxFit.cover);
    }
    return Container(
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image, size: 32),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
