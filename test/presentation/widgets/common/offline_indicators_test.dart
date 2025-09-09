import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:mini_feed/presentation/widgets/common/offline_indicators.dart';

class MockConnectivityCubit extends Mock implements ConnectivityCubit {}

void main() {
  group('OfflineBanner', () {
    late MockConnectivityCubit mockConnectivityCubit;

    setUp(() {
      mockConnectivityCubit = MockConnectivityCubit();
    });

    Widget createWidgetUnderTest({
      required ConnectivityState state,
      bool showWhenConnected = false,
    }) {
      when(() => mockConnectivityCubit.state).thenReturn(state);
      when(() => mockConnectivityCubit.stream).thenAnswer(
        (_) => Stream.value(state),
      );

      return MaterialApp(
        home: BlocProvider<ConnectivityCubit>.value(
          value: mockConnectivityCubit,
          child: OfflineBanner(
            showWhenConnected: showWhenConnected,
            child: const Scaffold(
              body: Center(child: Text('Test Content')),
            ),
          ),
        ),
      );
    }

    testWidgets('should show offline banner when disconnected', (tester) async {
      // Arrange
      const state = ConnectivityDisconnected();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(
        find.text('You are offline. Some features may not be available.'),
        findsOneWidget,
      );
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should not show banner when connected by default', (tester) async {
      // Arrange
      const state = ConnectivityConnected(connectionType: 'WiFi');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(
        find.text('You are offline. Some features may not be available.'),
        findsNothing,
      );
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should show connection restored banner when showWhenConnected is true', (tester) async {
      // Arrange
      const state = ConnectivityConnected(connectionType: 'WiFi');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        state: state,
        showWhenConnected: true,
      ));

      // Assert
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.text('Connection restored'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should not show any banner for initial state', (tester) async {
      // Arrange
      const state = ConnectivityInitial();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(find.byIcon(Icons.wifi), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('ConnectivityIndicator', () {
    late MockConnectivityCubit mockConnectivityCubit;

    setUp(() {
      mockConnectivityCubit = MockConnectivityCubit();
    });

    Widget createWidgetUnderTest({
      required ConnectivityState state,
      bool showWhenConnected = false,
    }) {
      when(() => mockConnectivityCubit.state).thenReturn(state);
      when(() => mockConnectivityCubit.stream).thenAnswer(
        (_) => Stream.value(state),
      );

      return MaterialApp(
        home: BlocProvider<ConnectivityCubit>.value(
          value: mockConnectivityCubit,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ConnectivityIndicator(showWhenConnected: showWhenConnected),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('should show offline indicator when disconnected', (tester) async {
      // Arrange
      const state = ConnectivityDisconnected();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('should not show indicator when connected by default', (tester) async {
      // Arrange
      const state = ConnectivityConnected(connectionType: 'WiFi');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byIcon(Icons.wifi), findsNothing);
      expect(find.text('WiFi'), findsNothing);
    });

    testWidgets('should show connection type when connected and showWhenConnected is true', (tester) async {
      // Arrange
      const state = ConnectivityConnected(connectionType: 'Mobile');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        state: state,
        showWhenConnected: true,
      ));

      // Assert
      expect(find.byIcon(Icons.signal_cellular_4_bar), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('should show WiFi icon for WiFi connection', (tester) async {
      // Test WiFi
      await tester.pumpWidget(createWidgetUnderTest(
        state: const ConnectivityConnected(connectionType: 'WiFi'),
        showWhenConnected: true,
      ));
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('should show mobile icon for mobile connection', (tester) async {
      // Test Mobile
      await tester.pumpWidget(createWidgetUnderTest(
        state: const ConnectivityConnected(connectionType: 'Mobile'),
        showWhenConnected: true,
      ));
      expect(find.byIcon(Icons.signal_cellular_4_bar), findsOneWidget);
    });

    testWidgets('should show network icon for ethernet connection', (tester) async {
      // Test Ethernet
      await tester.pumpWidget(createWidgetUnderTest(
        state: const ConnectivityConnected(connectionType: 'Ethernet'),
        showWhenConnected: true,
      ));
      expect(find.byIcon(Icons.network_check), findsOneWidget);
    });

    testWidgets('should show network icon for unknown connection', (tester) async {
      // Test Unknown
      await tester.pumpWidget(createWidgetUnderTest(
        state: const ConnectivityConnected(connectionType: 'Unknown'),
        showWhenConnected: true,
      ));
      expect(find.byIcon(Icons.network_check), findsOneWidget);
    });

    testWidgets('should not show anything for initial state', (tester) async {
      // Arrange
      const state = ConnectivityInitial();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.byType(ConnectivityIndicator), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(find.byIcon(Icons.wifi), findsNothing);
    });
  });

  group('ConnectivityBuilder', () {
    late MockConnectivityCubit mockConnectivityCubit;

    setUp(() {
      mockConnectivityCubit = MockConnectivityCubit();
    });

    Widget createWidgetUnderTest({
      required ConnectivityState state,
    }) {
      when(() => mockConnectivityCubit.state).thenReturn(state);
      when(() => mockConnectivityCubit.stream).thenAnswer(
        (_) => Stream.value(state),
      );

      return MaterialApp(
        home: BlocProvider<ConnectivityCubit>.value(
          value: mockConnectivityCubit,
          child: Scaffold(
            body: ConnectivityBuilder(
              builder: (context, isConnected, connectionType) {
                return Column(
                  children: [
                    Text('Connected: $isConnected'),
                    Text('Type: $connectionType'),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('should provide correct values when connected', (tester) async {
      // Arrange
      const state = ConnectivityConnected(connectionType: 'WiFi');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.text('Connected: true'), findsOneWidget);
      expect(find.text('Type: WiFi'), findsOneWidget);
    });

    testWidgets('should provide correct values when disconnected', (tester) async {
      // Arrange
      const state = ConnectivityDisconnected();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.text('Connected: false'), findsOneWidget);
      expect(find.text('Type: None'), findsOneWidget);
    });

    testWidgets('should provide correct values for initial state', (tester) async {
      // Arrange
      const state = ConnectivityInitial();

      // Act
      await tester.pumpWidget(createWidgetUnderTest(state: state));

      // Assert
      expect(find.text('Connected: false'), findsOneWidget);
      expect(find.text('Type: None'), findsOneWidget);
    });
  });
}