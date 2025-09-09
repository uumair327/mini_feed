import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post_creation/post_creation_bloc.dart';
import '../../blocs/post_creation/post_creation_event.dart' as post_creation_events;
import '../../blocs/post_creation/post_creation_state.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart' as feed_events;
import '../../widgets/common/loading_indicators.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/offline_indicators.dart';
import '../../theme/app_breakpoints.dart';
import '../../../core/di/injection_container.dart' as di;

/// Page for creating new posts
/// 
/// Provides a form with title and body input fields, validation,
/// and submission handling with loading states and error feedback.
/// Integrates with FeedBloc for optimistic updates.
class NewPostPage extends StatefulWidget {
  final FeedBloc? feedBloc;

  const NewPostPage({
    super.key,
    this.feedBloc,
  });

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _bodyFocusNode = FocusNode();
  
  late PostCreationBloc _postCreationBloc;
  FeedBloc? _feedBloc;
  bool _isFormValid = false;
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    _postCreationBloc = di.sl<PostCreationBloc>();
    _feedBloc = widget.feedBloc;
    
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
    _postCreationBloc.close();
    super.dispose();
  }

  void _onInputChanged() {
    final title = _titleController.text;
    final body = _bodyController.text;
    
    _postCreationBloc.add(post_creation_events.PostInputValidated(
      title: title,
      body: body,
    ));
  }

  void _onSubmit() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    
    // Mark that user attempted to submit
    _submitAttempted = true;
    
    // Always validate first, then submit if valid
    _postCreationBloc.add(post_creation_events.PostInputValidated(
      title: title,
      body: body,
    ));
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _postCreationBloc,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: OfflineBanner(
          child: ResponsiveContainer(
            child: BlocConsumer<PostCreationBloc, PostCreationState>(
              listener: (context, state) {
              if (state is PostCreationLoading && state.optimisticPost != null) {
                // Add optimistic post to feed
                _feedBloc?.add(feed_events.OptimisticPostAdded(
                  optimisticPost: state.optimisticPost!,
                ));
              } else if (state is PostCreationSuccess) {
                // Replace optimistic post with real post in feed
                if (state.previousOptimisticPost != null) {
                  _feedBloc?.add(feed_events.OptimisticPostReplaced(
                    optimisticPost: state.previousOptimisticPost!,
                    realPost: state.createdPost,
                  ));
                }
                
                // Show success message and close the page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(true); // Return true to indicate success
              } else if (state is PostCreationFailure) {
                // Remove optimistic post from feed on failure
                if (state.failedOptimisticPost != null) {
                  _feedBloc?.add(feed_events.OptimisticPostRemoved(
                    optimisticPost: state.failedOptimisticPost!,
                  ));
                }
                
                // Show error message with rollback notification
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.message}\nPost has been removed from feed.'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    action: state.canRetry
                        ? SnackBarAction(
                            label: 'Retry',
                            onPressed: _onSubmit,
                          )
                        : null,
                  ),
                );
              } else if (state is PostCreationValidating) {
                setState(() {
                  _isFormValid = state.isValid;
                });
                
                // If user attempted to submit and form is now valid, proceed with submission
                if (_submitAttempted && state.isValid) {
                  _submitAttempted = false; // Reset flag
                  
                  final title = _titleController.text.trim();
                  final body = _bodyController.text.trim();
                  
                  // TODO: Get actual user ID from authentication
                  const userId = 1;
                  
                  _postCreationBloc.add(post_creation_events.PostCreationRequested(
                    title: title,
                    body: body,
                    userId: userId,
                  ));
                }
              }
            },
              builder: (context, state) {
                return _buildBody(state);
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Create Post'),
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _onCancel,
        tooltip: 'Cancel',
      ),
      actions: [
        const ConnectivityIndicator(),
        const SizedBox(width: 8),
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
    );
  }

  Widget _buildBody(PostCreationState state) {
    return Padding(
      padding: EdgeInsets.all(
        AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleField(state),
            const SizedBox(height: 16),
            _buildBodyField(state),
            const SizedBox(height: 24),
            if (state is PostCreationLoading) _buildLoadingIndicator(),
            if (state is PostCreationFailure) _buildErrorMessage(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(PostCreationState state) {
    String? errorText;
    if (state is PostCreationValidating) {
      errorText = state.titleError;
    }

    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: InputDecoration(
        labelText: 'Post Title',
        hintText: 'Enter a catchy title for your post...',
        errorText: errorText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.title),
        counterText: '${_titleController.text.length}/200',
      ),
      maxLength: 200,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _bodyFocusNode.requestFocus(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Post title is required';
        }
        if (value.trim().length < 3) {
          return 'Post title must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildBodyField(PostCreationState state) {
    String? errorText;
    if (state is PostCreationValidating) {
      errorText = state.bodyError;
    }

    return TextFormField(
      controller: _bodyController,
      focusNode: _bodyFocusNode,
      decoration: InputDecoration(
        labelText: 'Post Content',
        hintText: 'Share your thoughts, ideas, or experiences...',
        errorText: errorText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.article),
        alignLabelWithHint: true,
        counterText: '${_bodyController.text.length}/5000',
      ),
      maxLines: 8,
      minLines: 4,
      maxLength: 5000,
      textInputAction: TextInputAction.newline,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Post content is required';
        }
        if (value.trim().length < 10) {
          return 'Post content must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: AppLoadingIndicator(),
          ),
          const SizedBox(width: 12),
          Text(
            'Creating your post...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(PostCreationFailure state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to create post',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          if (state.canRetry) ...[
            const SizedBox(height: 12),
            AppSecondaryButton(
              onPressed: _onSubmit,
              text: 'Try Again',
            ),
          ],
        ],
      ),
    );
  }
}