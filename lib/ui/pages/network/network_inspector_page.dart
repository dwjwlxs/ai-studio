import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/network_log_entry.dart';

class NetworkInspectorPage extends ConsumerStatefulWidget {
  const NetworkInspectorPage({super.key});

  @override
  ConsumerState<NetworkInspectorPage> createState() =>
      _NetworkInspectorPageState();
}

class _NetworkInspectorPageState extends ConsumerState<NetworkInspectorPage> {
  NetworkLogEntry? _selected;
  String _filterMethod = 'ALL';
  String _searchQuery = '';

  List<NetworkLogEntry> _filtered(List<NetworkLogEntry> entries) {
    return entries.where((e) {
      if (_filterMethod != 'ALL' && e.method != _filterMethod) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return e.url.toLowerCase().contains(q) ||
            e.method.toLowerCase().contains(q) ||
            (e.statusCode?.toString().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(networkLogProvider);
    final filtered = _filtered(entries);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_heart, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Network Inspector',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              // Method filter
              _MethodFilter(
                selected: _filterMethod,
                onChanged: (v) => setState(() {
                  _filterMethod = v;
                  _selected = null;
                }),
              ),
              const SizedBox(width: 12),
              // Search
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filter URLs...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _selected = null;
                  }),
                ),
              ),
              const Spacer(),
              // Entry count
              Text('${filtered.length} requests',
                  style: theme.textTheme.labelSmall),
              const SizedBox(width: 8),
              // Clear button
              TextButton.icon(
                onPressed: entries.isEmpty
                    ? null
                    : () {
                        ref.read(networkLogProvider.notifier).clear();
                        setState(() => _selected = null);
                      },
                icon: const Icon(Icons.delete_sweep, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_tethering_off,
                          size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text('No network activity yet',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Requests will appear here as you use the app',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Entry list
                    SizedBox(
                      width: 420,
                      child: _EntryList(
                        entries: filtered,
                        selected: _selected,
                        onTap: (e) => setState(() => _selected = e),
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    // Detail panel
                    Expanded(
                      child: _selected != null
                          ? _DetailPanel(entry: _selected!)
                          : Center(
                              child: Text('Select a request to inspect',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: theme.hintColor)),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Method Filter Chips ───
class _MethodFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _MethodFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final methods = ['ALL', 'GET', 'POST'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: methods.map((m) {
        final isSelected = m == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilterChip(
            label: Text(m, style: const TextStyle(fontSize: 11)),
            selected: isSelected,
            onSelected: (_) => onChanged(m),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Entry List ───
class _EntryList extends StatelessWidget {
  final List<NetworkLogEntry> entries;
  final NetworkLogEntry? selected;
  final ValueChanged<NetworkLogEntry> onTap;

  const _EntryList({
    required this.entries,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selected?.id == entry.id;
        return InkWell(
          onTap: () => onTap(entry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MethodBadge(method: entry.method),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      statusCode: entry.statusCode,
                      isError: entry.error != null,
                      isStreaming: entry.isStreaming,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.duration.inMilliseconds}ms',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(entry.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _shortenUrl(entry.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
    } catch (_) {
      return url;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

// ─── Method Badge ───
class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = method == 'GET' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─── Status Badge ───
class _StatusBadge extends StatelessWidget {
  final int? statusCode;
  final bool isError;
  final bool isStreaming;
  const _StatusBadge({
    required this.statusCode,
    required this.isError,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    if (isError && statusCode == null) {
      color = Colors.red;
      text = 'ERR';
    } else if (isStreaming) {
      color = Colors.purple;
      text = statusCode != null ? '$statusCode ⟳' : 'STREAM';
    } else if (statusCode == null) {
      color = Colors.grey;
      text = '...';
    } else if (statusCode! >= 200 && statusCode! < 300) {
      color = Colors.green;
      text = '$statusCode';
    } else if (statusCode! >= 400) {
      color = Colors.red;
      text = '$statusCode';
    } else {
      color = Colors.orange;
      text = '$statusCode';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─── Detail Panel ───
class _DetailPanel extends StatelessWidget {
  final NetworkLogEntry entry;
  const _DetailPanel({required this.entry});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Request Headers'),
                Tab(text: 'Request Body'),
                Tab(text: 'Response Headers'),
                Tab(text: 'Response Body'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(entry: entry),
                _HeadersTab(headers: entry.requestHeaders),
                _BodyTab(body: entry.requestBody),
                _HeadersTab(headers: entry.responseHeaders),
                _BodyTab(body: entry.responseBody, error: entry.error),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ───
class _OverviewTab extends StatelessWidget {
  final NetworkLogEntry entry;
  const _OverviewTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_InfoRow>[
      _InfoRow('Method', entry.method),
      _InfoRow('URL', entry.url),
      _InfoRow('Status',
          entry.statusCode != null ? '${entry.statusCode}' : 'N/A'),
      _InfoRow('Duration', '${entry.duration.inMilliseconds}ms'),
      _InfoRow('Timestamp', entry.timestamp.toString()),
      if (entry.isStreaming)
        _InfoRow('Type', 'Streaming (SSE)'),
      if (entry.error != null)
        _InfoRow('Error', entry.error!, isError: true),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          r.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          r.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: r.isError ? Colors.red : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isError;
  const _InfoRow(this.label, this.value, {this.isError = false});
}

// ─── Headers Tab ───
class _HeadersTab extends StatelessWidget {
  final Map<String, String>? headers;
  const _HeadersTab({required this.headers});

  @override
  Widget build(BuildContext context) {
    if (headers == null || headers!.isEmpty) {
      return const Center(child: Text('No headers'));
    }
    final theme = Theme.of(context);
    final entries = headers!.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: SelectableText(
                  e.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Body Tab ───
class _BodyTab extends StatelessWidget {
  final String? body;
  final String? error;
  const _BodyTab({required this.body, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (error != null && body == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                _tryFormatJson(error!) ?? error!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (body == null || body!.isEmpty) {
      return const Center(child: Text('No body'));
    }

    // Streaming marker
    if (body == '[streaming response]') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stream, size: 48, color: theme.hintColor),
            const SizedBox(height: 8),
            Text('Streaming response',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 4),
            Text('Response body is delivered incrementally via SSE',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }

    final formatted = _tryFormatJson(body!);
    return Column(
      children: [
        // Copy button
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: formatted ?? body!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy', style: TextStyle(fontSize: 12)),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              formatted ?? body!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _tryFormatJson(String input) {
    try {
      final parsed = jsonDecode(input);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      return null;
    }
  }
}
