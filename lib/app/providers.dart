import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/server_config.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_completion_request.dart';
import '../data/models/chat_completion_response.dart';
import '../data/models/image_generation_request.dart';
import '../data/models/video_job.dart';
import '../data/models/model_info.dart';
import '../data/models/conversation.dart';
import '../data/models/persisted_image.dart';
import '../data/models/network_log_entry.dart';
import '../data/services/bifrost_api_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/image_service.dart';
import '../data/services/video_service.dart';
import '../data/services/file_storage_service.dart';
import '../data/services/model_service.dart';
import '../data/services/health_service.dart';
import '../data/repositories/settings_repository.dart';
import '../data/database/chat_dao.dart';
import '../data/database/image_dao.dart';
import '../data/database/video_dao.dart';

// ─── Settings Repository ───
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

// ─── Theme Mode ───
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(settingsRepositoryProvider);
    final mode = await repo.loadThemeMode();
    state = _fromString(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveThemeMode(_toString(mode));
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

// ─── Selected Model (per page, persisted) ───
final selectedModelProvider = StateNotifierProvider.family<
    SelectedModelNotifier, String?, String>(
  (ref, page) => SelectedModelNotifier(ref, page),
);

class SelectedModelNotifier extends StateNotifier<String?> {
  final Ref _ref;
  final String _page;
  SelectedModelNotifier(this._ref, this._page) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(settingsRepositoryProvider);
    final model = await repo.loadSelectedModel(_page);
    if (mounted) state = model;
  }

  Future<void> setModel(String? model) async {
    state = model;
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveSelectedModel(_page, model);
  }
}

// ─── Server Config ───
final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, AsyncValue<ServerConfig>>(
  (ref) => ServerConfigNotifier(ref),
);

class ServerConfigNotifier extends StateNotifier<AsyncValue<ServerConfig>> {
  final Ref _ref;
  ServerConfigNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      final config = await repo.loadConfig();
      state = AsyncData(config);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateConfig(String url, String apiKey) async {
    final config = ServerConfig(
      gatewayUrl: url,
      apiKey: apiKey,
      isConfigured: true,
    );
    state = AsyncData(config);
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveConfig(config);
  }
}

// ─── Connection Status ───
final connectionStatusProvider = StateProvider<bool>((ref) => false);

// ─── Network Log ───
final networkLogProvider =
    StateNotifierProvider<NetworkLogNotifier, List<NetworkLogEntry>>(
  (ref) => NetworkLogNotifier(),
);

class NetworkLogNotifier extends StateNotifier<List<NetworkLogEntry>> {
  NetworkLogNotifier() : super([]);

  static const int _maxEntries = 500;

  void addEntry(NetworkLogEntry entry) {
    state = [entry, ...state];
    if (state.length > _maxEntries) {
      state = state.sublist(0, _maxEntries);
    }
  }

  void clear() {
    state = [];
  }

  void removeEntry(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

// ─── Bifrost API Service ───
final bifrostApiServiceProvider = Provider<BifrostApiService>((ref) {
  final configAsync = ref.watch(serverConfigProvider);
  final service = configAsync.when(
    data: (config) => BifrostApiService(
      baseUrl: config.gatewayUrl,
      apiKey: config.apiKey.isEmpty ? null : config.apiKey,
    ),
    loading: () => BifrostApiService(baseUrl: 'http://localhost:8080'),
    error: (e, st) => BifrostApiService(baseUrl: 'http://localhost:8080'),
  );
  // Wire up network log capture
  service.onNetworkLog = (entry) {
    ref.read(networkLogProvider.notifier).addEntry(entry);
  };
  return service;
});

// ─── Health Service ───
final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(ref.watch(bifrostApiServiceProvider)),
);

// ─── Model Service ───
final modelServiceProvider = Provider<ModelService>(
  (ref) => ModelService(ref.watch(bifrostApiServiceProvider)),
);

final modelsProvider = FutureProvider<List<ModelInfo>>((ref) async {
  final service = ref.watch(modelServiceProvider);
  return service.listModels();
});

// ─── Chat Service ───
final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.watch(bifrostApiServiceProvider)),
);

