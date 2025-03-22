import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../services/sync_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SyncService _syncService = SyncService();
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _syncService.getBackupFiles();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to load backup files: $e';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final filePath = await _syncService.exportData();
      await _loadBackupFiles();
      setState(() {
        _message = 'Backup created successfully: ${path.basename(filePath)}';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to create backup: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
            'This will replace all current data. Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _syncService.importData(filePath);

      // Reload providers
      await Provider.of<CategoryProvider>(context, listen: false).init();
      await Provider.of<TransactionProvider>(context, listen: false).init();

      setState(() {
        _message = 'Data restored successfully';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to restore backup: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String fileName) {
    try {
      final regex = RegExp(r'myfinance_backup_(\d+)\.json');
      final match = regex.firstMatch(fileName);
      if (match != null) {
        final timestamp = int.parse(match.group(1)!);
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
      }
    } catch (_) {}
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isError ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isError ? Colors.red[900] : Colors.green[900],
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Backup'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Available Backups',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _backupFiles.isEmpty
                        ? const Center(
                            child: Text('No backup files found'),
                          )
                        : ListView.builder(
                            itemCount: _backupFiles.length,
                            itemBuilder: (context, index) {
                              final file = _backupFiles[index];
                              final fileName = path.basename(file.path);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(_formatDate(fileName)),
                                  subtitle: Text(fileName),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.restore),
                                    onPressed: () => _restoreBackup(file.path),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
