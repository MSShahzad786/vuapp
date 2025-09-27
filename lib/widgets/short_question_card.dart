import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/models/mcq.dart';
import 'package:vu_mcqs_app/services/chapter_service.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart' as auth;
import 'package:vu_mcqs_app/widgets/math_text.dart';

class ShortQuestionCard extends StatefulWidget {
  final MCQ question;
  final int index;
  final String subjectCode;
  final int chapterOrderby;

  const ShortQuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.subjectCode,
    required this.chapterOrderby,
  });

  @override
  State<ShortQuestionCard> createState() => _ShortQuestionCardState();
}

class _ShortQuestionCardState extends State<ShortQuestionCard> {
  bool _isUpdatingReaction = false;
  late MCQ _currentQuestion;
  final ChapterService _chapterService = ChapterService();
  final DatabaseService _databaseService = DatabaseService();
  int? _currentUserReaction; // null=none, 1=upvote, 2=downvote, 3=heart

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.question;
    _loadCurrentUserReaction();
  }

  @override
  void didUpdateWidget(ShortQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _currentQuestion = widget.question;
    }
  }

  Future<void> _updateReaction(String reactionType) async {
    if (_isUpdatingReaction) return;

    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    setState(() => _isUpdatingReaction = true);

    // Store previous state for rollback
    final previousReaction = _currentUserReaction;
    final previousQuestion = _currentQuestion;

    try {
      // Determine if adding or removing
      bool isAdding = _currentUserReaction != _reactionTypeToValue(reactionType);

      // Optimistic UI update
      int? newReactionValue = isAdding ? _reactionTypeToValue(reactionType) : null;
      _applyOptimisticUpdate(newReactionValue);

      // Update local database
      await _databaseService.updateShortReactionLocal(
        widget.subjectCode,
        widget.chapterOrderby,
        _currentQuestion.id,
        reactionType,
        user.uid,
        isAdding,
      );

      // Update local state (persisted successfully)
      setState(() {
        _currentUserReaction = newReactionValue;
      });

    } catch (e) {
      // Revert optimistic update on failure
      setState(() {
        _currentQuestion = previousQuestion;
        _currentUserReaction = previousReaction;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update reaction. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isUpdatingReaction = false);
    }
  }

  void _applyOptimisticUpdate(int? newReaction) {
    setState(() {
      // Get the old reaction before updating
      final oldReaction = _currentUserReaction;

      // Update current user reaction
      _currentUserReaction = newReaction;

      // Update counts optimistically
      if (oldReaction != null) {
        // Decrement old reaction count
        switch (oldReaction) {
          case 1: _currentQuestion = _currentQuestion.copyWith(upvotes: _currentQuestion.upvotes - 1);
          case 2: _currentQuestion = _currentQuestion.copyWith(downvotes: _currentQuestion.downvotes - 1);
          case 3: _currentQuestion = _currentQuestion.copyWith(hearts: _currentQuestion.hearts - 1);
        }
      }

      if (newReaction != null) {
        // Increment new reaction count
        switch (newReaction) {
          case 1: _currentQuestion = _currentQuestion.copyWith(upvotes: _currentQuestion.upvotes + 1);
          case 2: _currentQuestion = _currentQuestion.copyWith(downvotes: _currentQuestion.downvotes + 1);
          case 3: _currentQuestion = _currentQuestion.copyWith(hearts: _currentQuestion.hearts + 1);
        }
      }
    });
  }

  int _reactionTypeToValue(String reactionType) {
    switch (reactionType) {
      case 'upvote': return 1;
      case 'downvote': return 2;
      case 'heart': return 3;
      default: return 0;
    }
  }

  Future<void> _loadCurrentUserReaction() async {
    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    try {
      // Query local database for current reaction
      final db = await _databaseService.database;
      final tableName = 'shorts_${widget.subjectCode.toLowerCase()}';
      final result = await db.query(
        tableName,
        columns: ['is_reacted'],
        where: 'shortid = ? AND chapter_order = ?',
        whereArgs: [_currentQuestion.id, widget.chapterOrderby],
        limit: 1,
      );

      if (result.isNotEmpty && mounted) {
        final reactionValue = result.first['is_reacted'] as int?;
        setState(() {
          _currentUserReaction = reactionValue;
        });
      }
    } catch (e) {
      // Silently handle errors when loading current reaction
    }
  }

  bool _hasUserReacted(String reactionType, String userId) {
    switch (reactionType) {
      case 'upvote':
        return _currentQuestion.upvotedBy.contains(userId);
      case 'downvote':
        return _currentQuestion.downvotedBy.contains(userId);
      case 'heart':
        return _currentQuestion.heartedBy.contains(userId);
      default:
        return false;
    }
  }

  String? _getCurrentUserReaction(String userId) {
    if (_currentQuestion.upvotedBy.contains(userId)) return 'upvote';
    if (_currentQuestion.downvotedBy.contains(userId)) return 'downvote';
    if (_currentQuestion.heartedBy.contains(userId)) return 'heart';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${widget.index + 1}.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MathText(
                    _currentQuestion.question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Answer section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: MathText(
                _currentQuestion.explanation,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Interactive Reaction Buttons
            Row(
              children: [
                // Reaction buttons on the left
                Row(
                  children: [
                    _buildReactionButton(
                      context,
                      Icons.arrow_upward,
                      'upvote',
                      _currentQuestion.upvotes,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildReactionButton(
                      context,
                      Icons.arrow_downward,
                      'downvote',
                      _currentQuestion.downvotes,
                      Colors.black,
                    ),
                    const SizedBox(width: 8),
                    _buildReactionButton(
                      context,
                      Icons.favorite,
                      'heart',
                      _currentQuestion.hearts,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, IconData icon, String reactionType, int count, Color color) {
    final authProvider = Provider.of<auth.AuthProvider>(context);
    final user = authProvider.user;
    final hasReacted = user != null && _currentUserReaction == _reactionTypeToValue(reactionType);

    return InkWell(
      onTap: _isUpdatingReaction || user == null ? null : () => _updateReaction(reactionType),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasReacted ? color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              size: 16,
            ),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: TextStyle(
                color: hasReacted ? color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontSize: 12,
                fontWeight: hasReacted && reactionType == 'heart' ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
