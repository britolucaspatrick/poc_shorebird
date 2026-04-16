import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
// O import permanece o mesmo, mas a classe interna mudou
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  runApp(const MyApp());
}

// 1. Mudança de ShorebirdCodePush para ShorebirdUpdater
final shorebirdUpdater = ShorebirdUpdater();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const MyHomePage());
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
  bool _patchAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _checkForUpdates();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    // 2. Para pegar o patch atual na versão nova:
    final currentPatch = await shorebirdUpdater.readCurrentPatch();

    setState(() {
      _appVersion = '${info.version}+${info.buildNumber} (Patch: ${currentPatch?.number ?? "Nenhum"})';
    });
  }

  Future<void> _checkForUpdates() async {
    // 3. O método isNewPatchAvailableForDownload foi substituído/refatorado.
    // O fluxo recomendado agora é usar o checkForUpdate()

    try {
      final status = await shorebirdUpdater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        setState(() {
          _isDownloading = true;
          _patchAvailable = true;
        });

        // 4. Inicia o download
        await shorebirdUpdater.update();

        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar: $e');
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorebird 2.0.5'),
        actions: [
          if (_isDownloading)
            const Center(
              child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_patchAvailable) Text(_isDownloading ? 'Baixando patch...' : 'Patch pronto! Reinicie o app.'),
            const SizedBox(height: 20),
            Text('Versão: $_appVersion'),
          ],
        ),
      ),
    );
  }
}
