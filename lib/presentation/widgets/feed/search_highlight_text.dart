import 'package:flutter/material.dart';

/// Widget that highlights search terms in text
/// 
/// Takes a text string and a search query, and highlights all occurrences
/// of the search query within the text using a different text style.
class SearchHighlightText extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const SearchHighlightText({
    super.key,
    required this.text,
    required this.searchQuery,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = _buildTextSpans(context);
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final spans = <TextSpan>[];
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final highlight = highlightStyle ?? 
        defaultStyle?.copyWith(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        );

    final query = searchQuery.toLowerCase();
    final textLower = text.toLowerCase();
    
    int start = 0;
    int index = textLower.indexOf(query);
    
    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: defaultStyle,
        ));
      }
      
      // Add the highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlight,
      ));
      
      start = index + query.length;
      index = textLower.indexOf(query, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }
    
    return spans;
  }
}