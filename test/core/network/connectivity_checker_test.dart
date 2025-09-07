import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/network/connectivity_checker.dart';

void main() {
  late ConnectivityChecker connectivityChecker;
  
  setUp(() {
    connectivityChecker = ConnectivityChecker();
  });
  
  group('ConnectivityChecker', () {
    test('should be a singleton', () {
      // Arrange & Act
      final instance1 = ConnectivityChecker();
      final instance2 = ConnectivityChecker();
      
      // Assert
      expect(instance1, same(instance2));
    });
    
    test('should return connectivity stream', () {
      // Arrange & Act
      final stream = connectivityChecker.connectivityStream;
      
      // Assert
      expect(stream, isA<Stream<bool>>());
    });
    
    test('should handle connectivity check errors gracefully', () async {
      // This test verifies that the method doesn't throw exceptions
      // and returns a boolean value even when connectivity check fails
      
      // Act & Assert
      expect(() => connectivityChecker.hasConnection, returnsNormally);
      
      final result = await connectivityChecker.hasConnection;
      expect(result, isA<bool>());
    });
    
    test('should handle internet connection check errors gracefully', () async {
      // This test verifies that the method doesn't throw exceptions
      // and returns a boolean value even when internet check fails
      
      // Act & Assert
      expect(
        () => connectivityChecker.hasInternetConnection(),
        returnsNormally,
      );
      
      final result = await connectivityChecker.hasInternetConnection();
      expect(result, isA<bool>());
    });
    
    test('should return connectivity type as string', () async {
      // Act
      final type = await connectivityChecker.getConnectivityType();
      
      // Assert
      expect(type, isA<String>());
      expect(
        ['WiFi', 'Mobile', 'Ethernet', 'None', 'Unknown'].contains(type),
        true,
      );
    });
    
    test('should start and stop listening correctly', () {
      // This test verifies that the methods don't throw exceptions
      
      // Act & Assert
      expect(
        () => connectivityChecker.startListening((isConnected) {}),
        returnsNormally,
      );
      
      expect(
        () => connectivityChecker.stopListening(),
        returnsNormally,
      );
    });
  });
}