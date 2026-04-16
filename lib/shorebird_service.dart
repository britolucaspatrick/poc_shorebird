import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdService {
  static final ShorebirdService _instance = ShorebirdService._internal();
  factory ShorebirdService() => _instance;
  ShorebirdService._internal() {
    _loadLogs();
  }

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  final ValueNotifier<List<String>> logsNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isDownloadingNotifier = ValueNotifier<bool>(false);

  static const String _logKey = 'shorebird_logs_history';

  // Getters para os serviços da versão 2.0.5
  bool get isAvailable => _updater.isAvailable;

  Future<Patch?> getCurrentPatch() async {
    try {
      return await _updater.readCurrentPatch();
    } catch (_) {
      return null;
    }
  }

  Future<Patch?> getNextPatch() async {
    try {
      return await _updater.readNextPatch();
    } catch (_) {
      return null;
    }
  }

  // Lógica de Logs com Persistência
  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    logsNotifier.value = prefs.getStringList(_logKey) ?? [];
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first.split(' ').last;
    final formatted = '[$timestamp] $message';
    logsNotifier.value = [formatted, ...logsNotifier.value.take(99)];
    _saveLogs();
    debugPrint('[Shorebird] $message');
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_logKey, logsNotifier.value);
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
    logsNotifier.value = [];
  }

  // Processo de Atualização
  Future<void> checkForUpdates() async {
    if (!isAvailable) {
      addLog('❌ Shorebird não disponível neste build.');
      return;
    }

    addLog('🔍 Verificando atualizações...');
    try {
      final status = await _updater.checkForUpdate();
      addLog('Status: ${status.name}');

      if (status == UpdateStatus.outdated) {
        addLog('📥 Novo patch encontrado! Baixando...');
        isDownloadingNotifier.value = true;

        await _updater.update();

        final next = await getNextPatch();
        if (next != null) {
          addLog('✅ Patch Nº ${next.number} pronto! Reinicie o app.');
        } else {
          addLog('⚠️ Update concluído, mas patch não identificado.');
        }
      } else if (status == UpdateStatus.upToDate) {
        addLog('✨ O app já está atualizado.');
      }
    } on UpdateException catch (e) {
      addLog('❌ Erro: ${e.message} (${e.reason})');
    } catch (e) {
      addLog('❌ Erro inesperado: $e');
    } finally {
      isDownloadingNotifier.value = false;
    }
  }
}
