import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/logger.dart';

/// Utility class for checking network connectivity
class ConnectivityChecker {
  static final ConnectivityChecker _instance = ConnectivityChecker._internal();
  factory ConnectivityChecker() => _instance;
  ConnectivityChecker._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((results) => _hasConnection(results));
  
  /// Check if device has internet connection
  Future<bool> get hasConnection async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (e) {
      Logger.error('Error checking connectivity', e);
      return false;
    }
  }
  
  /// Check if device has active internet connection by pinging a server
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      Logger.debug('No internet connection available');
      return false;
    } catch (e) {
      Logger.error('Error checking internet connection', e);
      return false;
    }
  }
  
  /// Start listening to connectivity changes
  void startListening(void Function(bool isConnected) onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) => onConnectivityChanged(_hasConnection(results)),
      onError: (error) {
        Logger.error('Connectivity stream error', error);
      },
    );
  }
  
  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Helper method to determine if connection exists
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }
  
  /// Get current connectivity type as string
  Future<String> getConnectivityType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        return 'Mobile';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'None';
      }
    } catch (e) {
      Logger.error('Error getting connectivity type', e);
      return 'Unknown';
    }
  }
}
