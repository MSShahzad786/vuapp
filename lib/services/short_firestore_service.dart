import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mcq.dart';

class ShortFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MCQ>> fetchShortsForChapter(String subjectCode, int chapterOrderby) async {
    try {
      String normalizedSubjectCode = subjectCode.toLowerCase();

      QuerySnapshot shortsDocumentsSnapshot = await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .where('orderby', isEqualTo: chapterOrderby)
          .where('is_mcq', isEqualTo: false)
          .get();

      if (shortsDocumentsSnapshot.docs.isEmpty) {
        return [];
      }

      final shortsDoc = shortsDocumentsSnapshot.docs.first;
      final docData = shortsDoc.data() as Map<String, dynamic>;

      List<dynamic> shortsArray = docData['shorts'] ?? [];

      if (shortsArray.isEmpty) {
        return [];
      }

      List<MCQ> shorts = [];
      for (var i = 0; i < shortsArray.length; i++) {
        final shortData = shortsArray[i] as Map<String, dynamic>;

        // Handle explanation - join array if it's an array
        String explanation = '';
        if (shortData['explain'] is List) {
          explanation = (shortData['explain'] as List).join(' ');
        } else {
          explanation = shortData['explain'] ?? shortData['explanation'] ?? '';
        }

        // Handle reactions object
        final reactions = shortData['reactions'] as Map<String, dynamic>? ?? {};

        final short = MCQ(
          id: shortData['shortId']?.toString() ?? 'short_${i + 1}',
          question: shortData['question'] ?? '',
          options: [], // Shorts don't have options
          correctOptionIndex: 0, // Not applicable for shorts
          explanation: explanation,
          chapterId: shortsDoc.id,
          upvotes: reactions['upvote'] ?? shortData['upvotes'] ?? 0,
          downvotes: reactions['downvote'] ?? shortData['downvotes'] ?? 0,
          hearts: reactions['heart'] ?? shortData['hearts'] ?? 0,
          upvotedBy: List<String>.from(shortData['upvotedBy'] ?? []),
          downvotedBy: List<String>.from(shortData['downvotedBy'] ?? []),
          heartedBy: List<String>.from(shortData['heartedBy'] ?? []),
          topicList: List<String>.from(shortData['topics'] ?? []),
          subtopicList: List<String>.from(shortData['subtopics'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        shorts.add(short);
      }

      return shorts;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateShortReaction(String subjectCode, int chapterOrderby, String shortId, String reactionType, String userId) async {
    try {
      String normalizedSubjectCode = subjectCode.toLowerCase();

      // Find the document containing this short question
      QuerySnapshot shortsDocumentsSnapshot = await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .where('orderby', isEqualTo: chapterOrderby)
          .where('is_mcq', isEqualTo: false)
          .get();

      if (shortsDocumentsSnapshot.docs.isEmpty) {
        return;
      }

      final shortsDoc = shortsDocumentsSnapshot.docs.first;
      final docData = shortsDoc.data() as Map<String, dynamic>;
      List<dynamic> shortsArray = docData['shorts'] ?? [];

      // Find the short in the array
      int shortIndex = -1;
      Map<String, dynamic>? shortData;
      for (int i = 0; i < shortsArray.length; i++) {
        final currentShort = shortsArray[i] as Map<String, dynamic>;
        if (currentShort['shortId']?.toString() == shortId) {
          shortIndex = i;
          shortData = currentShort;
          break;
        }
      }

      if (shortIndex == -1 || shortData == null) {
        return;
      }

      // Initialize user tracking lists if not exists
      if (!shortData.containsKey('upvotedBy')) shortData['upvotedBy'] = [];
      if (!shortData.containsKey('downvotedBy')) shortData['downvotedBy'] = [];
      if (!shortData.containsKey('heartedBy')) shortData['heartedBy'] = [];

      // Initialize reactions if not exists
      if (!shortData.containsKey('reactions')) {
        shortData['reactions'] = {
          'upvote': shortData['upvotes'] ?? 0,
          'downvote': shortData['downvotes'] ?? 0,
          'heart': shortData['hearts'] ?? 0,
        };
      }

      final reactions = shortData['reactions'] as Map<String, dynamic>;
      final upvotedBy = List<String>.from(shortData['upvotedBy'] ?? []);
      final downvotedBy = List<String>.from(shortData['downvotedBy'] ?? []);
      final heartedBy = List<String>.from(shortData['heartedBy'] ?? []);

      // Check if user has any existing reaction (for exclusive reactions)
      String? currentReactionType;
      if (upvotedBy.contains(userId)) {
        currentReactionType = 'upvote';
      } else if (downvotedBy.contains(userId)) {
        currentReactionType = 'downvote';
      } else if (heartedBy.contains(userId)) {
        currentReactionType = 'heart';
      }

      // If user has a different reaction, remove it first
      if (currentReactionType != null && currentReactionType != reactionType) {
        switch (currentReactionType) {
          case 'upvote':
            upvotedBy.remove(userId);
            reactions['upvote'] = (reactions['upvote'] ?? 0) > 0 ? (reactions['upvote'] ?? 0) - 1 : 0;
            shortData['upvotedBy'] = upvotedBy;
            break;
          case 'downvote':
            downvotedBy.remove(userId);
            reactions['downvote'] = (reactions['downvote'] ?? 0) > 0 ? (reactions['downvote'] ?? 0) - 1 : 0;
            shortData['downvotedBy'] = downvotedBy;
            break;
          case 'heart':
            heartedBy.remove(userId);
            reactions['heart'] = (reactions['heart'] ?? 0) > 0 ? (reactions['heart'] ?? 0) - 1 : 0;
            shortData['heartedBy'] = heartedBy;
            break;
        }
      }

      // Determine the user list based on reaction type
      List<String> targetList;
      String listKey;
      switch (reactionType) {
        case 'upvote':
          targetList = upvotedBy;
          listKey = 'upvotedBy';
          break;
        case 'downvote':
          targetList = downvotedBy;
          listKey = 'downvotedBy';
          break;
        case 'heart':
          targetList = heartedBy;
          listKey = 'heartedBy';
          break;
        default:

          return;
      }

      // Check if user has already reacted with this type
      bool hasReactedWithThisType = targetList.contains(userId);
      int currentCount = reactions[reactionType] ?? 0;

      if (hasReactedWithThisType) {
        // Remove reaction
        targetList.remove(userId);
        reactions[reactionType] = currentCount > 0 ? currentCount - 1 : 0;
      } else {
        // Add reaction
        targetList.add(userId);
        reactions[reactionType] = currentCount + 1;
      }

      // Update the user lists
      shortData[listKey] = targetList;

      // Update the document
      shortsArray[shortIndex] = shortData;

      await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .doc(shortsDoc.id)
          .update({'shorts': shortsArray});

    } catch (e) {
      // Silently handle errors
    }
  }
}
