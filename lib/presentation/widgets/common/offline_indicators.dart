import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/connectivity/connectivity_cubit.dart';

/// Banner that shows when the app is offline
class OfflineBanner extends StatelessWidget {
  final Widget child;
  final bool showWhenConnected;

  const OfflineBanner({
    super.key,
    required this.child,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final isOffline = state is ConnectivityDisconnected;
        final isConnected = state is ConnectivityConnected;
        
        return Column(
          children: [
            // Show offline banner when disconnected
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.error,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Theme.of(context).colorScheme.onError,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are offline. Some features may not be available.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Show connection restored banner briefly when reconnected
            if (showWhenConnected && isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.primary,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connection restored',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// Small connectivity indicator that can be placed in app bars
class ConnectivityIndicator extends StatelessWidget {
  final bool showWhenConnected;

  const ConnectivityIndicator({
    super.key,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityDisconnected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 12,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 4),
                Text(
                  'Offline',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        } else if (showWhenConnected && state is ConnectivityConnected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getConnectionIcon(state.connectionType),
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  state.connectionType,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  IconData _getConnectionIcon(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'mobile':
        return Icons.signal_cellular_4_bar;
      case 'ethernet':
        return Icons.network_check;
      default:
        return Icons.network_check;
    }
  }
}

/// Snackbar that shows connectivity changes
class ConnectivitySnackBar {
  static void show(BuildContext context, ConnectivityState state) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    messenger.clearSnackBars();
    
    if (state is ConnectivityDisconnected) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('You are now offline'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (state is ConnectivityConnected) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getConnectionIcon(state.connectionType),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Connected via ${state.connectionType}'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static IconData _getConnectionIcon(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'mobile':
        return Icons.signal_cellular_4_bar;
      case 'ethernet':
        return Icons.network_check;
      default:
        return Icons.network_check;
    }
  }
}

/// Widget that shows different content based on connectivity
class ConnectivityBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isConnected, String connectionType) builder;

  const ConnectivityBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final isConnected = state is ConnectivityConnected;
        final connectionType = state is ConnectivityConnected 
            ? state.connectionType 
            : 'None';
        
        return builder(context, isConnected, connectionType);
      },
    );
  }
}