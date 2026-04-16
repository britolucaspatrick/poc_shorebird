import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'shorebird_service.dart';

class ShorebirdControlPage extends StatefulWidget {
  const ShorebirdControlPage({super.key});

  @override
  State<ShorebirdControlPage> createState() => _ShorebirdControlPageState();
}

class _ShorebirdControlPageState extends State<ShorebirdControlPage> {
  final ShorebirdService _service = ShorebirdService();

  Future<void> _runUpdateProcess() async {
    await _service.checkForUpdates();

    // Proteção contra Async Gaps (Linter warning fix)
    if (!mounted) return;

    // Se um patch foi baixado, avisa o usuário
    final next = await _service.getNextPatch();
    if (next != null && mounted) {
      _showRestartDialog();
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Patch Baixado'),
        content: const Text('Para aplicar as mudanças, feche o aplicativo completamente e abra-o novamente.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDI'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorebird Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar Logs',
            onPressed: () => _service.clearLogs(),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _service.isDownloadingNotifier,
            builder: (_, isDownloading, __) {
              return IconButton(icon: const Icon(Icons.refresh), onPressed: isDownloading ? null : _runUpdateProcess);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _service.isDownloadingNotifier,
            builder: (_, isDownloading, __) {
              return isDownloading ? const LinearProgressIndicator() : const SizedBox.shrink();
            },
          ),
          _buildStatusPanel(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('HISTÓRICO (PERSISTENTE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _service.logsNotifier,
              builder: (_, logs, __) {
                if (logs.isEmpty) return const Center(child: Text('Nenhum log disponível.'));
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(logs[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          _statusRow('Disponível:', _service.isAvailable ? 'SIM ✅' : 'NÃO ❌'),
          const SizedBox(height: 10),
          FutureBuilder<Patch?>(
            future: _service.getCurrentPatch(),
            builder: (context, snapshot) =>
                _statusRow('Patch Atual:', snapshot.data != null ? 'Nº ${snapshot.data!.number}' : 'Nenhum'),
          ),
          const SizedBox(height: 10),
          FutureBuilder<Patch?>(
            future: _service.getNextPatch(),
            builder: (context, snapshot) => _statusRow(
              'Próximo Patch:',
              snapshot.data != null ? 'Nº ${snapshot.data!.number} ⏳' : 'Nenhum',
              highlight: snapshot.data != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: highlight ? Colors.orange.shade100 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