// ─── DAO Providers ───
final chatDaoProvider = Provider<ChatDao>((ref) => ChatDao());
final imageDaoProvider = Provider<ImageDao>((ref) => ImageDao());
final videoDaoProvider = Provider<VideoDao>((ref) => VideoDao());
final fileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => FileStorageService(),
);

// ─── Chat Generation Phase ───
enum GenerationPhase {
  idle,
  thinking, // Request sent, waiting for first token
  generating, // First token received, streaming content
}

// ─── Chat State ───
class ChatState {
  final String? conversationId;
  final List<ChatMessage> messages;
  final GenerationPhase phase;
  final String? error;
  final ChatCompletionResponse? lastResponse;
  final Duration? timeToFirstToken;
  final Duration? totalLatency;

  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.phase = GenerationPhase.idle,
    this.error,
    this.lastResponse,
    this.timeToFirstToken,
    this.totalLatency,
  });

  bool get isStreaming => phase != GenerationPhase.idle;

  ChatState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    GenerationPhase? phase,
    String? error,
    ChatCompletionResponse? lastResponse,
    Duration? timeToFirstToken,
    Duration? totalLatency,
  }) =>
      ChatState(
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        phase: phase ?? this.phase,
        error: error,
        lastResponse: lastResponse ?? this.lastResponse,
        timeToFirstToken: timeToFirstToken ?? this.timeToFirstToken,
        totalLatency: totalLatency ?? this.totalLatency,
      );
}

// ─── Conversation List Provider ───
final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, List<Conversation>>(
  (ref) => ConversationListNotifier(ref),
);

class ConversationListNotifier extends StateNotifier<List<Conversation>> {
  final Ref _ref;
  ConversationListNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final dao = _ref.read(chatDaoProvider);
    final conversations = await dao.getAllConversations();
    if (mounted) state = conversations;
  }

  Future<void> refresh() async {
    await _load();
  }
}

