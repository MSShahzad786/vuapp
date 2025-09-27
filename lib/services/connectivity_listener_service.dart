import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vu_mcqs_app/services/sync_service.dart';
import 'package:vu_mcqs_app/services/connectivity_service.dart';

class ConnectivityListenerService {
  static final ConnectivityListenerService _instance = ConnectivityListenerService._internal();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isListening = false;

  factory ConnectivityListenerService() => _instance;

  ConnectivityListenerService._internal();

  /// Start listening to connectivity changes
  void startListening() {
    if (_isListening) return;

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        // Silently handle errors
      },
    );

    _isListening = true;
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isListening = false;
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    try {
      // Check if any of the results indicate online connectivity
      final hasConnection = results.any((result) => result != ConnectivityResult.none);

      if (hasConnection) {
        // User came back online - process pending syncs
        // await _syncService.processPendingSyncs(); // Method removed
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;
}