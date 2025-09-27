import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_mcqs_app/models/mcq.dart';
import 'package:vu_mcqs_app/services/user_subject_firestore_service.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/providers/auth_provider.dart' as auth;
import 'package:vu_mcqs_app/widgets/math_text.dart';

class McqCard extends StatefulWidget {
  final MCQ mcq;
  final int index;
  final String subjectCode;
  final int chapterOrderby;
  final double fontSize;

  const McqCard({
    super.key,
    required this.mcq,
    required this.index,
    required this.subjectCode,
    required this.chapterOrderby,
    this.fontSize = 16.0,
  });

  @override
  State<McqCard> createState() => _McqCardState();
}

class _McqCardState extends State<McqCard> {
  bool _showCorrectOption = false;
  bool _showExplanation = false;
  bool _isUpdatingReaction = false;
  late MCQ _currentMcq;
  final UserSubjectFirestoreService _subjectService = UserSubjectFirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  int? _selectedOptionIndex;
  bool _hasAttempted = false;
  int? _currentUserReaction; // null=none, 1=upvote, 2=downvote, 3=heart

  @override
  void initState() {
    super.initState();
    _currentMcq = widget.mcq;
    _loadCurrentUserReaction();
  }

  @override
  void didUpdateWidget(McqCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mcq != widget.mcq) {
      _currentMcq = widget.mcq;
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
    final previousMcq = _currentMcq;

    try {
      // Determine if adding or removing
      bool isAdding = _currentUserReaction != _reactionTypeToValue(reactionType);

      // Optimistic UI update
      int? newReactionValue = isAdding ? _reactionTypeToValue(reactionType) : null;
      _applyOptimisticUpdate(newReactionValue);

      // Update local database
      await _databaseService.updateMcqReactionLocal(
        widget.subjectCode,
        widget.chapterOrderby,
        _currentMcq.id,
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
        _currentMcq = previousMcq;
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
          case 1: _currentMcq = _currentMcq.copyWith(upvotes: _currentMcq.upvotes - 1);
          case 2: _currentMcq = _currentMcq.copyWith(downvotes: _currentMcq.downvotes - 1);
          case 3: _currentMcq = _currentMcq.copyWith(hearts: _currentMcq.hearts - 1);
        }
      }

      if (newReaction != null) {
        // Increment new reaction count
        switch (newReaction) {
          case 1: _currentMcq = _currentMcq.copyWith(upvotes: _currentMcq.upvotes + 1);
          case 2: _currentMcq = _currentMcq.copyWith(downvotes: _currentMcq.downvotes + 1);
          case 3: _currentMcq = _currentMcq.copyWith(hearts: _currentMcq.hearts + 1);
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
      final tableName = 'mcqs_${widget.subjectCode.toLowerCase()}';
      final result = await db.query(
        tableName,
        columns: ['is_reacted'],
        where: 'mcqid = ? AND chapter_order = ?',
        whereArgs: [_currentMcq.id, widget.chapterOrderby],
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

  Future<void> _refreshMcqData() async {
    // Reload MCQ data from database to reflect changes
    final db = await _databaseService.database;
    final tableName = 'mcqs_${widget.subjectCode.toLowerCase()}';
    final result = await db.query(
      tableName,
      where: 'mcqid = ? AND chapter_order = ?',
      whereArgs: [_currentMcq.id, widget.chapterOrderby],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final map = result.first;
      // Parse reaction data
      final reactionsStr = map['reactions'] as String? ?? '{"upvote": 0, "downvote": 0, "heart": 0}';
      int upvotes = 0, downvotes = 0, hearts = 0;

      final upvoteMatch = RegExp(r'"upvote":\s*(\d+)').firstMatch(reactionsStr);
      if (upvoteMatch != null) upvotes = int.parse(upvoteMatch.group(1)!);

      final downvoteMatch = RegExp(r'"downvote":\s*(\d+)').firstMatch(reactionsStr);
      if (downvoteMatch != null) downvotes = int.parse(downvoteMatch.group(1)!);

      final heartMatch = RegExp(r'"heart":\s*(\d+)').firstMatch(reactionsStr);
      if (heartMatch != null) hearts = int.parse(heartMatch.group(1)!);

      // Get user reaction from is_reacted column
      final reactionValue = map['is_reacted'] as int? ?? 0;
      List<String> upvotedBy = [], downvotedBy = [], heartedBy = [];

      final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        switch (reactionValue) {
          case 1: upvotedBy = [user.uid]; break;
          case 2: downvotedBy = [user.uid]; break;
          case 3: heartedBy = [user.uid]; break;
        }
      }

      setState(() {
        _currentMcq = _currentMcq.copyWith(
          upvotes: upvotes,
          downvotes: downvotes,
          hearts: hearts,
          upvotedBy: upvotedBy,
          downvotedBy: downvotedBy,
          heartedBy: heartedBy,
        );
      });
    }
  }

  bool _hasUserReacted(String reactionType, String userId) {
    switch (reactionType) {
      case 'upvote':
        return _currentMcq.upvotedBy.contains(userId);
      case 'downvote':
        return _currentMcq.downvotedBy.contains(userId);
      case 'heart':
        return _currentMcq.heartedBy.contains(userId);
      default:
        return false;
    }
  }

  String? _getCurrentUserReaction(String userId) {
    if (_currentMcq.upvotedBy.contains(userId)) return 'upvote';
    if (_currentMcq.downvotedBy.contains(userId)) return 'downvote';
    if (_currentMcq.heartedBy.contains(userId)) return 'heart';
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
                      _currentMcq.question,
                      style: TextStyle(
                        fontSize: widget.fontSize - 1,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Options
              ...List.generate(
                _currentMcq.options.length,
                (optionIndex) {
                  final isCorrect = optionIndex == _currentMcq.correctOptionIndex;
                  final isSelected = _selectedOptionIndex == optionIndex;
                  final shouldShowCorrect = _showCorrectOption;

                  return GestureDetector(
                    onTap: () {
                      if (!_hasAttempted) {
                        setState(() {
                          _selectedOptionIndex = optionIndex;
                          _hasAttempted = true;
                          _showCorrectOption = true;
                        });
                        final isCorrect = optionIndex == _currentMcq.correctOptionIndex;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(97 + optionIndex)}.',
                            style: TextStyle(
                              color: shouldShowCorrect && isCorrect
                                  ? Colors.green.shade700
                                  : isSelected && !isCorrect
                                      ? Colors.red.shade700
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: shouldShowCorrect && isCorrect
                                  ? FontWeight.w700
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MathText(
                              _currentMcq.options[optionIndex],
                              style: TextStyle(
                                color: shouldShowCorrect && isCorrect
                                    ? Colors.green.shade700
                                    : isSelected && !isCorrect
                                        ? Colors.red.shade700
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: shouldShowCorrect && isCorrect
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                fontSize: widget.fontSize - 2,
                              ),
                            ),
                          ),
                          if (shouldShowCorrect && isCorrect) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          ] else if (shouldShowCorrect && isSelected && !isCorrect) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Interactive Reaction Buttons and Explanation
              Row(
                children: [
                  // Reaction buttons on the left
                  Row(
                    children: [
                      _buildReactionButton(
                        context,
                        Icons.arrow_upward,
                        'upvote',
                        _currentMcq.upvotes,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildReactionButton(
                        context,
                        Icons.arrow_downward,
                        'downvote',
                        _currentMcq.downvotes,
                        Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      _buildReactionButton(
                        context,
                        Icons.favorite,
                        'heart',
                        _currentMcq.hearts,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Explanation button on the right
                  if (_currentMcq.explanation.isNotEmpty) ...[
                    TextButton(
                      onPressed: () {
                        setState(() => _showExplanation = !_showExplanation);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'explain',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Explanation display
              if (_showExplanation && _currentMcq.explanation.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                    _currentMcq.explanation,
                    style: TextStyle(
                      fontSize: widget.fontSize - 2,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
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
