# Use Cases

This directory contains the business logic use cases that orchestrate the flow of data between the presentation layer and the repositories. Each use case represents a single business operation and encapsulates the rules and logic for that operation.

## Structure

Use cases follow the Clean Architecture pattern where:
- Each use case has a single responsibility
- Use cases depend only on repository interfaces (not implementations)
- Use cases return Result objects for consistent error handling
- Use cases can be composed to create more complex operations

## Authentication Use Cases

- `LoginUseCase`: Handles user authentication with email and password
- `LogoutUseCase`: Handles user logout and token cleanup
- `GetCurrentUserUseCase`: Retrieves the currently authenticated user
- `CheckAuthStatusUseCase`: Checks if user is currently authenticated

## Post Use Cases

- `GetPostsUseCase`: Retrieves paginated list of posts
- `GetPostUseCase`: Retrieves a specific post by ID
- `CreatePostUseCase`: Creates a new post with optimistic updates
- `SearchPostsUseCase`: Searches posts by title or content
- `RefreshPostsUseCase`: Refreshes posts from remote source

## Favorite Use Cases

- `ToggleFavoriteUseCase`: Toggles favorite status of a post
- `GetFavoritePostsUseCase`: Retrieves all favorite posts

## Comment Use Cases

- `GetCommentsUseCase`: Retrieves comments for a specific post

## Base Use Case

All use cases extend from a base `UseCase` class that provides:
- Consistent parameter handling
- Result type safety
- Error handling patterns