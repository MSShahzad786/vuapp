import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vu_mcqs_app/services/database_service.dart';
import 'package:vu_mcqs_app/services/reaction_firestore_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final DatabaseService _databaseService = DatabaseService();
  final ReactionFirestoreService _reactionService = ReactionFirestoreService();

  factory SyncService() => _instance;

  SyncService._internal();

  /// Sync user reactions from local MCQs/shorts tables to Firestore
  /// Finds all questions where is_sync = 0 and uploads their reactions
 

  Future<void> syncLocalReactionsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all subjects from local database
      final subjects = await _databaseService.getSelectedSubjects();

      for (final subject in subjects) {
        final subjectCode = subject['subCode'] as String;

        // Sync MCQ reactions for this subject
        await _syncMcqReactionsForSubject(subjectCode, user.uid);

        // Sync Short reactions for this subject
        await _syncShortReactionsForSubject(subjectCode, user.uid);
      }
    } catch (e) {
      debugPrint('Error syncing reactions to Firestore: $e');
    }
  }

  /// Sync MCQ reactions for a specific subject
  Future<void> _syncMcqReactionsForSubject(String subjectCode, String userId) async {
    final db = await _databaseService.database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    try {
      // Get all MCQs with unsynced reactions (is_sync = 0 and is_reacted > 0)
      final unsyncedMcqs = await db.query(
        tableName,
        where: 'is_sync = ? AND is_reacted > ?',
        whereArgs: [0, 0],
      );

      if (unsyncedMcqs.isEmpty) return;

      // Group reactions by chapter
      final Map<int, List<Map<String, dynamic>>> chapterReactions = {};

      for (final mcqRow in unsyncedMcqs) {
        final chapterOrder = mcqRow['chapter_order'] as int;
        final mcqId = mcqRow['mcqid'] as String;
        final reactionValue = mcqRow['is_reacted'] as int;

        if (!chapterReactions.containsKey(chapterOrder)) {
          chapterReactions[chapterOrder] = [];
        }

        chapterReactions[chapterOrder]!.add({
          'mcqId': mcqId,
          'reaction': reactionValue,
        });
      }

      // Batch update each chapter
      for (final entry in chapterReactions.entries) {
        final chapterOrder = entry.key;
        final reactions = entry.value;

        try {
          await _batchUpdateMcqReactionsForChapter(
            userId: userId,
            subjectCode: subjectCode,
            chapterNumber: chapterOrder,
            reactions: reactions,
          );

          // Mark all reactions for this chapter as synced
          for (final reaction in reactions) {
            await db.update(
              tableName,
              {'is_sync': 1},
              where: 'mcqid = ? AND chapter_order = ?',
              whereArgs: [reaction['mcqId'], chapterOrder],
            );
          }

        } catch (e) {
          debugPrint('Error batch syncing MCQ reactions for chapter $chapterOrder: $e');
          // Continue with other chapters even if one fails
        }
      }
    } catch (e) {
      debugPrint('Error syncing MCQ reactions for subject $subjectCode: $e');
    }
  }

  /// Batch update MCQ reactions for a specific chapter
  Future<void> _batchUpdateMcqReactionsForChapter({
    required String userId,
    required String subjectCode,
    required int chapterNumber,
    required List<Map<String, dynamic>> reactions,
  }) async {
    final docId = '${subjectCode.toLowerCase()}_chapt_$chapterNumber';
    final userReactionDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_reactions')
        .doc(docId);

    // Get current user reactions for this chapter
    final docSnapshot = await userReactionDoc.get();
    Map<String, dynamic> currentReactions = {};
    if (docSnapshot.exists) {
      currentReactions = docSnapshot.data()!;
    }

    // Initialize arrays if not exist
    currentReactions.putIfAbsent('mcqs', () => []);

    final mcqArray = currentReactions['mcqs'] as List<dynamic>;

    // Update reactions for each MCQ
    for (final reaction in reactions) {
      final mcqId = reaction['mcqId'] as String;
      final reactionValue = reaction['reaction'] as int;

      // Find existing reaction for this MCQ
      Map<String, dynamic>? existingItemReaction;
      int existingIndex = -1;
      for (int i = 0; i < mcqArray.length; i++) {
        final item = mcqArray[i] as Map<String, dynamic>;
        if (item.containsKey(mcqId)) {
          existingItemReaction = item;
          existingIndex = i;
          break;
        }
      }

      // Add or update reaction
      final newItem = {mcqId: reactionValue};
      if (existingIndex != -1) {
        mcqArray[existingIndex] = newItem;
      } else {
        mcqArray.add(newItem);
      }
    }

    // Update the document
    await userReactionDoc.set(currentReactions, SetOptions(merge: true));
  }

  /// Sync Short reactions for a specific subject
  Future<void> _syncShortReactionsForSubject(String subjectCode, String userId) async {
    final db = await _databaseService.database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    try {
      // Get all Shorts with unsynced reactions (is_sync = 0 and is_reacted > 0)
      final unsyncedShorts = await db.query(
        tableName,
        where: 'is_sync = ? AND is_reacted > ?',
        whereArgs: [0, 0],
      );

      if (unsyncedShorts.isEmpty) return;

      // Group reactions by chapter
      final Map<int, List<Map<String, dynamic>>> chapterReactions = {};

      for (final shortRow in unsyncedShorts) {
        final chapterOrder = shortRow['chapter_order'] as int;
        final shortId = shortRow['shortid'] as String;
        final reactionValue = shortRow['is_reacted'] as int;

        if (!chapterReactions.containsKey(chapterOrder)) {
          chapterReactions[chapterOrder] = [];
        }

        chapterReactions[chapterOrder]!.add({
          'shortId': shortId,
          'reaction': reactionValue,
        });
      }

      // Batch update each chapter
      for (final entry in chapterReactions.entries) {
        final chapterOrder = entry.key;
        final reactions = entry.value;

        try {
          await _batchUpdateShortReactionsForChapter(
            userId: userId,
            subjectCode: subjectCode,
            chapterNumber: chapterOrder,
            reactions: reactions,
          );

          // Mark all reactions for this chapter as synced
          for (final reaction in reactions) {
            await db.update(
              tableName,
              {'is_sync': 1},
              where: 'shortid = ? AND chapter_order = ?',
              whereArgs: [reaction['shortId'], chapterOrder],
            );
          }

        } catch (e) {
          debugPrint('Error batch syncing Short reactions for chapter $chapterOrder: $e');
          // Continue with other chapters even if one fails
        }
      }
    } catch (e) {
      debugPrint('Error syncing Short reactions for subject $subjectCode: $e');
    }
  }

  /// Batch update Short reactions for a specific chapter
  Future<void> _batchUpdateShortReactionsForChapter({
    required String userId,
    required String subjectCode,
    required int chapterNumber,
    required List<Map<String, dynamic>> reactions,
  }) async {
    final docId = '${subjectCode.toLowerCase()}_chapt_$chapterNumber';
    final userReactionDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_reactions')
        .doc(docId);

    // Get current user reactions for this chapter
    final docSnapshot = await userReactionDoc.get();
    Map<String, dynamic> currentReactions = {};
    if (docSnapshot.exists) {
      currentReactions = docSnapshot.data()!;
    }

    // Initialize arrays if not exist
    currentReactions.putIfAbsent('shorts', () => []);

    final shortArray = currentReactions['shorts'] as List<dynamic>;

    // Update reactions for each Short
    for (final reaction in reactions) {
      final shortId = reaction['shortId'] as String;
      final reactionValue = reaction['reaction'] as int;

      // Find existing reaction for this Short
      Map<String, dynamic>? existingItemReaction;
      int existingIndex = -1;
      for (int i = 0; i < shortArray.length; i++) {
        final item = shortArray[i] as Map<String, dynamic>;
        if (item.containsKey(shortId)) {
          existingItemReaction = item;
          existingIndex = i;
          break;
        }
      }

      // Add or update reaction
      final newItem = {shortId: reactionValue};
      if (existingIndex != -1) {
        shortArray[existingIndex] = newItem;
      } else {
        shortArray.add(newItem);
      }
    }

    // Update the document
    await userReactionDoc.set(currentReactions, SetOptions(merge: true));
  }
}