// ─── Chat Provider ───
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<String>? _streamSub;
  DateTime? _requestStartTime;
  bool _firstTokenReceived = false;
  String? _lastUsedModel;

  ChatNotifier(this._ref) : super(const ChatState());

  Future<void> sendMessage(
    String content,
    String model, {
    double? temperature,
    int? maxTokens,
    double? topP,
    bool stream = true,
  }) async {
    _requestStartTime = DateTime.now();
    _firstTokenReceived = false;
    _lastUsedModel = model;

    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      conversationId: state.conversationId,
    );

    // Ensure conversation exists
    String convId = state.conversationId ?? const Uuid().v4();
    final dao = _ref.read(chatDaoProvider);
    if (state.conversationId == null) {
      final conv = Conversation(
        id: convId,
        model: model,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dao.insertConversation(conv);
      await _ref.read(conversationListProvider.notifier).refresh();
    } else {
      // Update model if changed
      await dao.updateConversationModel(convId, model);
    }

    // Persist user message
    final userSortOrder = state.messages.length;
    await dao.insertMessage(userMessage, convId, sortOrder: userSortOrder);

    final newMessages = [...state.messages, userMessage];
    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
      conversationId: convId,
    );
    newMessages.add(assistantMessage);

    state = state.copyWith(
      conversationId: convId,
      messages: newMessages,
      phase: GenerationPhase.thinking,
      error: null,
      timeToFirstToken: null,
      totalLatency: null,
    );

    final messagesList = newMessages
        .where((m) => m.role != MessageRole.assistant || m.content.isNotEmpty)
        .map((m) => <String, String>{
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final request = ChatCompletionRequest(
      model: model,
      messages: messagesList,
      stream: stream,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
    );

    final service = _ref.read(chatServiceProvider);
    final needsTitle = state.messages.where((m) => m.role == MessageRole.assistant && !m.isStreaming).isEmpty;

    try {
      if (stream) {
        final stream$ = service.completeStream(request);
        String fullContent = '';
        _streamSub = stream$.listen(
          (delta) {
            if (!_firstTokenReceived) {
              _firstTokenReceived = true;
              final ttft = DateTime.now().difference(_requestStartTime!);
              state = state.copyWith(
                phase: GenerationPhase.generating,
                timeToFirstToken: ttft,
              );
            }
            fullContent += delta;
            final updated = [...state.messages];
            updated[lastAssistantIndex(updated)] = ChatMessage(
              role: MessageRole.assistant,
              content: fullContent,
              timestamp: assistantMessage.timestamp,
              isStreaming: true,
              conversationId: convId,
            );
            state = state.copyWith(messages: updated);
          },
          onDone: () async {
            final totalLatency =
                DateTime.now().difference(_requestStartTime!);
            final completedAssistant = ChatMessage(
              role: MessageRole.assistant,
              content: fullContent,
              timestamp: assistantMessage.timestamp,
              isStreaming: false,
              conversationId: convId,
            );
            final updated = [...state.messages];
            updated[lastAssistantIndex(updated)] = completedAssistant;
            state = state.copyWith(
              messages: updated,
              phase: GenerationPhase.idle,
              totalLatency: totalLatency,
            );
            // Persist completed assistant message
            await dao.insertMessage(
                completedAssistant, convId, sortOrder: updated.length - 1);
            await dao.updateConversationTimestamp(convId);
            await dao.updateConversationModel(convId, model);
            await _ref.read(conversationListProvider.notifier).refresh();
            // Generate title if first exchange
            if (needsTitle) {
              _generateTitle(convId, content, fullContent);
            }
          },
          onError: (e) async {
            final totalLatency =
                DateTime.now().difference(_requestStartTime!);
            state = state.copyWith(
              phase: GenerationPhase.idle,
              error: e.toString(),
              totalLatency: totalLatency,
            );
          },
        );
      } else {
        final response = await service.complete(request);
        final ttft = DateTime.now().difference(_requestStartTime!);
        final completedAssistant = ChatMessage(
          role: MessageRole.assistant,
          content: response.content,
          timestamp: assistantMessage.timestamp,
          isStreaming: false,
          conversationId: convId,
        );
        final updated = [...state.messages];
        updated[lastAssistantIndex(updated)] = completedAssistant;
        state = state.copyWith(
          messages: updated,
          phase: GenerationPhase.idle,
          lastResponse: response,
          timeToFirstToken: ttft,
          totalLatency: ttft,
        );
        // Persist
        await dao.insertMessage(
            completedAssistant, convId, sortOrder: updated.length - 1);
        await dao.updateConversationTimestamp(convId);
        await dao.updateConversationModel(convId, model);
        await _ref.read(conversationListProvider.notifier).refresh();
        if (needsTitle) {
          _generateTitle(convId, content, response.content);
        }
      }
    } catch (e) {
      final totalLatency = DateTime.now().difference(_requestStartTime!);
      state = state.copyWith(
        phase: GenerationPhase.idle,
        error: e.toString(),
        totalLatency: totalLatency,
      );
    }
  }

  Future<void> _generateTitle(
      String convId, String userMsg, String assistantMsg) async {
    try {
      final service = _ref.read(chatServiceProvider);
      final response = await service.complete(ChatCompletionRequest(
        model: _lastUsedModel ?? 'gpt-4o',
        messages: [
          {
            'role': 'system',
            'content':
                'Summarize this conversation in 5-10 words. Output only the title, nothing else.'
          },
          {'role': 'user', 'content': userMsg},
          {
            'role': 'assistant',
            'content':
                assistantMsg.length > 500 ? assistantMsg.substring(0, 500) : assistantMsg
          },
        ],
        maxTokens: 20,
        temperature: 0.3,
        stream: false,
      ));
      final title = response.content.trim();
      if (title.isNotEmpty) {
        final dao = _ref.read(chatDaoProvider);
        await dao.updateConversationTitle(convId, title);
        await _ref.read(conversationListProvider.notifier).refresh();
      }
    } catch (_) {
      // Fallback: use first 30 chars of user message
      final fallback = userMsg.length > 30
          ? '${userMsg.substring(0, 30)}...'
          : userMsg;
      final dao = _ref.read(chatDaoProvider);
      await dao.updateConversationTitle(convId, fallback);
      await _ref.read(conversationListProvider.notifier).refresh();
    }
  }

  int lastAssistantIndex(List<ChatMessage> messages) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.assistant) return i;
    }
    return messages.length - 1;
  }

  void stopStreaming() async {
    _streamSub?.cancel();
    _streamSub = null;
    final totalLatency =
        _requestStartTime != null ? DateTime.now().difference(_requestStartTime!) : null;
    final updated = state.messages.map((m) {
      if (m.isStreaming) return m.copyWith(isStreaming: false);
      return m;
    }).toList();
    state = state.copyWith(
      messages: updated,
      phase: GenerationPhase.idle,
      totalLatency: totalLatency,
    );
    // Persist the partial assistant message
    if (state.conversationId != null) {
      final dao = _ref.read(chatDaoProvider);
      final lastAssistant = updated.lastWhere(
        (m) => m.role == MessageRole.assistant,
        orElse: () => ChatMessage(role: MessageRole.assistant, content: ''),
      );
      if (lastAssistant.content.isNotEmpty) {
        await dao.insertMessage(
            lastAssistant, state.conversationId!, sortOrder: updated.length - 1);
        await dao.updateConversationTimestamp(state.conversationId!);
      }
    }
  }

  Future<void> newConversation() async {
    _streamSub?.cancel();
    _streamSub = null;
    state = const ChatState();
  }

  Future<void> selectConversation(String id) async {
    _streamSub?.cancel();
    _streamSub = null;
    final dao = _ref.read(chatDaoProvider);
    final messages = await dao.getMessages(id);
    state = ChatState(
      conversationId: id,
      messages: messages,
    );
  }

  Future<void> deleteConversation(String id) async {
    final dao = _ref.read(chatDaoProvider);
    await dao.deleteConversation(id);
    await _ref.read(conversationListProvider.notifier).refresh();
    if (state.conversationId == id) {
      state = const ChatState();
    }
  }

  Future<void> clearMessages() async {
    if (state.conversationId != null) {
      final dao = _ref.read(chatDaoProvider);
      await dao.deleteMessages(state.conversationId!);
      await dao.updateConversationTimestamp(state.conversationId!);
    }
    state = state.copyWith(messages: [], error: null);
  }
}

