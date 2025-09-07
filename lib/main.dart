import 'package:flutter/material.dart';
import 'package:mini_feed/core/storage/storage_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageInitializer.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mini Feed',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ArchitectureDemoPage(),
      );
}

class ArchitectureDemoPage extends StatelessWidget {
  const ArchitectureDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Feed - Clean Architecture Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArchitectureOverview(),
            SizedBox(height: 24),
            _LayerDetails(),
            SizedBox(height: 24),
            _ImplementationStatus(),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureOverview extends StatelessWidget {
  const _ArchitectureOverview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clean Architecture Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'This app demonstrates Clean Architecture with 4 distinct layers:\n'
              '• Presentation Layer (UI, BLoC/Cubit)\n'
              '• Domain Layer (Entities, Use Cases, Repository Interfaces)\n'
              '• Data Layer (Models, Data Sources, Repository Implementations)\n'
              '• Core Layer (Network, Storage, Utilities)',
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerDetails extends StatelessWidget {
  const _LayerDetails();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Architecture Layers',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const _LayerCard(
          title: '🎨 Presentation Layer',
          description: 'UI components and state management',
          status: 'Minimal Implementation',
          items: [
            'Basic Flutter widgets',
            'Material Design theme',
            'Architecture demo screen',
          ],
        ),
        const _LayerCard(
          title: '🏛️ Domain Layer',
          description: 'Business logic and entities',
          status: 'Fully Implemented',
          items: [
            'User, Post, Comment entities',
            'Authentication use cases',
            'Post management use cases',
            'Repository interfaces',
          ],
        ),
        const _LayerCard(
          title: '📊 Data Layer',
          description: 'Data sources and models',
          status: 'Fully Implemented',
          items: [
            'API models with JSON serialization',
            'Hive models for local storage',
            'Remote data sources (reqres.in, JSONPlaceholder)',
            'Local data sources with caching',
            'Repository implementations',
          ],
        ),
        const _LayerCard(
          title: '⚙️ Core Layer',
          description: 'Shared utilities and infrastructure',
          status: 'Fully Implemented',
          items: [
            'Network client with Dio',
            'Storage services (Hive, SharedPreferences)',
            'Error handling with Result<T> pattern',
            'Logging and validation utilities',
          ],
        ),
      ],
    );
  }
}

class _LayerCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final List<String> items;

  const _LayerCard({
    required this.title,
    required this.description,
    required this.status,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(status),
                  backgroundColor: status.contains('Fully') 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ImplementationStatus extends StatelessWidget {
  const _ImplementationStatus();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Implementation Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              '✅ Complete Foundation: Domain, Data, and Core layers\n'
              '✅ 300+ Unit Tests with comprehensive coverage\n'
              '✅ API Integration: reqres.in (auth) + JSONPlaceholder (posts)\n'
              '✅ Local Storage: Hive + SharedPreferences with caching\n'
              '✅ Error Handling: Result<T> pattern with custom failures\n'
              '✅ Network Layer: Dio client with interceptors\n\n'
              '⏳ Pending: Full UI implementation with BLoC state management\n'
              '⏳ Pending: Navigation and routing\n'
              '⏳ Pending: Integration tests',
            ),
          ],
        ),
      ),
    );
  }
}
