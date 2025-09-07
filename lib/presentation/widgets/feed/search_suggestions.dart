import 'package:flutter/material.dart';

/// Widget that displays search suggestions below the search bar
/// 
/// Shows recent searches and popular search terms to help users
/// discover content and quickly access previous searches.
class SearchSuggestions extends StatelessWidget {
  final List<String> recentSearches;
  final List<String> popularSearches;
  final Function(String) onSuggestionTap;
  final VoidCallback? onClearHistory;

  const SearchSuggestions({
    super.key,
    required this.recentSearches,
    required this.popularSearches,
    required this.onSuggestionTap,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty && popularSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Recent Searches',
              onClearHistory != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: onClearHistory,
                      tooltip: 'Clear search history',
                      iconSize: 20,
                    )
                  : null,
            ),
            _buildSuggestionsList(context, recentSearches, Icons.history),
          ],
          if (popularSearches.isNotEmpty) ...[
            _buildSectionHeader(context, 'Popular Searches'),
            _buildSuggestionsList(context, popularSearches, Icons.trending_up),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, [Widget? action]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, List<String> suggestions, IconData icon) {
    return Column(
      children: suggestions.take(5).map((suggestion) {
        return ListTile(
          leading: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(
            suggestion,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: () => onSuggestionTap(suggestion),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          trailing: Icon(
            Icons.north_west,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }).toList(),
    );
  }
}

/// Widget for managing search history and suggestions
/// 
/// Provides functionality to store, retrieve, and manage search history
/// using local storage for persistence across app sessions.
class SearchHistoryManager {
  static const String _storageKey = 'search_history';
  static const int _maxHistoryItems = 10;

  // In a real app, this would use SharedPreferences or similar
  static final List<String> _searchHistory = [];

  /// Add a search query to history
  static void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim();
    
    // Remove if already exists to avoid duplicates
    _searchHistory.remove(trimmedQuery);
    
    // Add to beginning
    _searchHistory.insert(0, trimmedQuery);
    
    // Keep only the most recent items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
  }

  /// Get search history
  static List<String> getHistory() {
    return List.from(_searchHistory);
  }

  /// Clear search history
  static void clearHistory() {
    _searchHistory.clear();
  }

  /// Get popular search terms (mock data for demo)
  static List<String> getPopularSearches() {
    return [
      'flutter',
      'development',
      'mobile',
      'programming',
      'tutorial',
    ];
  }
}