// ─── Image Service ───
final imageServiceProvider = Provider<ImageService>(
  (ref) => ImageService(ref.watch(bifrostApiServiceProvider)),
);

// ─── Image State ───
class ImageState {
  final List<PersistedImage> history;
  final bool isLoading;
  final String? error;

  const ImageState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  ImageState copyWith({
    List<PersistedImage>? history,
    bool? isLoading,
    String? error,
  }) =>
      ImageState(
        history: history ?? this.history,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final imageProvider = StateNotifierProvider<ImageNotifier, ImageState>(
  (ref) => ImageNotifier(ref),
);

class ImageNotifier extends StateNotifier<ImageState> {
  final Ref _ref;
  ImageNotifier(this._ref) : super(const ImageState()) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(imageDaoProvider);
    final images = await dao.getAllImages();
    if (mounted) state = state.copyWith(history: images);
  }

  Future<void> generate(
    String prompt,
    String model, {
    String size = '1024x1024',
    String responseFormat = 'url',
    int? n,
    String? quality,
    String? style,
    String? background,
    String? moderation,
    String? outputFormat,
    int? outputCompression,
    int? partialImages,
    int? seed,
    String? negativePrompt,
    int? numInferenceSteps,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(imageServiceProvider);
      final fileStorage = _ref.read(fileStorageServiceProvider);
      final dao = _ref.read(imageDaoProvider);
      final request = ImageGenerationRequest(
        model: model,
        prompt: prompt,
        size: size,
        responseFormat: responseFormat,
        n: n,
        quality: quality,
        style: style,
        background: background,
        moderation: moderation,
        outputFormat: outputFormat,
        outputCompression: outputCompression,
        partialImages: partialImages,
        seed: seed,
        negativePrompt: negativePrompt,
        numInferenceSteps: numInferenceSteps,
      );
      final response = await service.generate(request);

      // Save each image to local file and persist to DB
      for (final img in response.images) {
        String localFilePath;
        String? sourceUrl;
        if (img.url != null) {
          sourceUrl = img.url;
          localFilePath = await fileStorage.saveImageFromUrl(img.url!);
        } else if (img.b64Json != null) {
          localFilePath =
              await fileStorage.saveImageFromBase64(img.b64Json!);
        } else {
          continue;
        }
        final persisted = PersistedImage(
          prompt: prompt,
          model: model,
          size: size,
          revisedPrompt: img.revisedPrompt,
          localFilePath: localFilePath,
          sourceUrl: sourceUrl,
          createdAt: DateTime.now(),
        );
        await dao.insertImage(persisted);
      }

      // Reload from DB
      await _loadFromDb();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteImage(int id) async {
    final dao = _ref.read(imageDaoProvider);
    await dao.deleteImage(id);
    await _loadFromDb();
  }
}

// ─── Video Service ───
final videoServiceProvider = Provider<VideoService>(
  (ref) => VideoService(ref.watch(bifrostApiServiceProvider)),
);

// ─── Video State ───
class VideoState {
  final List<VideoJob> jobs;
  final bool isSubmitting;
  final String? error;

  const VideoState({
    this.jobs = const [],
    this.isSubmitting = false,
    this.error,
  });

  VideoState copyWith({
    List<VideoJob>? jobs,
    bool? isSubmitting,
    String? error,
  }) =>
      VideoState(
        jobs: jobs ?? this.jobs,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );
}

final videoProvider = StateNotifierProvider<VideoNotifier, VideoState>(
  (ref) => VideoNotifier(ref),
);

class VideoNotifier extends StateNotifier<VideoState> {
  final Ref _ref;
  Timer? _pollTimer;
  final Map<String, Timer> _activeTimers = {};

  VideoNotifier(this._ref) : super(const VideoState()) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(videoDaoProvider);
    final videos = await dao.getAllVideos();
    if (mounted) {
      state = state.copyWith(jobs: videos);
      // Resume polling for incomplete jobs
      for (final job in videos) {
        if (job.status == VideoJobStatus.pending ||
            job.status == VideoJobStatus.processing) {
          _startPolling(job.id);
        }
      }
    }
  }

  Future<void> submitJob(
    String prompt,
    String model, {
    String? seconds,
    String? size,
    String? negativePrompt,
    int? seed,
    String? inputReference,
    String? videoUri,
    bool? audio,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final service = _ref.read(videoServiceProvider);
      final job = await service.submitJob(
        prompt,
        model,
        seconds: seconds,
        size: size,
        negativePrompt: negativePrompt,
        seed: seed,
        inputReference: inputReference,
        videoUri: videoUri,
        audio: audio,
      );
      state = state.copyWith(
        jobs: [...state.jobs, job],
        isSubmitting: false,
      );
      // Persist to DB
      final dao = _ref.read(videoDaoProvider);
      await dao.insertVideo(job.copyWith(createdAt: DateTime.now()));
      _startPolling(job.id);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void _startPolling(String jobId) {
    _activeTimers[jobId]?.cancel();
    _activeTimers[jobId] =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final service = _ref.read(videoServiceProvider);
        final jobIndex = state.jobs.indexWhere((j) => j.id == jobId);
        if (jobIndex == -1) {
          timer.cancel();
          _activeTimers.remove(jobId);
          return;
        }
        final updated = await service.pollStatus(state.jobs[jobIndex]);
        final newJobs = [...state.jobs];
        newJobs[jobIndex] = updated;
        state = state.copyWith(jobs: newJobs);

        // Update DB
        final dao = _ref.read(videoDaoProvider);
        await dao.updateVideoStatus(
          jobId,
          status: updated.status.name,
          resultUrl: updated.resultUrl,
          error: updated.error,
        );

        if (updated.status == VideoJobStatus.complete) {
          timer.cancel();
          _activeTimers.remove(jobId);
          // Download video file
          await _downloadVideo(jobId, updated);
        } else if (updated.status == VideoJobStatus.failed) {
          timer.cancel();
          _activeTimers.remove(jobId);
        }
      } catch (e) {
        // Continue polling on transient errors
      }
    });
  }

  Future<void> _downloadVideo(String jobId, VideoJob job) async {
    try {
      final service = _ref.read(videoServiceProvider);
      final fileStorage = _ref.read(fileStorageServiceProvider);
      // Prefer the direct video URL from API response (e.g. signed OSS URL),
      // fall back to Bifrost content proxy endpoint
      final downloadUrl =
          job.resultUrl ?? service.getContentUrl(jobId);
      final localPath =
          await fileStorage.saveVideoFromUrl(downloadUrl, filename: jobId);

      // Update state
      final newJobs = [...state.jobs];
      final jobIndex = newJobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        newJobs[jobIndex] = newJobs[jobIndex].copyWith(localFilePath: localPath);
        state = state.copyWith(jobs: newJobs);
      }

      // Update DB
      final dao = _ref.read(videoDaoProvider);
      await dao.updateVideoStatus(jobId, localFilePath: localPath);
    } catch (_) {
      // Download failed, keep URL-based playback as fallback
    }
  }

