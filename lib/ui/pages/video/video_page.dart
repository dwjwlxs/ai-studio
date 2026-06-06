import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../app/providers.dart';
import '../../core/widgets/model_selector.dart';
import '../../core/widgets/error_display.dart';
import '../../../data/models/video_job.dart';

class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({super.key});

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();
  final _seedController = TextEditingController();
  final _inputReferenceController = TextEditingController();
  final _videoUriController = TextEditingController();
  String _seconds = '4';
  String _size = '1280x720';
  bool _audio = false;
  bool _showAdvanced = false;
  Player? _player;
  VideoController? _videoController;
  int _selectedJobIndex = -1;

  static const _secondsOptions = ['4', '8', '12', '16'];
  static const _sizeOptions = [
    '1280x720',
    '720x1280',
    '1920x1080',
    '1080x1920',
  ];

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player!);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _seedController.dispose();
    _inputReferenceController.dispose();
    _videoUriController.dispose();
    _player?.dispose();
    super.dispose();
  }

  void _submitJob() {
    final model = ref.read(selectedModelProvider('video'));
    if (_promptController.text.trim().isEmpty || model == null) return;
    final seedText = _seedController.text.trim();
    ref.read(videoProvider.notifier).submitJob(
          _promptController.text.trim(),
          model,
          seconds: _seconds,
          size: _size,
          negativePrompt: _negativePromptController.text.trim().isEmpty
              ? null
              : _negativePromptController.text.trim(),
          seed: seedText.isEmpty ? null : int.tryParse(seedText),
          inputReference: _inputReferenceController.text.trim().isEmpty
              ? null
              : _inputReferenceController.text.trim(),
          videoUri: _videoUriController.text.trim().isEmpty
              ? null
              : _videoUriController.text.trim(),
          audio: _audio ? true : null,
        );
    _promptController.clear();
  }

  void _playJob(VideoJob job) {
    if (job.localFilePath != null && File(job.localFilePath!).existsSync()) {
      _player?.open(Media(job.localFilePath!));
    } else if (job.resultUrl != null) {
      _player?.open(Media(job.resultUrl!));
    }
  }

  IconData _statusIcon(VideoJobStatus status) {
    switch (status) {
      case VideoJobStatus.pending:
        return Icons.schedule;
      case VideoJobStatus.processing:
        return Icons.sync;
      case VideoJobStatus.complete:
        return Icons.check_circle;
      case VideoJobStatus.failed:
        return Icons.error;
      case VideoJobStatus.cancelled:
        return Icons.cancel;
      case VideoJobStatus.unknown:
        return Icons.help;
    }
  }

  Color _statusColor(VideoJobStatus status) {
    switch (status) {
      case VideoJobStatus.pending:
        return Colors.orange;
      case VideoJobStatus.processing:
        return Colors.blue;
      case VideoJobStatus.complete:
        return Colors.green;
      case VideoJobStatus.failed:
        return Colors.red;
      case VideoJobStatus.cancelled:
        return Colors.amber;
      case VideoJobStatus.unknown:
        return Colors.grey;
    }
  }

  bool _isActive(VideoJobStatus status) {
    return status == VideoJobStatus.pending ||
        status == VideoJobStatus.processing;
  }

  String _statusMessage(VideoJob job) {
    switch (job.status) {
      case VideoJobStatus.processing:
        return 'Video is being generated...\nThis may take a few minutes.';
      case VideoJobStatus.pending:
        return 'Job submitted. Waiting to start...';
      case VideoJobStatus.failed:
        return 'Generation failed: ${job.error ?? "Unknown error"}';
      case VideoJobStatus.cancelled:
        return 'Polling cancelled.\nClick Resume to check status again.';
      default:
        return 'Unknown status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);
    final selectedModel = ref.watch(selectedModelProvider('video'));
    final jobs = videoState.jobs;
    final selectedJob = _selectedJobIndex >= 0 && _selectedJobIndex < jobs.length
        ? jobs[_selectedJobIndex]
        : (jobs.isNotEmpty ? jobs.first : null);

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
                    .read(selectedModelProvider('video').notifier)
                    .setModel(v),
              ),
            ],
          ),
        ),
        // Error
        ErrorDisplay(error: videoState.error),
        // Main content
        Expanded(
          child: Row(
            children: [
              // Video area
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
                          hintText: 'Describe the video you want to generate...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Parameters row
                      Row(
                        children: [
                          const Text('Duration:', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _seconds,
                            items: _secondsOptions
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text('${s}s')))
                                .toList(),
                            onChanged: (v) => setState(() => _seconds = v!),
                            isDense: true,
                          ),
                          const SizedBox(width: 16),
                          const Text('Size:', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _size,
                            items: _sizeOptions
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => _size = v!),
                            isDense: true,
                          ),
                          const SizedBox(width: 16),
                          const Text('Audio:', style: TextStyle(fontSize: 13)),
                          Switch(
                            value: _audio,
                            onChanged: (v) => setState(() => _audio = v),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAdvanced = !_showAdvanced),
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
                        TextField(
                          controller: _negativePromptController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Negative prompt (things to avoid)...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
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
                                  prefixIcon: Icon(Icons.shuffle, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _inputReferenceController,
                                decoration: const InputDecoration(
                                  hintText: 'Image URL (image-to-video)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon:
                                      Icon(Icons.image_outlined, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _videoUriController,
                          decoration: const InputDecoration(
                            hintText:
                                'Source video URI (video-to-video)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon:
                                Icon(Icons.videocam_outlined, size: 16),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed:
                                videoState.isSubmitting ? null : _submitJob,
                            icon: videoState.isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.videocam),
                            label: Text(videoState.isSubmitting
                                ? 'Submitting...'
                                : 'Generate Video'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Video player or status
                      Expanded(
                        child: selectedJob != null
                            ? Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _statusColor(selectedJob.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_statusIcon(selectedJob.status),
                                            color:
                                                _statusColor(selectedJob.status),
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${selectedJob.prompt.length > 50 ? '${selectedJob.prompt.substring(0, 50)}...' : selectedJob.prompt} - ${selectedJob.status.name}',
                                            style: TextStyle(
                                              color: _statusColor(selectedJob.status),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (selectedJob.status ==
                                            VideoJobStatus.processing) ...[
                                          const SizedBox(width: 8),
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child:
                                                CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('Polling...',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall),
                                        ],
                                        if (_isActive(selectedJob.status)) ...[
                                          const SizedBox(width: 8),
                                          FilledButton.tonalIcon(
                                            onPressed: () => ref
                                                .read(videoProvider.notifier)
                                                .cancelPolling(selectedJob.id),
                                            icon: const Icon(Icons.stop, size: 16),
                                            label: const Text('Cancel',
                                                style: TextStyle(fontSize: 12)),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                        if (selectedJob.status ==
                                            VideoJobStatus.cancelled) ...[
                                          const SizedBox(width: 8),
                                          FilledButton.icon(
                                            onPressed: () => ref
                                                .read(videoProvider.notifier)
                                                .resumePolling(selectedJob.id),
                                            icon: const Icon(Icons.play_arrow,
                                                size: 16),
                                            label: const Text('Resume',
                                                style: TextStyle(fontSize: 12)),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: selectedJob.status ==
                                            VideoJobStatus.complete
                                        ? Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.black,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Video(
                                                controller: _videoController!,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (selectedJob.status ==
                                                    VideoJobStatus.processing)
                                                  const CircularProgressIndicator(),
                                                if (selectedJob.status ==
                                                    VideoJobStatus.cancelled)
                                                  Icon(Icons.cancel_outlined,
                                                      size: 48,
                                                      color: Colors.amber
                                                          .withValues(alpha: 0.7)),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _statusMessage(selectedJob),
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  if (selectedJob.status ==
                                      VideoJobStatus.complete) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () => _playJob(selectedJob),
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('Play'),
                                        ),
                                        if (selectedJob.localFilePath != null) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.folder_open,
                                              size: 16,
                                              color: Theme.of(context).hintColor),
                                          Text(
                                            ' Saved locally',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_outlined,
                                        size: 64,
                                        color: Theme.of(context).disabledColor),
                                    const SizedBox(height: 16),
                                    Text('No video generated yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              // Job history
              if (jobs.isNotEmpty)
                SizedBox(
                  width: 200,
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
                            Text('${jobs.length}',
                                style:
                                    Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            final isSelected = index == _selectedJobIndex ||
                                (_selectedJobIndex < 0 && index == 0);
                            return Dismissible(
                              key: Key(job.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                ref
                                    .read(videoProvider.notifier)
                                    .deleteVideoByJobId(job.id);
                                if (_selectedJobIndex == index) {
                                  setState(() => _selectedJobIndex = -1);
                                } else if (_selectedJobIndex > index) {
                                  setState(() => _selectedJobIndex--);
                                }
                              },
                              child: ListTile(
                                selected: isSelected,
                                dense: true,
                                leading: Icon(_statusIcon(job.status),
                                    color: _statusColor(job.status),
                                    size: 18),
                                title: Text(
                                  job.prompt.length > 30
                                      ? '${job.prompt.substring(0, 30)}...'
                                      : job.prompt,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  '${job.id.substring(0, 8)}${job.localFilePath != null ? ' (local)' : ''}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Text(job.status.name,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: _statusColor(job.status))),
                                onTap: () {
                                  setState(() => _selectedJobIndex = index);
                                  if (job.status == VideoJobStatus.complete) {
                                    _playJob(job);
                                  }
                                },
                              ),
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
}
