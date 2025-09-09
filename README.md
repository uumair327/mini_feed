# Mini Feed App

A modern Flutter application that provides a social media feed experience with offline capabilities, optimistic updates, and responsive design.

## Features

### Core Functionality
- **User Authentication**: Secure login with token-based authentication
- **Social Feed**: Browse and interact with posts from multiple users
- **Post Creation**: Create new posts with optimistic updates
- **Post Details**: View detailed post information with comments
- **Search**: Real-time search through posts with highlighting
- **Favorites**: Mark posts as favorites with local persistence

### Advanced Features
- **Offline Support**: Full offline functionality with data caching
- **Optimistic Updates**: Immediate UI updates with background synchronization
- **Responsive Design**: Adaptive layouts for mobile, tablet, and desktop
- **Dark/Light Theme**: System-aware theme switching
- **Error Handling**: Comprehensive error handling with retry mechanisms
- **Accessibility**: Full accessibility support with screen reader compatibility

## Architecture

This application follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/                   # Core utilities and services
│   ├── di/                # Dependency injection
│   ├── errors/            # Error handling
│   ├── network/           # Network services
│   ├── storage/           # Local storage
│   ├── sync/              # Background synchronization
│   └── utils/             # Utilities and helpers
├── data/                  # Data layer
│   ├── datasources/       # Remote and local data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Business logic
└── presentation/          # Presentation layer
    ├── blocs/             # State management (BLoC)
    ├── pages/             # UI screens
    ├── widgets/           # Reusable UI components
    ├── routes/            # Navigation
    └── theme/             # Theming
```

### Key Design Patterns
- **Clean Architecture**: Separation of concerns with dependency inversion
- **BLoC Pattern**: Reactive state management
- **Repository Pattern**: Data access abstraction
- **Dependency Injection**: Loose coupling with GetIt
- **Result Pattern**: Functional error handling

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mini_feed
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

1. **Enable developer options**
   ```bash
   flutter config --enable-web
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter config --enable-linux-desktop
   ```

2. **Run tests**
   ```bash
   # Unit tests
   flutter test
   
   # Integration tests
   flutter test integration_test/
   
   # Test coverage
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

3. **Code analysis**
   ```bash
   flutter analyze
   dart format .
   ```

## Configuration

### API Configuration
The app uses JSONPlaceholder API for demo purposes. To configure a different API:

1. Update `lib/core/constants/api_constants.dart`
2. Modify authentication endpoints in `lib/data/datasources/remote/auth_remote_datasource.dart`
3. Update post endpoints in `lib/data/datasources/remote/post_remote_datasource.dart`

### Authentication
Default test credentials:
- Email: `eve.holt@reqres.in`
- Password: `cityslicka`

## Usage

### Basic Flow
1. **Login**: Enter credentials on the login screen
2. **Browse Feed**: Scroll through posts, pull to refresh
3. **Search**: Use the search bar to find specific posts
4. **View Details**: Tap on a post to see full content and comments
5. **Create Posts**: Use the floating action button to create new posts
6. **Favorites**: Tap the heart icon to mark posts as favorites
7. **Theme**: Use the theme toggle to switch between light/dark modes

### Offline Usage
- The app automatically caches data for offline access
- Create posts while offline (they'll sync when connection returns)
- Search and browse cached content
- Offline indicator shows connection status

## Testing

### Test Structure
```
test/
├── core/                  # Core functionality tests
├── data/                  # Data layer tests
├── domain/                # Domain layer tests
├── presentation/          # UI and BLoC tests
└── integration/           # End-to-end tests
```

### Running Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/presentation/blocs/feed/feed_bloc_test.dart

# Integration tests
flutter test integration_test/

# Test with coverage
flutter test --coverage
```

### Test Categories
- **Unit Tests**: Individual component testing
- **Widget Tests**: UI component testing
- **BLoC Tests**: State management testing
- **Integration Tests**: End-to-end user flows
- **Golden Tests**: Visual regression testing

## Performance

### Optimization Strategies
- **Lazy Loading**: Posts loaded on demand with pagination
- **Image Caching**: Efficient image loading and caching
- **State Management**: Optimized BLoC state updates
- **Memory Management**: Proper disposal of resources
- **Build Optimization**: Tree shaking and code splitting

### Performance Monitoring
- Use Flutter Inspector for widget tree analysis
- Profile memory usage with DevTools
- Monitor network requests and caching efficiency
- Track app startup time and frame rendering

## Accessibility

### Features
- **Screen Reader Support**: Full VoiceOver/TalkBack compatibility
- **Keyboard Navigation**: Complete keyboard accessibility
- **High Contrast**: Support for high contrast themes
- **Font Scaling**: Respects system font size settings
- **Focus Management**: Proper focus handling throughout the app

### Testing Accessibility
```bash
# Run accessibility tests
flutter test test/accessibility/

# Use accessibility scanner
flutter run --enable-accessibility-scanner
```

## Deployment

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS
```bash
# Build iOS
flutter build ios --release
```

### Web
```bash
# Build for web
flutter build web --release
```

### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Troubleshooting

### Common Issues

1. **Build Errors**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Network Issues**
   - Check internet connection
   - Verify API endpoints are accessible
   - Review network security settings

3. **Storage Issues**
   - Clear app data
   - Check device storage space
   - Verify permissions

4. **Performance Issues**
   - Enable performance overlay: `flutter run --enable-performance-overlay`
   - Profile the app: `flutter run --profile`
   - Check for memory leaks in DevTools

### Debug Mode
```bash
# Run in debug mode with verbose logging
flutter run --debug --verbose

# Enable additional debugging
flutter run --enable-software-rendering
flutter run --trace-startup
```

## Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and add tests
4. Run tests: `flutter test`
5. Run linting: `flutter analyze`
6. Commit changes: `git commit -m 'Add amazing feature'`
7. Push to branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for consistent formatting
- Add documentation for public APIs
- Write tests for new features
- Follow existing architecture patterns

### Commit Messages
Use conventional commit format:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

## Dependencies

### Core Dependencies
- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **dio**: HTTP client
- **hive**: Local database
- **shared_preferences**: Simple key-value storage
- **connectivity_plus**: Network connectivity
- **equatable**: Value equality

### Development Dependencies
- **flutter_test**: Testing framework
- **mocktail**: Mocking library
- **build_runner**: Code generation
- **json_annotation**: JSON serialization
- **flutter_lints**: Linting rules

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [JSONPlaceholder](https://jsonplaceholder.typicode.com/) for the demo API
- [ReqRes](https://reqres.in/) for authentication API
- Flutter team for the amazing framework
- Open source community for the excellent packages

## Support

For support and questions:
- Create an issue in the repository
- Check existing documentation
- Review the troubleshooting section
- Contact the development team

---

**Built with ❤️ using Flutter**