  Future<void> deleteVideo(int id) async {
    final dao = _ref.read(videoDaoProvider);
    await dao.deleteVideo(id);
    await _loadFromDb();
  }

  Future<void> deleteVideoByJobId(String jobId) async {
    _activeTimers[jobId]?.cancel();
    _activeTimers.remove(jobId);
    final dao = _ref.read(videoDaoProvider);
    await dao.deleteVideoByJobId(jobId);
    await _loadFromDb();
  }

  void cancelPolling(String jobId) {
    _activeTimers[jobId]?.cancel();
    _activeTimers.remove(jobId);
    // Update state
    final newJobs = [...state.jobs];
    final jobIndex = newJobs.indexWhere((j) => j.id == jobId);
    if (jobIndex != -1) {
      newJobs[jobIndex] = newJobs[jobIndex].copyWith(
        status: VideoJobStatus.cancelled,
      );
      state = state.copyWith(jobs: newJobs);
    }
    // Update DB
    _ref.read(videoDaoProvider).updateVideoStatus(
          jobId,
          status: 'cancelled',
        );
  }

  void resumePolling(String jobId) {
    final newJobs = [...state.jobs];
    final jobIndex = newJobs.indexWhere((j) => j.id == jobId);
    if (jobIndex != -1) {
      newJobs[jobIndex] = newJobs[jobIndex].copyWith(
        status: VideoJobStatus.processing,
      );
      state = state.copyWith(jobs: newJobs);
    }
    // Update DB
    _ref.read(videoDaoProvider).updateVideoStatus(
          jobId,
          status: 'processing',
        );
    _startPolling(jobId);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
