import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:poc_shorebird/shorebird_service.dart';

class ShorebirdControlPage extends StatelessWidget {
  const ShorebirdControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ShorebirdService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorebird Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar Logs',
            onPressed: () => service.clearLogs(),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: service.isDownloadingNotifier,
            builder: (_, isDownloading, __) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isDownloading ? null : () => service.checkForUpdates(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progresso de download
          ValueListenableBuilder<bool>(
            valueListenable: service.isDownloadingNotifier,
            builder: (_, isDownloading, __) {
              return isDownloading ? const LinearProgressIndicator() : const SizedBox.shrink();
            },
          ),

          // Painel de Status Detalhado
          _buildStatusPanel(service),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('HISTÓRICO DE EVENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          // Lista de Logs
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: service.logsNotifier,
              builder: (_, logs, __) {
                if (logs.isEmpty) {
                  return const Center(child: Text('Nenhum log registrado.'));
                }
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

  Widget _buildStatusPanel(ShorebirdService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withOpacity(0.05),
      child: Column(
        children: [
          // Serviço: isAvailable
          _statusRow(
            'Disponível:',
            service.isAvailable ? 'Sim ✅' : 'Não ❌',
            subtitle: 'Indica se o app foi gerado via Shorebird',
          ),
          const SizedBox(height: 12),

          // Serviço: readCurrentPatch()
          FutureBuilder<Patch?>(
            future: service.getCurrentPatch(),
            builder: (context, snapshot) {
              final patch = snapshot.data;
              return _statusRow(
                'Patch Ativo:',
                patch != null ? 'Nº ${patch.number}' : 'Nenhum',
                subtitle: 'Versão de patch rodando agora',
              );
            },
          ),
          const SizedBox(height: 12),

          // Serviço: readNextPatch()
          FutureBuilder<Patch?>(
            future: service.getNextPatch(),
            builder: (context, snapshot) {
              final patch = snapshot.data;
              return _statusRow(
                'Próximo Patch:',
                patch != null ? 'Nº ${patch.number} ⏳' : 'Nenhum',
                subtitle: 'Aguardando reinicialização para aplicar',
                highlight: patch != null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, {String? subtitle, bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: highlight ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
