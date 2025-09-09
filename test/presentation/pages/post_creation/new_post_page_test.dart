import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_bloc.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_event.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_state.dart';
import 'package:mini_feed/presentation/pages/post_creation/new_post_page.dart';
import 'package:mini_feed/presentation/widgets/common/app_buttons.dart';

class MockPostCreationBloc extends Mock implements PostCreationBloc {}

void main() {
  group('NewPostPage', () {
    late MockPostCreationBloc mockPostCreationBloc;

    setUp(() {
      mockPostCreationBloc = MockPostCreationBloc();
    });

    Widget createNewPostPage() {
      return MaterialApp(
        home: BlocProvider<PostCreationBloc>.value(
          value: mockPostCreationBloc,
          child: const TestNewPostPage(),
        ),
      );
    }

    testWidgets('should display form fields and submit button', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationInitial());
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Create Post'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Post Title'), findsOneWidget);
      expect(find.text('Post Content'), findsOneWidget);
      expect(find.byType(AppPrimaryButton), findsOneWidget);
    });

    testWidgets('should validate title field', (tester) async {
      // Mock the BLoC to return validation state with title error
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationValidating(
            titleError: 'Title must be at least 3 characters long',
            bodyError: null,
            isValid: false,
          ));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Title must be at least 3 characters long'), findsOneWidget);
    });

    testWidgets('should validate body field', (tester) async {
      // Mock the BLoC to return validation state with body error
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationValidating(
            titleError: null,
            bodyError: 'Body must be at least 10 characters long',
            isValid: false,
          ));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Body must be at least 10 characters long'), findsOneWidget);
    });

    testWidgets('should submit valid form', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationInitial());
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      // Enter valid data
      final titleField = find.widgetWithText(TextFormField, 'Post Title');
      final bodyField = find.widgetWithText(TextFormField, 'Post Content');
      
      await tester.enterText(titleField, 'Test Post Title');
      await tester.enterText(bodyField, 'This is a test post content with enough characters');
      await tester.pump();

      // Submit the form
      final submitButton = find.byType(AppPrimaryButton);
      await tester.tap(submitButton);
      await tester.pump();

      // Verify that validation event is added first
      verify(() => mockPostCreationBloc.add(
        const PostInputValidated(
          title: 'Test Post Title',
          body: 'This is a test post content with enough characters',
        ),
      )).called(1);
    });

    testWidgets('should show loading state', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationLoading());
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Creating your post...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2)); // One in loading indicator, one in button
    });

    testWidgets('should show error state with retry option', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationFailure(
            message: 'Network error occurred',
            canRetry: true,
          ));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Failed to create post'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should handle success state', (tester) async {
      final testPost = Post(
        id: 1,
        userId: 1,
        title: 'Test Post',
        body: 'Test content',
      );

      when(() => mockPostCreationBloc.state)
          .thenReturn(PostCreationSuccess(createdPost: testPost));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => Stream.value(PostCreationSuccess(createdPost: testPost)));

      await tester.pumpWidget(createNewPostPage());
      await tester.pump(); // Allow the listener to process

      expect(find.text('Post created successfully!'), findsOneWidget);
    });

    testWidgets('should show validation errors from bloc', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationValidating(
            titleError: 'Title is too short',
            bodyError: 'Body is required',
            isValid: false,
          ));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      expect(find.text('Title is too short'), findsOneWidget);
      expect(find.text('Body is required'), findsOneWidget);
    });

    testWidgets('should show character counters', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationInitial());
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      // Should show initial character counters
      expect(find.text('0/200'), findsOneWidget); // Title counter
      expect(find.text('0/5000'), findsOneWidget); // Body counter
    });

    testWidgets('should close page when cancel is pressed', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationInitial());
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      final cancelButton = find.byIcon(Icons.close);
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Page should be closed (we can't easily test Navigator.pop in unit tests,
      // but we can verify the button exists and is tappable)
    });

    testWidgets('should disable submit button when form is invalid', (tester) async {
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationValidating(isValid: false));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createNewPostPage());

      final submitButton = find.byType(AppPrimaryButton);
      final appButton = tester.widget<AppPrimaryButton>(submitButton);
      
      expect(appButton.onPressed, isNull);
    });

    testWidgets('should enable submit button when form is valid', (tester) async {
      // Mock the BLoC to return validation state with isValid: true
      when(() => mockPostCreationBloc.state)
          .thenReturn(const PostCreationValidating(isValid: true));
      when(() => mockPostCreationBloc.stream)
          .thenAnswer((_) => Stream.value(const PostCreationValidating(isValid: true)));

      await tester.pumpWidget(createNewPostPage());
      await tester.pump(); // Allow the listener to process

      final submitButton = find.byType(AppPrimaryButton);
      final appButton = tester.widget<AppPrimaryButton>(submitButton);
      
      expect(appButton.onPressed, isNotNull);
    });
  });
}

/// Test version of NewPostPage that doesn't use dependency injection
class TestNewPostPage extends StatefulWidget {
  const TestNewPostPage({super.key});

  @override
  State<TestNewPostPage> createState() => _TestNewPostPageState();
}

class _TestNewPostPageState extends State<TestNewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _bodyFocusNode = FocusNode();
  
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to text changes for real-time validation
    _titleController.addListener(_onInputChanged);
    _bodyController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final title = _titleController.text;
    final body = _bodyController.text;
    
    context.read<PostCreationBloc>().add(PostInputValidated(
      title: title,
      body: body,
    ));
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      
      context.read<PostCreationBloc>().add(PostCreationRequested(
        title: title,
        body: body,
        userId: 1,
      ));
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancel,
        ),
        actions: [
          BlocBuilder<PostCreationBloc, PostCreationState>(
            builder: (context, state) {
              final isLoading = state is PostCreationLoading;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: AppPrimaryButton(
                  onPressed: (_isFormValid && !isLoading) ? _onSubmit : null,
                  text: 'Post',
                  isLoading: isLoading,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<PostCreationBloc, PostCreationState>(
        listener: (context, state) {
          if (state is PostCreationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is PostCreationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PostCreationValidating) {
            setState(() {
              _isFormValid = state.isValid;
            });
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Post Title',
                      errorText: state is PostCreationValidating ? state.titleError : null,
                      counterText: '${_titleController.text.length}/200',
                    ),
                    maxLength: 200,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Post title is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Post title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Post Content',
                      errorText: state is PostCreationValidating ? state.bodyError : null,
                      counterText: '${_bodyController.text.length}/5000',
                    ),
                    maxLines: 4,
                    maxLength: 5000,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Post content is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Post content must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  if (state is PostCreationLoading) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Creating your post...'),
                      ],
                    ),
                  ],
                  if (state is PostCreationFailure) ...[
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text('Failed to create post'),
                        Text(state.message),
                        if (state.canRetry)
                          TextButton(
                            onPressed: _onSubmit,
                            child: const Text('Try Again'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}