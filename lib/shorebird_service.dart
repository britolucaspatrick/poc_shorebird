import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShorebirdService {
  static final ShorebirdService _instance = ShorebirdService._internal();
  factory ShorebirdService() => _instance;
  ShorebirdService._internal() {
    // Carrega logs salvos ao iniciar
    _loadLogsFromStorage();
  }

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  final ValueNotifier<List<String>> logsNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isDownloadingNotifier = ValueNotifier<bool>(false);

  // Adicione estes métodos à sua classe ShorebirdService
  bool get isAvailable => _updater.isAvailable;

  Future<Patch?> getNextPatch() async {
    return await _updater.readNextPatch();
  }

  static const String _storageKey = 'shorebird_logs_history';

  // Carrega os logs do SharedPreferences
  Future<void> _loadLogsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogs = prefs.getStringList(_storageKey);
    if (savedLogs != null) {
      logsNotifier.value = savedLogs;
    }
  }

  // Salva os logs no SharedPreferences
  Future<void> _saveLogsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Limitamos a 100 logs para não inflar o armazenamento desnecessariamente
    final logsToSave = logsNotifier.value.take(100).toList();
    await prefs.setStringList(_storageKey, logsToSave);
  }

  // Limpa o histórico se necessário
  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    logsNotifier.value = [];
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first.split(' ').last;
    final newLog = '[$timestamp] $message';

    logsNotifier.value = [newLog, ...logsNotifier.value];
    debugPrint('[ShorebirdLog] $message');

    // Persiste a mudança
    _saveLogsToStorage();
  }

  Future<Patch?> getCurrentPatch() async {
    return await _updater.readCurrentPatch();
  }

  Future<void> checkForUpdates() async {
    addLog('Verificando atualizações...');

    try {
      final status = await _updater.checkForUpdate();
      addLog('Status: ${status.name}');

      if (status == UpdateStatus.outdated) {
        addLog('Novo patch encontrado! Baixando...');
        isDownloadingNotifier.value = true;

        await _updater.update();

        final nextPatch = await _updater.readNextPatch();
        if (nextPatch != null) {
          addLog('✅ Patch ${nextPatch.number} baixado.');
          addLog('🚀 PRONTO: Feche e abra o app para aplicar.');
        } else {
          addLog('⚠️ Download concluído.');
        }
      } else if (status == UpdateStatus.upToDate) {
        addLog('O app já está atualizado.');
      }
    } on UpdateException catch (e) {
      addLog('❌ Erro Shorebird: ${e.message}');
    } catch (e) {
      addLog('❌ Erro: $e');
    } finally {
      isDownloadingNotifier.value = false;
    }
  }
}
