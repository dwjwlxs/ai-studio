import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

class ServerConfigPage extends ConsumerStatefulWidget {
  const ServerConfigPage({super.key});

  @override
  ConsumerState<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends ConsumerState<ServerConfigPage> {
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  bool _isTesting = false;
  bool? _testResult;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final service = ref.read(healthServiceProvider);
    final connected = await service.checkConnection();

    setState(() {
      _isTesting = false;
      _testResult = connected;
    });

    ref.read(connectionStatusProvider.notifier).state = connected;
  }

  Future<void> _saveConfig() async {
    await ref.read(serverConfigProvider.notifier).updateConfig(
          _urlController.text.trim(),
          _apiKeyController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for config data arriving from async load
    ref.listen(serverConfigProvider, (prev, next) {
      next.whenData((config) {
        if (!_configLoaded) {
          _configLoaded = true;
          _urlController.text = config.gatewayUrl;
          _apiKeyController.text = config.apiKey;
        }
      });
    });

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Server Configuration',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Configure your Bifrost gateway connection to start testing APIs.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Gateway URL',
                  hintText: 'http://localhost:8080',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional)',
                  hintText: 'Leave empty if not required',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Configuration'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _testResult == true
                                ? Icons.check_circle
                                : _testResult == false
                                    ? Icons.cancel
                                    : Icons.network_check,
                            color: _testResult == true
                                ? Colors.green
                                : _testResult == false
                                    ? Colors.red
                                    : null,
                          ),
                    label: Text(
                      _isTesting
                          ? 'Testing...'
                          : _testResult == true
                              ? 'Connected!'
                              : _testResult == false
                                  ? 'Connection Failed'
                                  : 'Test Connection',
                    ),
                  ),
                ],
              ),
              if (_testResult == false) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not connect to the gateway. Make sure Bifrost is running and the URL is correct.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Start',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '1. Start your Bifrost gateway (default: http://localhost:8080)\n'
                        '2. Enter the gateway URL above\n'
                        '3. Click "Test Connection" to verify\n'
                        '4. Navigate to Chat, Image, or Video tabs to test APIs',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
