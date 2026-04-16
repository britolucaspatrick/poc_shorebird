import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  runApp(const MyApp());
}

final shorebirdUpdater = ShorebirdUpdater();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _appVersion = 'Carregando...';
  bool _isDownloading = false;
  final List<String> _logs = []; // Lista para exibir logs na UI

  @override
  void initState() {
    super.initState();
    _addLog('Iniciando monitoramento Shorebird...');
    _loadPackageInfo();
    _checkForUpdates();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first.split(' ').last;
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint('[ShorebirdLog] $message');
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentPatch = await shorebirdUpdater.readCurrentPatch();

      setState(() {
        _appVersion = '${info.version}+${info.buildNumber} (Patch: ${currentPatch?.number ?? "Nenhum"})';
      });
      _addLog('Versão carregada: $_appVersion');
    } catch (e) {
      _addLog('Erro ao carregar infos: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    _addLog('Verificando atualizações...');

    try {
      // 1. Usa o checkForUpdate que aparece no seu print
      final status = await shorebirdUpdater.checkForUpdate();
      _addLog('Status: ${status.name}');

      if (status == UpdateStatus.outdated) {
        _addLog('Novo patch encontrado! Baixando...');

        setState(() => _isDownloading = true);

        // 2. Usa o update() para baixar
        await shorebirdUpdater.update();

        // 3. Em vez de isNewPatchReadyToInstall, verificamos o readNextPatch()
        // Se readNextPatch não for nulo, significa que há um patch baixado
        // esperando o próximo reinício.
        final nextPatch = await shorebirdUpdater.readNextPatch();

        if (nextPatch != null) {
          _addLog('✅ Patch ${nextPatch.number} baixado e pronto para o próximo boot.');
        } else {
          _addLog('⚠️ Download concluído, mas o próximo patch ainda não foi identificado.');
        }
      } else if (status == UpdateStatus.upToDate) {
        _addLog('O app já está atualizado.');
      }
    } on UpdateException catch (e) {
      _addLog('❌ Erro Shorebird: ${e.message}');
    } catch (e) {
      _addLog('❌ Erro: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorebird Logs'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _isDownloading ? null : _checkForUpdates)],
      ),
      body: Column(
        children: [
          // Header de status
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão: $_appVersion', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_isDownloading) const LinearProgressIndicator(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('LOGS DO PROCESSO:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          // Lista de Logs
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    _logs[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: _logs[index].contains('❌') ? Colors.red : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
