import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// A widget that renders text with embedded LaTeX math expressions.
/// Math expressions must be enclosed in delimiters:
/// - Inline math: $expression$ or \(expression\)
/// - Display math: $$expression$$ or \[expression\]
///
/// Examples:
/// - $\log_{10} x$ for inline logarithm
/// - $$\frac{d}{dx} f(x)$$ for display derivative
/// - $\frac{\partial f}{\partial x}$ for partial derivative
///
/// Note: If math expressions are not rendering, ensure they are properly
/// formatted with delimiters. The widget will fall back to plain text
/// if no math delimiters are found.
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Show what we're looking for
    final hasDollar = text.contains('\$');
    final hasLParen = text.contains('\\(');
    final hasLBracket = text.contains('\\[');

    // If text doesn't contain math delimiters, use regular Text
    if (!hasDollar && !hasLParen && !hasLBracket) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Parse and render text with math
    return _buildMathText(context);
  }

  Widget _buildMathText(BuildContext context) {
    final List<InlineSpan> spans = [];
    // Improved regex to handle more complex expressions and avoid greedy matching
    final RegExp mathRegex = RegExp(r'(\$\$[\s\S]*?\$\$|\$[^$\n\r]+\$|\\\[[\s\S]*?\\\]|\\\([\s\S]*?\\\))');

    int lastEnd = 0;
    for (final Match match in mathRegex.allMatches(text)) {
      // Add text before math expression
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          spans.add(TextSpan(text: textBefore, style: style));
        }
      }

      // Add math expression
      final mathExpression = match.group(0)!;
      String cleanMath = mathExpression;

      // Determine math style based on delimiters
      MathStyle mathStyle = MathStyle.text; // Default to text style

      // Remove delimiters for flutter_math
      if (mathExpression.startsWith('\$\$') && mathExpression.endsWith('\$\$')) {
        cleanMath = mathExpression.substring(2, mathExpression.length - 2);
        mathStyle = MathStyle.display; // Display style for $$...$$
      } else if (mathExpression.startsWith('\$') && mathExpression.endsWith('\$')) {
        cleanMath = mathExpression.substring(1, mathExpression.length - 1);
        mathStyle = MathStyle.text; // Text style for $...$
      } else if (mathExpression.startsWith('\\[') && mathExpression.endsWith('\\]')) {
        cleanMath = mathExpression.substring(2, mathExpression.length - 2);
        mathStyle = MathStyle.display; // Display style for \[...\]
      } else if (mathExpression.startsWith('\\(') && mathExpression.endsWith('\\)')) {
        cleanMath = mathExpression.substring(2, mathExpression.length - 2);
        mathStyle = MathStyle.text; // Text style for \(...\)
      }

      try {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Math.tex(
            cleanMath.trim(), // Trim whitespace
            textStyle: style,
            mathStyle: mathStyle,
          ),
        ));
      } catch (e) {
        // If math parsing fails, show the cleaned math expression in red for debugging
        // This helps identify which expressions are failing
        spans.add(TextSpan(
          text: '[Math Error: $cleanMath]',
          style: style?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: (style?.fontSize ?? 14) * 0.8, // Slightly smaller
          )
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last math expression
    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText, style: style));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}