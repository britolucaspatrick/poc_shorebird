import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:poc_shorebird/shorebird_control_page.dart';
import 'shorebird_service.dart'; // Importe seu novo serviço

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _versionDisplay = 'Carregando...';
  final _shorebird = ShorebirdService();

  @override
  void initState() {
    super.initState();
    _initVersion();
  }

  Future<void> _initVersion() async {
    final info = await PackageInfo.fromPlatform();
    final patch = await _shorebird.getCurrentPatch();
    setState(() {
      _versionDisplay = '${info.version}+${info.buildNumber} (Patch: ${patch?.number ?? "Nenhum"})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Versão Atual:', style: Theme.of(context).textTheme.labelLarge),
            Text(_versionDisplay, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShorebirdControlPage())),
              icon: const Icon(Icons.settings_system_daydream),
              label: const Text('Controle de Versão Shorebird'),
            ),
          ],
        ),
      ),
    );
  }
}
