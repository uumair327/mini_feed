import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/network/network_info.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/logger.dart';

/// States for connectivity
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

/// Initial connectivity state
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// Connected state
class ConnectivityConnected extends ConnectivityState {
  final String connectionType;

  const ConnectivityConnected({
    required this.connectionType,
  });

  @override
  List<Object?> get props => [connectionType];
}

/// Disconnected state
class ConnectivityDisconnected extends ConnectivityState {
  const ConnectivityDisconnected();
}

/// Cubit for managing connectivity state
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final NetworkInfo _networkInfo;
  final SyncService? _syncService;
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityCubit({
    required NetworkInfo networkInfo,
    SyncService? syncService,
  })  : _networkInfo = networkInfo,
        _syncService = syncService,
        super(const ConnectivityInitial());

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await _checkConnectivity();
      
      // Start listening to connectivity changes
      _connectivitySubscription = _networkInfo.connectivityStream.listen(
        (isConnected) async {
          if (isConnected) {
            final connectionType = await _networkInfo.connectionType;
            emit(ConnectivityConnected(connectionType: connectionType));
            Logger.info('Connected to $connectionType');
            
            // Trigger sync when connectivity is restored
            if (_syncService != null) {
              Logger.info('Connectivity restored, triggering sync...');
              _syncService!.syncPendingChanges();
            }
          } else {
            emit(const ConnectivityDisconnected());
            Logger.info('Disconnected from network');
          }
        },
        onError: (error) {
          Logger.error('Connectivity stream error', error);
          emit(const ConnectivityDisconnected());
        },
      );
    } catch (e) {
      Logger.error('Error initializing connectivity', e);
      emit(const ConnectivityDisconnected());
    }
  }

  /// Check current connectivity status
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  /// Internal method to check connectivity
  Future<void> _checkConnectivity() async {
    try {
      final isConnected = await _networkInfo.isConnected;
      
      if (isConnected) {
        // Double-check with internet access
        final hasInternet = await _networkInfo.hasInternetAccess;
        
        if (hasInternet) {
          final connectionType = await _networkInfo.connectionType;
          emit(ConnectivityConnected(connectionType: connectionType));
        } else {
          emit(const ConnectivityDisconnected());
        }
      } else {
        emit(const ConnectivityDisconnected());
      }
    } catch (e) {
      Logger.error('Error checking connectivity', e);
      emit(const ConnectivityDisconnected());
    }
  }

  /// Get current connectivity status as boolean
  bool get isConnected => state is ConnectivityConnected;

  /// Get current connection type
  String get connectionType {
    final currentState = state;
    if (currentState is ConnectivityConnected) {
      return currentState.connectionType;
    }
    return 'None';
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}