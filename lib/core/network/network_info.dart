import 'connectivity_checker.dart';

/// Abstract class for network information
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Future<bool> get hasInternetAccess;
  Future<String> get connectionType;
  Stream<bool> get connectivityStream;
}

/// Implementation of NetworkInfo using ConnectivityChecker
class NetworkInfoImpl implements NetworkInfo {
  final ConnectivityChecker _connectivityChecker;
  
  NetworkInfoImpl(this._connectivityChecker);
  
  @override
  Future<bool> get isConnected => _connectivityChecker.hasConnection;
  
  @override
  Future<bool> get hasInternetAccess => 
      _connectivityChecker.hasInternetConnection();
  
  @override
  Future<String> get connectionType => 
      _connectivityChecker.getConnectivityType();
  
  @override
  Stream<bool> get connectivityStream => 
      _connectivityChecker.connectivityStream;
}
