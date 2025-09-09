import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/core/network/network_info.dart';
import 'package:mini_feed/presentation/blocs/connectivity/connectivity_cubit.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  group('ConnectivityCubit', () {
    late ConnectivityCubit connectivityCubit;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      connectivityCubit = ConnectivityCubit(networkInfo: mockNetworkInfo);
    });

    tearDown(() {
      connectivityCubit.close();
    });

    test('initial state is ConnectivityInitial', () {
      expect(connectivityCubit.state, const ConnectivityInitial());
    });

    group('initialize', () {
      test('should emit ConnectivityConnected when connected with internet', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'WiFi');
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.empty(),
        );

        // Act
        await connectivityCubit.initialize();

        // Assert
        expect(
          connectivityCubit.state,
          const ConnectivityConnected(connectionType: 'WiFi'),
        );
      });

      test('should emit ConnectivityDisconnected when not connected', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.empty(),
        );

        // Act
        await connectivityCubit.initialize();

        // Assert
        expect(connectivityCubit.state, const ConnectivityDisconnected());
      });

      test('should emit ConnectivityDisconnected when connected but no internet', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => false);
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.empty(),
        );

        // Act
        await connectivityCubit.initialize();

        // Assert
        expect(connectivityCubit.state, const ConnectivityDisconnected());
      });

      test('should handle connectivity stream changes', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'Mobile');
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.fromIterable([true, false]),
        );

        // Act
        await connectivityCubit.initialize();
        
        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - should end in disconnected state
        expect(connectivityCubit.state, const ConnectivityDisconnected());
      });
    });

    group('checkConnectivity', () {
      test('should update state when checking connectivity manually', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'Ethernet');

        // Act
        await connectivityCubit.checkConnectivity();

        // Assert
        expect(
          connectivityCubit.state,
          const ConnectivityConnected(connectionType: 'Ethernet'),
        );
      });
    });

    group('getters', () {
      test('isConnected should return true when connected', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'WiFi');

        // Act
        await connectivityCubit.checkConnectivity();

        // Assert
        expect(connectivityCubit.isConnected, true);
      });

      test('isConnected should return false when disconnected', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        await connectivityCubit.checkConnectivity();

        // Assert
        expect(connectivityCubit.isConnected, false);
      });

      test('connectionType should return correct type when connected', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'Mobile');

        // Act
        await connectivityCubit.checkConnectivity();

        // Assert
        expect(connectivityCubit.connectionType, 'Mobile');
      });

      test('connectionType should return None when disconnected', () {
        // Assert
        expect(connectivityCubit.connectionType, 'None');
      });
    });

    group('error handling', () {
      test('should emit ConnectivityDisconnected when network check throws', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenThrow(Exception('Network error'));
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.value(false),
        );

        // Act
        await connectivityCubit.initialize();

        // Assert
        expect(connectivityCubit.state, const ConnectivityDisconnected());
      });

      test('should handle stream errors gracefully', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.hasInternetAccess).thenAnswer((_) async => true);
        when(() => mockNetworkInfo.connectionType).thenAnswer((_) async => 'WiFi');
        when(() => mockNetworkInfo.connectivityStream).thenAnswer(
          (_) => Stream.error(Exception('Stream error')),
        );

        // Act
        await connectivityCubit.initialize();
        
        // Wait for error handling
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - should handle error and emit disconnected state
        expect(connectivityCubit.state, const ConnectivityDisconnected());
      });
    });
  });
}