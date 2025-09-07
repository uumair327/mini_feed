# Repository Interfaces

This directory contains the repository interfaces that define the contracts for data access in the Mini Feed application. These interfaces follow the Repository pattern and Clean Architecture principles.

## Overview

The repository interfaces serve as the boundary between the domain layer and the data layer. They define what operations are available without specifying how they are implemented. This allows for:

- **Testability**: Easy mocking and testing of business logic
- **Flexibility**: Multiple implementations (network, cache, mock)
- **Separation of Concerns**: Domain logic is independent of data sources
- **Dependency Inversion**: High-level modules don't depend on low-level modules

## Repository Interfaces

### AuthRepository

Handles all authentication-related operations:

- **User Authentication**: Login with email/password
- **Session Management**: Token storage and validation
- **User State**: Current user retrieval and authentication status
- **Security**: Secure token refresh and logout

**Key Methods:**
- `login()`: Authenticate user and store token
- `logout()`: Clear authentication state
- `getCurrentUser()`: Get authenticated user info
- `isAuthenticated()`: Check authentication status
- `validateToken()`: Verify token validity with server

### PostRepository

Manages posts, comments, and related operations:

- **Post Management**: CRUD operations for posts
- **Pagination**: Efficient loading of large datasets
- **Search**: Full-text search across posts
- **Favorites**: User-specific favorite management
- **Comments**: Comment retrieval for posts
- **Caching**: Offline support and performance optimization

**Key Methods:**
- `getPosts()`: Paginated post retrieval
- `createPost()`: Create new posts with optimistic updates
- `searchPosts()`: Search posts by content
- `toggleFavorite()`: Manage user favorites
- `getComments()`: Retrieve post comments

## Error Handling

All repository methods return `Result<T>` objects instead of throwing exceptions. This provides:

- **Type Safety**: Compile-time error handling
- **Explicit Error Handling**: Forces consideration of failure cases
- **Consistent API**: Uniform error handling across all operations

### Common Failure Types

- **NetworkFailure**: Network connectivity issues
- **ServerFailure**: Server errors (4xx, 5xx responses)
- **CacheFailure**: Local storage/cache issues
- **AuthFailure**: Authentication/authorization failures
- **ValidationFailure**: Invalid input data
- **NotFoundFailure**: Requested resource doesn't exist

## Caching Strategy

The repositories implement a multi-level caching strategy:

1. **Memory Cache**: Fast access to recently used data
2. **Persistent Cache**: Offline access using Hive/SQLite
3. **Network**: Fresh data from remote APIs

### Cache Behavior

- **Cache-First**: Try cache first, fallback to network
- **Network-First**: Try network first, fallback to cache (with `forceRefresh`)
- **Cache Invalidation**: Smart cache updates on data changes
- **Offline Support**: Graceful degradation when network unavailable

## Optimistic Updates

For better user experience, the repositories support optimistic updates:

1. **Immediate UI Update**: Show changes instantly
2. **Background Sync**: Sync with server in background
3. **Conflict Resolution**: Handle sync failures gracefully
4. **Rollback**: Revert changes if sync fails

### Optimistic Operations

- **Post Creation**: Show new post immediately
- **Favorite Toggle**: Update favorite status instantly
- **Post Updates**: Reflect changes before server confirmation

## Pagination

All list operations support pagination for performance:

- **Page-Based**: Traditional page/limit pagination
- **Cursor-Based**: For real-time feeds (future enhancement)
- **Infinite Scroll**: Seamless loading of additional content
- **Cache Integration**: Efficient page caching

## Implementation Guidelines

When implementing these interfaces:

1. **Follow the Contract**: Implement all methods as specified
2. **Handle All Error Cases**: Return appropriate failure types
3. **Implement Caching**: Use the multi-level caching strategy
4. **Support Offline**: Graceful degradation without network
5. **Optimize Performance**: Minimize network requests and database queries
6. **Log Operations**: Comprehensive logging for debugging
7. **Test Thoroughly**: Unit tests for all scenarios

## Usage Example

```dart
// Inject repository (typically done by DI container)
final AuthRepository authRepo = GetIt.instance<AuthRepository>();

// Use repository in business logic
final result = await authRepo.login(
  email: 'user@example.com',
  password: 'password123',
);

result.fold(
  (failure) => handleError(failure),
  (user) => handleSuccess(user),
);
```

## Testing

Repository interfaces enable easy testing:

```dart
// Mock repository for testing
class MockAuthRepository implements AuthRepository {
  @override
  Future<Result<User>> login({required String email, required String password}) async {
    // Return test data
    return Result.success(testUser);
  }
  
  // ... implement other methods
}
```

## Future Enhancements

Potential future additions to the repository interfaces:

- **Real-time Updates**: WebSocket/SSE support for live data
- **Batch Operations**: Bulk create/update/delete operations
- **Advanced Search**: Filters, sorting, faceted search
- **Media Support**: Image/video upload and management
- **Analytics**: Usage tracking and metrics collection
- **Sync Status**: Detailed sync state information