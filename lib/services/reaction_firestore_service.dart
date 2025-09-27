import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates user reaction for an MCQ or short question with retry logic
  /// Handles storing in user_reactions collection and updating aggregates
  Future<void> updateReaction({
    required String userId,
    required String subjectCode,
    required int chapterNumber,
    required String itemId,
    required String itemType, // 'mcq' or 'short'
    required int? newReaction, // 1=like, 2=dislike, 3=heart, null=remove
  }) async {
    await _retryOperation(() async {
      await _updateReactionInternal(userId, subjectCode, chapterNumber, itemId, itemType, newReaction);
    });
  }

  Future<void> _updateReactionInternal(
    String userId,
    String subjectCode,
    int chapterNumber,
    String itemId,
    String itemType,
    int? newReaction,
  ) async {
    final docId = '${subjectCode.toLowerCase()}_chapt_$chapterNumber';
    final userReactionDoc = _firestore
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
    currentReactions.putIfAbsent('shorts', () => []);

    final itemArray = itemType == 'mcq' ? currentReactions['mcqs'] as List<dynamic> : currentReactions['shorts'] as List<dynamic>;

    // Find existing reaction for this item
    Map<String, dynamic>? existingItemReaction;
    int existingIndex = -1;
    for (int i = 0; i < itemArray.length; i++) {
      final item = itemArray[i] as Map<String, dynamic>;
      if (item.containsKey(itemId)) {
        existingItemReaction = item;
        existingIndex = i;
        break;
      }
    }

    int? previousReaction;
    if (existingItemReaction != null) {
      previousReaction = existingItemReaction[itemId] as int?;
    }

    // If same reaction, remove it
    if (previousReaction == newReaction) {
      newReaction = null;
    }

    // Update user reactions document
    if (newReaction == null) {
      // Remove reaction
      if (existingItemReaction != null) {
        existingItemReaction.remove(itemId);
        if (existingItemReaction.isEmpty) {
          itemArray.removeAt(existingIndex);
        }
      }
    } else {
      // Add or update reaction
      if (existingItemReaction != null) {
        existingItemReaction[itemId] = newReaction;
      } else {
        final newItem = {itemId: newReaction};
        itemArray.add(newItem);
      }
    }

    // Update the document
    await userReactionDoc.set(currentReactions, SetOptions(merge: true));

    // Update aggregates
    await _updateAggregates(subjectCode, chapterNumber, itemId, itemType, previousReaction, newReaction);
  }

  /// Updates aggregate counts in the question documents
  Future<void> _updateAggregates(
    String subjectCode,
    int chapterNumber,
    String itemId,
    String itemType,
    int? previousReaction,
    int? newReaction,
  ) async {
    final normalizedSubjectCode = subjectCode.toLowerCase();

    // Find the document containing this item
    final querySnapshot = await _firestore
        .collection('mySubjects')
        .doc(normalizedSubjectCode)
        .collection('chapters')
        .where('orderby', isEqualTo: chapterNumber)
        .where('is_mcq', isEqualTo: itemType == 'mcq')
        .get();

    if (querySnapshot.docs.isEmpty) return;

    final docRef = querySnapshot.docs.first.reference;
    final docData = querySnapshot.docs.first.data();
    final itemsArray = itemType == 'mcq' ? docData['mcqs'] as List<dynamic> : docData['shorts'] as List<dynamic>;

    // Find the item in the array
    for (int i = 0; i < itemsArray.length; i++) {
      final item = itemsArray[i] as Map<String, dynamic>;
      final itemIdKey = itemType == 'mcq' ? 'mcqId' : 'shortId';
      if (item[itemIdKey]?.toString() == itemId) {
        // Update reactions map
        final reactions = item['reactions'] as Map<String, dynamic>? ?? {};

        // Decrement previous reaction
        if (previousReaction != null) {
          final prevReactionType = _reactionValueToType(previousReaction);
          reactions[prevReactionType] = (reactions[prevReactionType] ?? 0) - 1;
          if (reactions[prevReactionType]! < 0) reactions[prevReactionType] = 0;
        }

        // Increment new reaction
        if (newReaction != null) {
          final newReactionType = _reactionValueToType(newReaction);
          reactions[newReactionType] = (reactions[newReactionType] ?? 0) + 1;
        }

        item['reactions'] = reactions;
        itemsArray[i] = item;
        break;
      }
    }

    // Update the document
    await docRef.update({itemType == 'mcq' ? 'mcqs' : 'shorts': itemsArray});
  }

  String _reactionValueToType(int value) {
    switch (value) {
      case 1: return 'upvote';
      case 2: return 'downvote';
      case 3: return 'heart';
      default: return 'upvote';
    }
  }

  /// Gets user's current reaction for an item
  Future<int?> getUserReaction(String userId, String subjectCode, int chapterNumber, String itemId, String itemType) async {
    final docId = '${subjectCode.toLowerCase()}_chapt_$chapterNumber';

    final docSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_reactions')
        .doc(docId)
        .get();

    if (!docSnapshot.exists) return null;

    final data = docSnapshot.data()!;
    final itemArray = itemType == 'mcq' ? data['mcqs'] as List<dynamic>? ?? [] : data['shorts'] as List<dynamic>? ?? [];

    for (final item in itemArray) {
      final itemMap = item as Map<String, dynamic>;
      if (itemMap.containsKey(itemId)) {
        return itemMap[itemId] as int?;
      }
    }

    return null;
  }

  /// Retry operation with exponential backoff
  Future<void> _retryOperation(Future<void> Function() operation) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await operation();
        return; // Success, exit retry loop
      } catch (e) {
        if (attempt == maxRetries - 1) {
          // Last attempt failed, rethrow
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = baseDelay * pow(2, attempt).toInt();
        final jitter = Random().nextInt(100); // Add up to 100ms jitter
        await Future.delayed(delay + Duration(milliseconds: jitter));
      }
    }
  }
}